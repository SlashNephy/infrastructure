package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/bwmarrin/discordgo"
	"github.com/caarlos0/env/v11"
	coreV1 "k8s.io/api/core/v1"
	apiErrors "k8s.io/apimachinery/pkg/api/errors"
	metaV1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/watch"
	"k8s.io/client-go/kubernetes"
	typedCoreV1 "k8s.io/client-go/kubernetes/typed/core/v1"
	"k8s.io/client-go/rest"
)

// notifyCountInterval は同じイベントを再通知するまでに必要な count の増分。
// Kubernetes は同じ理由・同じ対象のイベントを新規作成せず既存オブジェクトの count を加算するため、
// 再発のたびに通知すると Discord が溢れる。
const notifyCountInterval = 5

type Config struct {
	DiscordWebhookID    string `env:"DISCORD_WEBHOOK_ID,notEmpty"`
	DiscordWebhookToken string `env:"DISCORD_WEBHOOK_TOKEN,notEmpty"`
}

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-signalChannel
		cancel()
	}()

	config, err := env.ParseAs[Config]()
	if err != nil {
		slog.ErrorContext(ctx, "failed to parse environment variables", slog.String("error", err.Error()))
		os.Exit(1)
	}

	kubernetesConfig, err := rest.InClusterConfig()
	if err != nil {
		slog.ErrorContext(ctx, "failed to get Kubernetes cluster config", slog.String("error", err.Error()))
		os.Exit(1)
	}

	clientSet, err := kubernetes.NewForConfig(kubernetesConfig)
	if err != nil {
		slog.ErrorContext(ctx, "failed to create Kubernetes client", slog.String("error", err.Error()))
		os.Exit(1)
	}

	if err := watchEvents(ctx, clientSet, &config); err != nil {
		slog.ErrorContext(ctx, "error occurred while watching events", slog.String("error", err.Error()))
		os.Exit(1)
	}
}

func watchEvents(ctx context.Context, clientSet *kubernetes.Clientset, config *Config) error {
	discordSession, err := discordgo.New("")
	if err != nil {
		return err
	}

	client := clientSet.CoreV1().Events(metaV1.NamespaceAll)

	// ResourceVersion を指定しない Watch は既存のイベントを全件 ADDED として流し直すため、
	// 開始位置を List で取得してから Watch する。
	resourceVersion, syncedAt, err := resyncResourceVersion(ctx, client)
	if err != nil {
		return err
	}

	watcher, err := client.Watch(ctx, metaV1.ListOptions{ResourceVersion: resourceVersion})
	if err != nil {
		return err
	}
	defer func() {
		watcher.Stop()
	}()

	handler := newEventHandler(config, discordSession, clientSet.CoreV1(), syncedAt)

	slog.InfoContext(ctx, "Kubernetes events watching started", slog.String("resourceVersion", resourceVersion))

	for {
		select {
		case <-ctx.Done():
			return nil
		case event, ok := <-watcher.ResultChan():
			if !ok || event.Type == watch.Error {
				// ResourceVersion が古すぎて再開できない場合は取得し直す
				if event.Type == watch.Error {
					resourceVersion, handler.syncedAt, err = resyncResourceVersion(ctx, client)
					if err != nil {
						return err
					}
				}

				slog.WarnContext(ctx, "event channel closed, reconnecting", slog.String("resourceVersion", resourceVersion))

				watcher.Stop()

				watcher, err = client.Watch(ctx, metaV1.ListOptions{ResourceVersion: resourceVersion})
				if err != nil {
					return err
				}

				continue
			}

			if k8sEvent, ok := event.Object.(*coreV1.Event); ok {
				resourceVersion = k8sEvent.ResourceVersion
			}

			handler.handleEvent(ctx, event)
		}
	}
}

// resyncResourceVersion は Watch の開始位置に使う ResourceVersion と、それを取得した時刻を返す。
func resyncResourceVersion(ctx context.Context, client typedCoreV1.EventInterface) (string, time.Time, error) {
	// イベント本体は不要なので Limit: 1 でコレクションの ResourceVersion だけを取る
	list, err := client.List(ctx, metaV1.ListOptions{Limit: 1})
	if err != nil {
		return "", time.Time{}, err
	}

	return list.ResourceVersion, time.Now(), nil
}

type eventHandler struct {
	config         *Config
	discordSession *discordgo.Session
	podsGetter     typedCoreV1.PodsGetter
	syncedAt       time.Time
	// lastNotifiedCounts は通知済みイベントの count を保持する。
	// Watch のループは単一の goroutine から呼ばれるため排他は不要。
	lastNotifiedCounts map[types.UID]int32
}

func newEventHandler(config *Config, discordSession *discordgo.Session, podsGetter typedCoreV1.PodsGetter, syncedAt time.Time) *eventHandler {
	return &eventHandler{
		config:             config,
		discordSession:     discordSession,
		podsGetter:         podsGetter,
		syncedAt:           syncedAt,
		lastNotifiedCounts: make(map[types.UID]int32),
	}
}

func (h *eventHandler) handleEvent(ctx context.Context, event watch.Event) {
	if event.Object == nil {
		return
	}

	k8sEvent, ok := event.Object.(*coreV1.Event)
	if !ok {
		return
	}

	// イベントは TTL (既定 1 時間) で削除される。再発を追跡する必要が無くなるので状態も捨てる。
	if event.Type == watch.Deleted {
		delete(h.lastNotifiedCounts, k8sEvent.UID)
		return
	}

	// 再発は既存オブジェクトの count 更新として届くため Modified も扱う
	if event.Type != watch.Added && event.Type != watch.Modified {
		return
	}

	if !filterEvent(k8sEvent, h.syncedAt) {
		return
	}

	// Pod の取得より先に判定して、通知しないイベントでは API を叩かないようにする
	if !h.shouldNotify(k8sEvent) {
		return
	}

	if h.isTerminatingPodEvent(ctx, k8sEvent) {
		return
	}

	slog.InfoContext(
		ctx,
		"notifying event",
		slog.String("eventType", string(event.Type)),
		slog.String("reason", k8sEvent.Reason),
		slog.String("message", k8sEvent.Message),
		slog.String("namespace", k8sEvent.Namespace),
		slog.String("involvedObject", k8sEvent.InvolvedObject.Name),
		slog.Int("count", int(eventCount(k8sEvent))),
	)

	if err := sendDiscordNotification(h.discordSession, h.config.DiscordWebhookID, h.config.DiscordWebhookToken, k8sEvent); err != nil {
		slog.ErrorContext(ctx, "failed to send Discord notification", "error", err)
	}
}

// shouldNotify は通知すべきイベントかどうかを count の増分で判定し、通知する場合に限り状態を更新する。
// 初見のイベントは必ず通知する。既に通知したイベントは count が notifyCountInterval 以上増えたときだけ再通知する。
func (h *eventHandler) shouldNotify(event *coreV1.Event) bool {
	count := eventCount(event)

	lastNotified, notified := h.lastNotifiedCounts[event.UID]
	if notified && count < lastNotified+notifyCountInterval {
		return false
	}

	h.lastNotifiedCounts[event.UID] = count
	return true
}

// isTerminatingPodEvent は削除中 (あるいは既に削除された) Pod の probe 失敗イベントかどうかを返す。
// kubelet は削除中の Pod にも readinessProbe を回し続けるため、ロールアウトのたびに
// `connection refused` が記録される。削除が決まった Pod の probe 失敗は actionable ではない。
func (h *eventHandler) isTerminatingPodEvent(ctx context.Context, event *coreV1.Event) bool {
	if event.Reason != "Unhealthy" || event.InvolvedObject.Kind != "Pod" {
		return false
	}

	pod, err := h.podsGetter.Pods(event.InvolvedObject.Namespace).Get(ctx, event.InvolvedObject.Name, metaV1.GetOptions{})
	switch {
	case apiErrors.IsNotFound(err):
		// 通知を組み立てる時点で既に消えていることが実際にある
		return true
	case err != nil:
		// 判定できないときは握り潰さずに通知する
		slog.WarnContext(
			ctx,
			"failed to get pod for event",
			slog.String("namespace", event.InvolvedObject.Namespace),
			slog.String("pod", event.InvolvedObject.Name),
			slog.String("error", err.Error()),
		)
		return false
	}

	return pod.DeletionTimestamp != nil
}

func filterEvent(event *coreV1.Event, syncedAt time.Time) bool {
	// 一旦 Warning だけ
	if event.Type != "Warning" {
		return false
	}

	// ResourceVersion を取り直して Watch を貼り直したときに、既に通知済みのイベントを再通知しない
	if eventTimestamp(event).Before(syncedAt) {
		return false
	}

	// startup probe は failureThreshold に達するまで失敗するのが前提なので、1 回の失敗は異常ではない。
	// 起動できないまま終わる場合は CrashLoopBackOff の BackOff イベントで通知される。
	if event.Reason == "Unhealthy" && strings.HasPrefix(event.Message, "Startup probe failed:") {
		return false
	}

	if event.Reason == "BackoffLimitExceeded" {
		switch {
		case event.InvolvedObject.Kind == "Job" && event.Namespace == "rclone" && strings.HasPrefix(event.InvolvedObject.Name, "music-"):
			return false
		case event.InvolvedObject.Kind == "Job" && event.Namespace == "annict2anilist" && strings.HasPrefix(event.InvolvedObject.Name, "cronjob-"):
			return false
		}
	}

	return true
}

func sendDiscordNotification(session *discordgo.Session, webhookID, webhookToken string, event *coreV1.Event) error {
	var color int
	switch event.Type {
	case coreV1.EventTypeNormal:
		color = 0x00FF00 // 緑
	case coreV1.EventTypeWarning:
		color = 0xFF9900 // オレンジ
	}

	fields := []*discordgo.MessageEmbedField{
		{
			Name:   "Object Kind",
			Value:  fmt.Sprintf("%s/%s", event.InvolvedObject.APIVersion, event.InvolvedObject.Kind),
			Inline: true,
		},
		{
			Name:   "Object Name",
			Value:  event.InvolvedObject.Name,
			Inline: true,
		},
		{
			Name:   "Source",
			Value:  event.Source.Component,
			Inline: true,
		},
		{
			Name:   "Count",
			Value:  fmt.Sprintf("%d", eventCount(event)),
			Inline: true,
		},
	}

	// 継続中かどうかが分かるように初回の発生時刻を出す
	if firstSeen := eventFirstTimestamp(event); !firstSeen.IsZero() {
		fields = append(fields, &discordgo.MessageEmbedField{
			Name:   "First Seen",
			Value:  fmt.Sprintf("<t:%d:R>", firstSeen.Unix()),
			Inline: true,
		})
	}

	embed := &discordgo.MessageEmbed{
		Title:       fmt.Sprintf("[%s] %s", event.Namespace, event.Reason),
		Description: event.Message,
		Color:       color,
		Fields:      fields,
		Timestamp:   eventTimestamp(event).Format(time.RFC3339),
	}

	params := &discordgo.WebhookParams{
		Embeds: []*discordgo.MessageEmbed{embed},
	}

	_, err := session.WebhookExecute(webhookID, webhookToken, false, params)
	return err
}

// eventCount はイベントの発生回数を返す。
// events.k8s.io/v1 で記録されたイベントは count ではなく series.count に回数を持つ。
func eventCount(event *coreV1.Event) int32 {
	if event.Series != nil && event.Series.Count > 0 {
		return event.Series.Count
	}

	if event.Count > 0 {
		return event.Count
	}

	return 1
}

// eventTimestamp はイベントの直近の発生時刻を返す。
func eventTimestamp(event *coreV1.Event) time.Time {
	switch {
	case event.Series != nil && !event.Series.LastObservedTime.IsZero():
		return event.Series.LastObservedTime.Time
	case !event.LastTimestamp.IsZero():
		return event.LastTimestamp.Time
	case !event.EventTime.IsZero():
		return event.EventTime.Time
	case !event.FirstTimestamp.IsZero():
		return event.FirstTimestamp.Time
	default:
		return time.Now()
	}
}

// eventFirstTimestamp はイベントの初回の発生時刻を返す。分からない場合はゼロ値を返す。
func eventFirstTimestamp(event *coreV1.Event) time.Time {
	switch {
	case !event.FirstTimestamp.IsZero():
		return event.FirstTimestamp.Time
	case !event.EventTime.IsZero():
		return event.EventTime.Time
	default:
		return time.Time{}
	}
}

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
	metaV1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/watch"
	"k8s.io/client-go/kubernetes"
	typedCoreV1 "k8s.io/client-go/kubernetes/typed/core/v1"
	"k8s.io/client-go/rest"
)

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

	slog.InfoContext(ctx, "Kubernetes events watching started", slog.String("resourceVersion", resourceVersion))

	for {
		select {
		case <-ctx.Done():
			return nil
		case event, ok := <-watcher.ResultChan():
			if !ok || event.Type == watch.Error {
				// ResourceVersion が古すぎて再開できない場合は取得し直す
				if event.Type == watch.Error {
					resourceVersion, syncedAt, err = resyncResourceVersion(ctx, client)
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

			handleEvent(ctx, event, config, discordSession, syncedAt)
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

func handleEvent(ctx context.Context, event watch.Event, config *Config, discordSession *discordgo.Session, syncedAt time.Time) {
	if event.Object == nil {
		return
	}

	if event.Type != watch.Added {
		return
	}

	k8sEvent, ok := event.Object.(*coreV1.Event)
	if !ok {
		return
	}

	if !filterEvent(k8sEvent, syncedAt) {
		return
	}

	slog.DebugContext(
		ctx,
		"new event received",
		slog.String("reason", k8sEvent.Reason),
		slog.String("message", k8sEvent.Message),
		slog.String("namespace", k8sEvent.Namespace),
	)

	if err := sendDiscordNotification(discordSession, config.DiscordWebhookID, config.DiscordWebhookToken, k8sEvent); err != nil {
		slog.ErrorContext(ctx, "failed to send Discord notification", "error", err)
	}
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

	embed := &discordgo.MessageEmbed{
		Title:       fmt.Sprintf("[%s] %s", event.Namespace, event.Reason),
		Description: event.Message,
		Color:       color,
		Fields: []*discordgo.MessageEmbedField{
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
				Value:  fmt.Sprintf("%d", event.Count),
				Inline: true,
			},
		},
		Timestamp: eventTimestamp(event).Format(time.RFC3339),
	}

	params := &discordgo.WebhookParams{
		Embeds: []*discordgo.MessageEmbed{embed},
	}

	_, err := session.WebhookExecute(webhookID, webhookToken, false, params)
	return err
}

// eventTimestamp はイベントの発生時刻を返す。
func eventTimestamp(event *coreV1.Event) time.Time {
	switch {
	case !event.LastTimestamp.IsZero():
		return event.LastTimestamp.Time
	case !event.FirstTimestamp.IsZero():
		return event.FirstTimestamp.Time
	default:
		return time.Now()
	}
}

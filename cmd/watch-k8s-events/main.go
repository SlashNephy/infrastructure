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
	watcher, err := client.Watch(ctx, metaV1.ListOptions{})
	if err != nil {
		return err
	}
	defer watcher.Stop()

	slog.InfoContext(ctx, "Kubernetes events watching started")

	for {
		select {
		case <-ctx.Done():
			return nil
		case event, ok := <-watcher.ResultChan():
			if !ok {
				slog.WarnContext(ctx, "event channel closed, reconnecting")

				watcher, err = client.Watch(ctx, metaV1.ListOptions{})
				if err != nil {
					return err
				}

				continue
			}

			handleEvent(ctx, clientSet, event, config, discordSession)
		}
	}
}

func handleEvent(ctx context.Context, clientSet *kubernetes.Clientset, event watch.Event, config *Config, discordSession *discordgo.Session) {
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

	if !filterEvent(ctx, clientSet, k8sEvent) {
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

func filterEvent(ctx context.Context, clientSet *kubernetes.Clientset, event *coreV1.Event) bool {
	// 一旦 Warning だけ
	if event.Type != "Warning" {
		return false
	}

	// Check if the involved object has the notification-ignored-reasons annotation
	if shouldIgnoreEvent(ctx, clientSet, event) {
		return false
	}

	return true
}

func shouldIgnoreEvent(ctx context.Context, clientSet *kubernetes.Clientset, event *coreV1.Event) bool {
	obj := event.InvolvedObject

	// Get the object's annotations based on its kind
	annotations, err := getObjectAnnotations(ctx, clientSet, obj.Namespace, obj.Kind, obj.Name, obj.APIVersion)
	if err != nil {
		slog.DebugContext(ctx, "failed to get object annotations",
			slog.String("kind", obj.Kind),
			slog.String("namespace", obj.Namespace),
			slog.String("name", obj.Name),
			slog.String("error", err.Error()),
		)
		return false
	}

	// Check for the starry.blue/notification-ignored-reasons annotation
	ignoredReasons, ok := annotations["starry.blue/notification-ignored-reasons"]
	if !ok {
		return false
	}

	// Parse comma-separated reasons
	reasons := strings.Split(ignoredReasons, ",")
	for _, reason := range reasons {
		if strings.TrimSpace(reason) == event.Reason {
			return true
		}
	}

	return false
}

func getObjectAnnotations(ctx context.Context, clientSet *kubernetes.Clientset, namespace, kind, name, apiVersion string) (map[string]string, error) {
	switch kind {
	case "CronJob":
		cronJob, err := clientSet.BatchV1().CronJobs(namespace).Get(ctx, name, metaV1.GetOptions{})
		if err != nil {
			return nil, err
		}
		return cronJob.Annotations, nil
	case "Job":
		job, err := clientSet.BatchV1().Jobs(namespace).Get(ctx, name, metaV1.GetOptions{})
		if err != nil {
			return nil, err
		}

		// For Jobs created by CronJobs, check the parent CronJob's annotations
		for _, owner := range job.OwnerReferences {
			if owner.Kind == "CronJob" {
				cronJob, err := clientSet.BatchV1().CronJobs(namespace).Get(ctx, owner.Name, metaV1.GetOptions{})
				if err != nil {
					slog.DebugContext(ctx, "failed to get parent CronJob annotations",
						slog.String("namespace", namespace),
						slog.String("cronJobName", owner.Name),
						slog.String("error", err.Error()),
					)
				} else if cronJob.Annotations != nil {
					return cronJob.Annotations, nil
				}
			}
		}

		// Fall back to Job's own annotations if no CronJob owner found
		return job.Annotations, nil
	case "Pod":
		pod, err := clientSet.CoreV1().Pods(namespace).Get(ctx, name, metaV1.GetOptions{})
		if err != nil {
			return nil, err
		}
		return pod.Annotations, nil
	case "Deployment":
		deployment, err := clientSet.AppsV1().Deployments(namespace).Get(ctx, name, metaV1.GetOptions{})
		if err != nil {
			return nil, err
		}
		return deployment.Annotations, nil
	case "StatefulSet":
		statefulSet, err := clientSet.AppsV1().StatefulSets(namespace).Get(ctx, name, metaV1.GetOptions{})
		if err != nil {
			return nil, err
		}
		return statefulSet.Annotations, nil
	case "DaemonSet":
		daemonSet, err := clientSet.AppsV1().DaemonSets(namespace).Get(ctx, name, metaV1.GetOptions{})
		if err != nil {
			return nil, err
		}
		return daemonSet.Annotations, nil
	default:
		return nil, fmt.Errorf("unsupported kind: %s", kind)
	}
}

func sendDiscordNotification(session *discordgo.Session, webhookID, webhookToken string, event *coreV1.Event) error {
	var color int
	switch event.Type {
	case coreV1.EventTypeNormal:
		color = 0x00FF00 // 緑
	case coreV1.EventTypeWarning:
		color = 0xFF9900 // オレンジ
	}

	var timestamp time.Time
	switch {
	case !event.LastTimestamp.IsZero():
		timestamp = event.LastTimestamp.Time
	case !event.FirstTimestamp.IsZero():
		timestamp = event.FirstTimestamp.Time
	default:
		timestamp = time.Now()
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
		Timestamp: timestamp.Format(time.RFC3339),
	}

	params := &discordgo.WebhookParams{
		Embeds: []*discordgo.MessageEmbed{embed},
	}

	_, err := session.WebhookExecute(webhookID, webhookToken, false, params)
	return err
}

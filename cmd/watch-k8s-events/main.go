package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
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

			handleEvent(ctx, event, config, discordSession)
		}
	}
}

func handleEvent(ctx context.Context, event watch.Event, config *Config, discordSession *discordgo.Session) {
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

	if !filterEvent(k8sEvent) {
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

func filterEvent(event *coreV1.Event) bool {
	// 一旦 Warning だけ
	if event.Type != "Warning" {
		return false
	}

	// rclone namespace の CronJob はよく失敗するので無視
	if event.Reason == "BackoffLimitExceeded" && event.Namespace == "rclone" && event.InvolvedObject.Kind == "Job" {
		return false
	}

	return true
}

func sendDiscordNotification(session *discordgo.Session, webhookID, webhookToken string, event *coreV1.Event) error {
	var color int
	switch event.Type {
	case "Normal":
		color = 0x00FF00 // 緑
	case "Warning":
		color = 0xFF9900 // オレンジ
	}

	embed := &discordgo.MessageEmbed{
		Title:       fmt.Sprintf("[%s] %s", event.Namespace, event.Reason),
		Description: event.Message,
		Color:       color,
		Fields: []*discordgo.MessageEmbedField{
			{
				Name:   "Object Kind",
				Value:  event.InvolvedObject.Kind,
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
		Timestamp: event.LastTimestamp.Time.Format(time.RFC3339),
	}

	params := &discordgo.WebhookParams{
		Embeds: []*discordgo.MessageEmbed{embed},
	}

	_, err := session.WebhookExecute(webhookID, webhookToken, false, params)
	return err
}

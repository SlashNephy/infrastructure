package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/caarlos0/env/v11"
	meta "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

type Config struct {
	EPGStationURL        string `env:"EPGSTATION_URL,notEmpty"`
	KubernetesNamespace  string `env:"K8S_NAMESPACE,notEmpty"`
	KubernetesDeployment string `env:"K8S_DEPLOYMENT,notEmpty"`
}

func main() {
	ctx := context.Background()
	config, err := env.ParseAs[Config]()
	if err != nil {
		slog.ErrorContext(ctx, "failed to parse environment variables", slog.String("error", err.Error()))
		os.Exit(1)
	}

	k8sConfig, err := rest.InClusterConfig()
	if err != nil {
		slog.ErrorContext(ctx, "failed to create Kubernetes client config", slog.String("error", err.Error()))
		os.Exit(1)
	}

	k8s, err := kubernetes.NewForConfig(k8sConfig)
	if err != nil {
		slog.ErrorContext(ctx, "failed to create Kubernetes client", slog.String("error", err.Error()))
		os.Exit(1)
	}

	if err = checkDeployment(ctx, k8s, config.KubernetesNamespace, config.KubernetesDeployment); err != nil {
		slog.ErrorContext(ctx, "failed to check EPGStation deployment", slog.String("error", err.Error()))
		os.Exit(1)
	}

	for {
		count, err := fetchEPGStationRecordingCount(ctx, config.EPGStationURL)
		if err != nil {
			slog.ErrorContext(ctx, "failed to fetch EPGStation recording count", slog.String("error", err.Error()))
			os.Exit(1)
		}

		if count == 0 {
			break
		}

		slog.DebugContext(ctx, "At least one recording is in progress; wait 5 seconds...")
		time.Sleep(5 * time.Second)
	}

	if err = rolloutDeploymentRestart(ctx, k8s, config.KubernetesNamespace, config.KubernetesDeployment); err != nil {
		slog.ErrorContext(ctx, "failed to restart EPGStation deployment", slog.String("error", err.Error()))
		os.Exit(1)
	}

	slog.InfoContext(ctx, "EPGStation deployment restarted")
}

func checkDeployment(ctx context.Context, k8s *kubernetes.Clientset, namespace, deployment string) error {
	_, err := k8s.AppsV1().Deployments(namespace).Get(ctx, deployment, meta.GetOptions{})
	return err
}

func fetchEPGStationRecordingCount(ctx context.Context, epgStationURL string) (int, error) {
	url := fmt.Sprintf("%s/api/recording?isHalfWidth=false", epgStationURL)
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return 0, err
	}

	response, err := http.DefaultClient.Do(request)
	if err != nil {
		return 0, err
	}

	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		return 0, err
	}

	var result struct {
		Total int `json:"total"`
	}
	if err = json.Unmarshal(body, &result); err != nil {
		return 0, err
	}

	return result.Total, nil
}

func rolloutDeploymentRestart(ctx context.Context, k8s *kubernetes.Clientset, namespace, deployment string) error {
	var patch struct {
		Spec struct {
			Template struct {
				Metadata struct {
					Annotations struct {
						RestartedAt string `json:"kubectl.kubernetes.io/restartedAt"`
					} `json:"annotations"`
				} `json:"metadata"`
			} `json:"template"`
		} `json:"spec"`
	}
	patch.Spec.Template.Metadata.Annotations.RestartedAt = time.Now().Format(time.RFC3339)

	patchData, err := json.Marshal(patch)
	if err != nil {
		return err
	}

	_, err = k8s.AppsV1().Deployments(namespace).Patch(ctx, deployment, types.StrategicMergePatchType, patchData, meta.PatchOptions{
		FieldManager: "restart-epgstation-deployment",
	})
	return err
}

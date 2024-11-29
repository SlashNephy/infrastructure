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

	httpClient := http.DefaultClient

	for {
		count, err := fetchEPGStationRecordingCount(ctx, httpClient, config.EPGStationURL)
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

	if err = rolloutDeploymentRestart(ctx, httpClient, config.KubernetesNamespace, config.KubernetesDeployment); err != nil {
		slog.ErrorContext(ctx, "failed to restart EPGStation deployment", slog.String("error", err.Error()))
		os.Exit(1)
	}

	slog.InfoContext(ctx, "EPGStation deployment restarted")
}

func fetchEPGStationRecordingCount(ctx context.Context, httpClient *http.Client, epgStationURL string) (int, error) {
	url := fmt.Sprintf("%s/api/recording?isHalfWidth=false", epgStationURL)
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return 0, err
	}

	response, err := httpClient.Do(request)
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

func rolloutDeploymentRestart(ctx context.Context, httpClient *http.Client, namespace, deployment string) error {
	config, err := rest.InClusterConfig()
	if err != nil {
		return err
	}

	k8s, err := kubernetes.NewForConfigAndClient(config, httpClient)
	if err != nil {
		return err
	}

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

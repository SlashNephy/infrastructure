package main

import (
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/sourcegraph/conc/pool"
)

const kubernetesRoot = "k8s"

func main() {
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stdout, nil)))

	kustomizationDirs, err := findKustomizationDirs(kubernetesRoot)
	if err != nil {
		slog.Error(
			"failed to find kustomization directories",
			slog.String("error", err.Error()),
		)
		os.Exit(1)
	}

	p := pool.NewWithResults[buildResult]().WithMaxGoroutines(4)
	for _, dir := range kustomizationDirs {
		p.Go(func() buildResult {
			return buildManifest(dir)
		})
	}

	results := p.Wait()
	failedDirs := make([]string, 0)
	for _, result := range results {
		if _, ok := result.(*buildFailed); ok {
			failedDirs = append(failedDirs, result.ManifestRoot())
		}
	}

	if len(failedDirs) > 0 {
		slog.Error(
			"❌ some manifests failed to build",
			slog.Int("count", len(failedDirs)),
			slog.String("roots", strings.Join(failedDirs, ", ")),
		)
		os.Exit(1)
	}
}

func findKustomizationDirs(baseDir string) ([]string, error) {
	var dirs []string
	err := filepath.Walk(baseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.Name() == "kustomization.yaml" && !info.IsDir() {
			dir := filepath.Dir(path)
			if _, err := os.Stat(filepath.Join(dir, ".ci-ignored")); err == nil {
				// .ci-ignored ファイルが存在する場合はスキップ
				return nil
			}

			dirs = append(dirs, dir)
		}

		return nil
	})

	return dirs, err
}

func buildManifest(root string) buildResult {
	cmd := exec.Command("kustomize", "build", "--enable-helm", root)
	output, err := cmd.CombinedOutput()
	if err != nil {
		slog.Error(
			"❌ kustomize build failed",
			slog.String("root", root),
			slog.String("output", string(output)),
		)

		return &buildFailed{
			manifestRoot: root,
		}
	}

	slog.Info(
		"✅ kustomize build succeeded",
		slog.String("root", root),
	)

	return &buildSuccess{
		manifestRoot: root,
	}
}

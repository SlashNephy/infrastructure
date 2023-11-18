package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
	"strings"

	"github.com/jessevdk/go-flags"
)

type Options struct {
	Images    string `short:"i" long:"images" description:"image names (comma separated)" required:"true"`
	NewDigest string `short:"d" long:"digest" description:"new digest" required:"true"`
}

var validDigest = regexp.MustCompile("^[0-9a-f]{64}$")

func main() {
	var options Options
	if _, err := flags.Parse(&options); err != nil {
		log.Fatalf("invalid options: %v", err)
	}

	// check digest
	options.NewDigest = strings.TrimPrefix(options.NewDigest, "sha256:")
	if !validDigest.MatchString(options.NewDigest) {
		log.Fatalf("invalid digest: %s", options.NewDigest)
	}

	images := strings.Split(options.Images, ",")
	if err := updateManifests(images, options.NewDigest); err != nil {
		log.Fatalf("failed to update manifests: %v", err)
	}
}

func updateManifests(images []string, digest string) error {
	const basePath = "k8s"

	patterns := map[string]*regexp.Regexp{}
	for _, image := range images {
		patterns[image] = regexp.MustCompile(fmt.Sprintf("%s@sha256:[0-9a-f]{64}", regexp.QuoteMeta(image)))
	}

	return filepath.Walk(basePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !strings.HasSuffix(info.Name(), ".yaml") {
			return nil
		}

		manifest, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		hasChanged := false
		for image, pattern := range patterns {
			newImageSpec := fmt.Sprintf("%s@sha256:%s", image, digest)
			newManifest := pattern.ReplaceAll(manifest, []byte(newImageSpec))
			if reflect.DeepEqual(manifest, newManifest) {
				continue
			}

			hasChanged = true
			manifest = newManifest
			log.Printf("updated %s with %s", path, newImageSpec)
		}
		if !hasChanged {
			return nil
		}

		return os.WriteFile(path, manifest, 0644)
	})
}

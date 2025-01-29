package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/jessevdk/go-flags"
)

type Options struct {
	URL   string        `long:"url" description:"URL to wait for"`
	DNS   string        `long:"dns" description:"DNS name to resolve"`
	Delay time.Duration `long:"delay" description:"delay between checks" default:"1s"`
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	var options Options
	if _, err := flags.Parse(&options); err != nil {
		log.Fatalf("invalid options: %v", err)
	}

	switch {
	case options.URL != "":
		waitForURL(ctx, options.URL, options.Delay)
	case options.DNS != "":
		waitForDNS(ctx, options.DNS, options.Delay)
	default:
		log.Fatalf("no URL or DNS options provided")
	}
}

func waitForURL(ctx context.Context, url string, delay time.Duration) {
	log.Printf("waiting for URL %s", url)

	for {
		select {
		case <-ctx.Done():
			return
		default:
			response, err := http.DefaultClient.Get(url)
			if err == nil && 200 <= response.StatusCode && response.StatusCode < 300 {
				log.Printf("%s is up", url)
				return
			}

			log.Printf("failed to get %s: %s: %v", url, response.Status, err)
			time.Sleep(delay)
		}
	}
}

func waitForDNS(ctx context.Context, dns string, delay time.Duration) {
	log.Printf("waiting for DNS %s", dns)

	for {
		select {
		case <-ctx.Done():
			return
		default:
			_, err := net.DefaultResolver.LookupHost(ctx, dns)
			if err == nil {
				log.Printf("%s is up", dns)
				return
			}

			log.Printf("failed to resolve %v", err)
			time.Sleep(delay)
		}
	}
}

package main

type buildResult interface {
	ManifestRoot() string
}

type buildSuccess struct {
	manifestRoot string
}

func (b *buildSuccess) ManifestRoot() string {
	return b.manifestRoot
}

var _ buildResult = new(buildSuccess)

type buildFailed struct {
	manifestRoot string
}

func (b *buildFailed) ManifestRoot() string {
	return b.manifestRoot
}

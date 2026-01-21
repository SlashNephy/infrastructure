FROM public.ecr.aws/docker/library/golang:1.25.6-bookworm@sha256:2f768d462dbffbb0f0b3a5171009f162945b086f326e0b2a8fd5d29c3219ff14 AS base
WORKDIR /work

COPY ./go.mod ./go.sum ./
RUN go mod download && go mod verify

FROM base AS build
WORKDIR /work

COPY ./ ./
RUN CGO_ENABLED=0 make build

FROM gcr.io/distroless/static-debian12:nonroot@sha256:cba10d7abd3e203428e86f5b2d7fd5eb7d8987c387864ae4996cf97191b33764
WORKDIR /

COPY --from=build /work/app /

ENTRYPOINT ["/app"]

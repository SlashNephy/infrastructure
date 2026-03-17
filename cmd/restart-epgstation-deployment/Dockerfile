FROM public.ecr.aws/docker/library/golang:1.26.1-bookworm@sha256:4465644228bc2857a954b092167e12aa59c006a3492282a6c820bf4755fd64a4 AS base
WORKDIR /work

COPY ./go.mod ./go.sum ./
RUN go mod download && go mod verify

FROM base AS build
WORKDIR /work

COPY ./ ./
RUN CGO_ENABLED=0 make build

FROM gcr.io/distroless/static-debian12:nonroot@sha256:a9329520abc449e3b14d5bc3a6ffae065bdde0f02667fa10880c49b35c109fd1
WORKDIR /

COPY --from=build /work/app /

ENTRYPOINT ["/app"]

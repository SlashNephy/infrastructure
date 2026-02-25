FROM public.ecr.aws/docker/library/golang:1.26.0-bookworm@sha256:2a0ba12e116687098780d3ce700f9ce3cb340783779646aafbabed748fa6677c AS base
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

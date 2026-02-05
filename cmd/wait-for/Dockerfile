FROM public.ecr.aws/docker/library/golang:1.25.7-bookworm@sha256:38342f3e7a504bf1efad858c18e771f84b66dc0b363add7a57c9a0bbb6cf7b12 AS base
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

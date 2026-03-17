FROM public.ecr.aws/docker/library/golang:1.26.1-bookworm@sha256:b46171cb3e0b1255cb72487533b1f855c59039255e4b74bc2453924178f490f3 AS base
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

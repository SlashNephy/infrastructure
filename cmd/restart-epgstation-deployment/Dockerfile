FROM public.ecr.aws/docker/library/golang:1.23.3-bookworm AS base
WORKDIR /work

COPY ./go.mod ./go.sum ./
RUN go mod download && go mod verify

FROM base AS build
WORKDIR /work

COPY ./ ./
RUN CGO_ENABLED=0 make build

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /

COPY --from=build /work/app /

ENTRYPOINT ["/app"]

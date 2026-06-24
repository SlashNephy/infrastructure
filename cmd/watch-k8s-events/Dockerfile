FROM golang:1.26.4-trixie@sha256:76a29248dedcd75870e95cbd90cc8cb356db082404ac7d3a5803f276c3ba79c9 AS base
WORKDIR /work

COPY ./go.mod ./go.sum ./
RUN go mod download && go mod verify

FROM base AS build
WORKDIR /work

COPY ./ ./
RUN CGO_ENABLED=0 make build

FROM gcr.io/distroless/static-debian13:nonroot
WORKDIR /

COPY --from=build /work/app /

ENTRYPOINT ["/app"]

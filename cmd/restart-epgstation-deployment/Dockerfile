FROM golang:1.26.4-trixie@sha256:3424c834a8b26df82d4b64cf0c92e0f8f309b4ff7f85581f8ec5026e6f7a44da AS base
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

FROM golang:1.26.5-trixie@sha256:4ee9ffa999b4583ce281939cdff828763083610292f252279a0cee77473bd9a7 AS base
WORKDIR /work

COPY ./go.mod ./go.sum ./
RUN go mod download && go mod verify

FROM base AS build
WORKDIR /work

COPY ./ ./
RUN CGO_ENABLED=0 make build

FROM gcr.io/distroless/static-debian13:nonroot@sha256:1c2c046bc09ed40fad370b599a0b1ae7987f55b01e247cf27a7c27cd97e5bbc7
WORKDIR /

COPY --from=build /work/app /

ENTRYPOINT ["/app"]

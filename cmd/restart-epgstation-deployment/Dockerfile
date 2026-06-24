FROM golang:1.26.4-trixie@sha256:a425cb16126d04e54977fca468d65d3f5af8722f8476cf2fe48906d47a626ec0 AS base
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

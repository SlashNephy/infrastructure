FROM golang:1.26.4-trixie@sha256:d4e92b5fc5b198732bc1f90bf08d581a482707c4bc724efd1484e59016c1d992 AS base
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

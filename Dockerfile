# checkov:skip=CKV_DOCKER_2: "Ensure that HEALTHCHECK instructions have been added to container images"
# Grab the latest official Golang image for building the application https://github.com/docker-library/official-images/blob/master/library/golang
FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY app/ .

ARG GOOS=linux
ARG GOARCH=amd64
# Build a statically linked binary with optimized size flags
# - CGO_ENABLED=0 disables dynamic link dependencies, crucial for Alpine's musl libc
# - -ldflags="-w -s" strips debug symbols to drastically reduce the binary
RUN CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build -ldflags="-s -w" -o /greeter .

FROM gcr.io/distroless/static-debian13:nonroot

EXPOSE 8080

COPY --from=builder --chown=65532:65532 /greeter /greeter

# Run securely as the pre-configured 'nonroot' user (UID 65532)
USER nonroot:nonroot

ENTRYPOINT  ["/greeter"]

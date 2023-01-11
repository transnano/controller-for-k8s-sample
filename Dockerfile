# Build the manager binary
FROM golang:1.19.5-buster as builder

WORKDIR /workspace
# For building Go Module required
ENV GOPROXY=direct
ENV GO111MODULE=on
ENV GOARCH=amd64
ENV GOOS=linux
ENV CGO_ENABLED=0
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/

# Build
RUN go build -a -o manager -ldflags "-s -w \
-X github.com/prometheus/common/version.Version=$(git describe --tags --abbrev=0) \
-X github.com/prometheus/common/version.BuildDate=$(date +%FT%T%z) \
-X github.com/prometheus/common/version.Branch=main \
-X github.com/prometheus/common/version.Revision=$(git rev-parse --short HEAD) \
-X github.com/prometheus/common/version.BuildUser=transnano" \
main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
# hadolint ignore=DL3007
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/manager .
USER nonroot:nonroot

ENTRYPOINT ["/manager"]

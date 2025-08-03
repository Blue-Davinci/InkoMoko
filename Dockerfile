# Build stage
FROM golang:1.24.5-alpine AS builder

# Install git for version info and ca-certificates for HTTPS
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build arguments for cross-compilation
ARG TARGETOS
ARG TARGETARCH

# Build the application
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -ldflags="-w -s -extldflags '-static' -X main.version=$(git describe --tags --always --dirty 2>/dev/null || echo 'docker-build')" \
    -a -installsuffix cgo \
    -o /app/bin/api \
    ./cmd/api

# Final stage
FROM scratch

# Import from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy the binary
COPY --from=builder /app/bin/api /api

# Create a non-root user
USER nobody

# Expose port
EXPOSE 4000

# Run the binary
ENTRYPOINT ["/api"]

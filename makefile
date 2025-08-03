.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make build       - Build the application"
	@echo "  make build/api   - Build API server binary"
	@echo "  make run         - Run the application"
	@echo "  make run/api     - Run the API server"
	@echo "  make test        - Run tests"
	@echo "  make clean       - Clean up build artifacts"
	@echo "  make tidy        - Tidy and vendor dependencies"

# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

.PHONY: tidy
tidy:
	@echo "Tidying and verifying module dependencies..."
	go mod tidy
	go mod verify
	@echo "Dependencies tidied!"

.PHONY: audit
audit:
	@echo "Running quality control checks..."
	go mod verify
	go vet ./...
	go run honnef.co/go/tools/cmd/staticcheck@latest -checks=all,-ST1000,-U1000 ./...
	go run golang.org/x/vuln/cmd/govulncheck@latest ./...
	go test -race -buildvcs -vet=off ./...

# ==================================================================================== #
# BUILD
# ==================================================================================== #

.PHONY: build
build: build/api

.PHONY: build/api
build/api:
	@echo "Building API server..."
	GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build \
		-ldflags="-w -s -extldflags '-static' -X main.version=$(shell git describe --tags --always --dirty)" \
		-a -installsuffix cgo \
		-o ./bin/api \
		./cmd/api
	@echo "API server built successfully to ./bin/api"

.PHONY: build/local
build/local:
	@echo "Building API server for local development..."
	go build \
		-ldflags="-X main.version=$(shell git describe --tags --always --dirty)" \
		-o ./bin/api \
		./cmd/api
	@echo "Local API server built successfully to ./bin/api"

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

.PHONY: run
run: run/api

.PHONY: run/api
run/api:
	@echo "Running API server..."
	go run ./cmd/api

.PHONY: test
test:
	@echo "Running tests..."
	go test -v -race -buildvcs ./...

.PHONY: test/cover
test/cover:
	@echo "Running tests with coverage..."
	go test -v -race -buildvcs -coverprofile=/tmp/coverage.out ./...
	go tool cover -html=/tmp/coverage.out

# ==================================================================================== #
# OPERATIONS
# ==================================================================================== #

.PHONY: clean
clean:
	@echo "Cleaning up build artifacts..."
	rm -rf ./bin
	go clean
	@echo "Clean complete!"

.PHONY: docker/build
docker/build:
	@echo "Building Docker image..."
	docker build -t inkomoko:latest .

.PHONY: docker/run
docker/run:
	@echo "Running Docker container..."
	docker run -p 4000:4000 inkomoko:latest 
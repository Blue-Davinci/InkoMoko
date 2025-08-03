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
	@echo "  make compose/up  - Start with nginx (production-like)"
	@echo "  make compose/down - Stop compose services"
	@echo "  make docker/build - Build Docker image"
	@echo ""
	@echo "Docker commands:"
	@echo "  make docker/build  - Build Docker image"
	@echo "  make docker/run    - Run container (foreground)"
	@echo "  make docker/dev    - Run container (background)"
	@echo "  make docker/stop   - Stop running containers"
	@echo "  make docker/clean  - Stop containers and remove image"
	@echo "  make docker/logs   - Show container logs"

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
# DOCKER COMPOSE
# ==================================================================================== #

.PHONY: compose/up
compose/up:
	@echo "Starting services with docker-compose..."
	docker-compose up -d --build
	@echo "Services started! API available at http://localhost"
	@echo "Health check: curl http://localhost/v1/health"
	@echo "Metrics: curl http://localhost/v1/health/metrics"
	@echo "Use 'make compose/logs' to see logs"

.PHONY: compose/up/foreground
compose/up/foreground:
	@echo "Starting services with docker-compose (foreground)..."
	docker-compose up --build

.PHONY: compose/down
compose/down:
	@echo "Stopping docker-compose services..."
	docker-compose down
	@echo "Services stopped!"

.PHONY: compose/down/clean
compose/down/clean:
	@echo "Stopping and cleaning up docker-compose services..."
	docker-compose down --volumes --remove-orphans
	@echo "Services stopped and cleaned up!"

.PHONY: compose/logs
compose/logs:
	@echo "Showing service logs..."
	docker-compose logs -f

.PHONY: compose/logs/api
compose/logs/api:
	@echo "Showing API service logs..."
	docker-compose logs -f api

.PHONY: compose/logs/nginx
compose/logs/nginx:
	@echo "Showing nginx service logs..."
	docker-compose logs -f nginx

.PHONY: compose/restart
compose/restart: compose/down compose/up

.PHONY: compose/rebuild
compose/rebuild:
	@echo "Rebuilding and restarting services..."
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d
	@echo "Services rebuilt and restarted!"

.PHONY: compose/status
compose/status:
	@echo "Checking service status..."
	docker-compose ps

# ==================================================================================== #
# DOCKER
# ==================================================================================== #

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

.PHONY: docker/dev
docker/dev:
	@echo "Running Docker container in background..."
	docker run -d -p 4000:4000 --name inkomoko-api inkomoko:latest
	@echo "Container started. Use 'make docker/logs' to see output"

.PHONY: docker/stop
docker/stop:
	@echo "Stopping inkomoko containers..."
	docker stop $$(docker ps -q --filter ancestor=inkomoko:latest) 2>/dev/null || true
	docker stop inkomoko-api 2>/dev/null || true
	docker rm $$(docker ps -aq --filter ancestor=inkomoko:latest) 2>/dev/null || true
	docker rm inkomoko-api 2>/dev/null || true

.PHONY: docker/clean
docker/clean: docker/stop
	@echo "Removing inkomoko image..."
	docker rmi inkomoko:latest 2>/dev/null || true

.PHONY: docker/logs
docker/logs:
	@echo "Showing container logs..."
	docker logs inkomoko-api 2>/dev/null || \
	docker logs $$(docker ps -q --filter ancestor=inkomoko:latest) 2>/dev/null || \
	echo "No running inkomoko containers found" 
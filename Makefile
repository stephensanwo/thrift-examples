.PHONY: generate build-server build-client run-server run-client clean test server client install build run help

THRIFT_COMPILER = thrift
GO = go
NPM = npm
PIP = pip

GO_SERVER_DIR = go_stream_server
NODE_CLIENT_DIR = nodejs_stream_client
THRIFT_DIR = thrift
GENERATED_DIR = generated

# Create necessary directories
create-dirs:
	mkdir -p $(GENERATED_DIR)/python
	mkdir -p $(GENERATED_DIR)/go
	mkdir -p $(GENERATED_DIR)/nodejs

# Clean specific generated code
clean-weather:
	rm -rf $(GO_SERVER_DIR)/weather
	rm -rf $(NODE_CLIENT_DIR)/src/generated
	rm -rf $(NODE_CLIENT_DIR)/dist
	rm -rf $(GENERATED_DIR)/go/weather
	rm -rf $(GENERATED_DIR)/nodejs/weather

clean-llm:
	rm -rf go_llm_client/llm
	rm -rf $(GENERATED_DIR)/python/llm
	rm -rf $(GENERATED_DIR)/go/llm

# Clean all generated code and build artifacts
clean: clean-weather clean-llm
	rm -rf $(NODE_CLIENT_DIR)/node_modules
	rm -rf $(GENERATED_DIR)

test:
	cd $(GO_SERVER_DIR) && $(GO) test ./...
	cd $(NODE_CLIENT_DIR) && $(NPM) test

server:
	cd $(GO_SERVER_DIR) && $(GO) run server.go

client:
	cd $(NODE_CLIENT_DIR) && $(NPM) start

install:
	cd $(GO_SERVER_DIR) && $(GO) mod download
	cd $(NODE_CLIENT_DIR) && $(NPM) install

build: generate-weather generate-llm
	cd $(GO_SERVER_DIR) && $(GO) build
	cd $(NODE_CLIENT_DIR) && $(NPM) run build

# Run both services (in separate terminals)
run: server client

help:
	@echo "Available commands:"
	@echo "  make generate-weather  - Generate Thrift code for weather service"
	@echo "  make generate-llm     - Generate Thrift code for LLM service"
	@echo "  make clean-weather    - Clean weather service generated code"
	@echo "  make clean-llm       - Clean LLM service generated code"
	@echo "  make clean           - Clean all generated code and artifacts"
	@echo "  make test            - Run tests for both services"
	@echo "  make server          - Start the Go server"
	@echo "  make client          - Start the Node.js client"
	@echo "  make install         - Install dependencies"
	@echo "  make build           - Build both services"
	@echo "  make run             - Run both services"
	@echo "  make help            - Show this help message"

generate-llm: create-dirs clean-llm
	@echo "Generating code from thrift files..."
	$(THRIFT_COMPILER) --gen py -out $(GENERATED_DIR)/python $(THRIFT_DIR)/llm.thrift
	$(THRIFT_COMPILER) --gen go -out $(GENERATED_DIR)/go $(THRIFT_DIR)/llm.thrift
	cp -r $(GENERATED_DIR)/go/llm go_llm_client/

build-llm-server:
	cd python_llm_server && uv sync

build-llm-client:
	cd go_llm_client && go mod tidy && go build -o llm_client

run-llm-server:
	cd python_llm_server && uv run python server.py

run-llm-client:
	cd go_llm_client && go run main.go

generate-weather: create-dirs clean-weather
	$(THRIFT_COMPILER) --gen go -out $(GENERATED_DIR)/go $(THRIFT_DIR)/weather.thrift
	$(THRIFT_COMPILER) --gen js:node -out $(GENERATED_DIR)/nodejs $(THRIFT_DIR)/weather.thrift
	cp -r $(GENERATED_DIR)/go/weather $(GO_SERVER_DIR)/
	mkdir -p $(NODE_CLIENT_DIR)/src/generated
	cp -r $(GENERATED_DIR)/nodejs/* $(NODE_CLIENT_DIR)/src/generated/

build-weather-server:
	cd $(GO_SERVER_DIR) && (test -f go.mod || go mod init go_stream_server) && go mod tidy && go build -o weather_server

build-weather-client:
	cd $(NODE_CLIENT_DIR) && npm install && npm run build

run-weather-server:
	cd $(GO_SERVER_DIR) && go run server.go

run-weather-client:
	make build-weather-client && cd $(NODE_CLIENT_DIR) && npm run start
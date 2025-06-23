.PHONY: generate build-server build-client run-server run-client clean test server client install build run help

THRIFT_COMPILER = thrift
GO = go
NPM = npm
PIP = pip

GO_SERVER_DIR = go_stream_server
NODE_CLIENT_DIR = nodejs_stream_client
THRIFT_DIR = thrift

generate:
	# Generate Go code
	$(THRIFT_COMPILER) -r --gen go $(THRIFT_DIR)/weather.thrift
	# Generate TypeScript code
	$(THRIFT_COMPILER) -r --gen js:node,ts $(THRIFT_DIR)/weather.thrift
	# Move generated files to their respective directories
	mv gen-go/weather $(GO_SERVER_DIR)/
	mv gen-nodejs/* $(NODE_CLIENT_DIR)/src/generated/
	rm -rf gen-go gen-nodejs

clean:
	rm -rf gen-go gen-nodejs
	rm -rf $(GO_SERVER_DIR)/weather
	rm -rf $(NODE_CLIENT_DIR)/src/generated
	rm -rf $(NODE_CLIENT_DIR)/dist
	rm -rf $(NODE_CLIENT_DIR)/node_modules

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

build: generate
	cd $(GO_SERVER_DIR) && $(GO) build
	cd $(NODE_CLIENT_DIR) && $(NPM) run build

# Run both services (in separate terminals)
run: server client

help:
	@echo "Available commands:"
	@echo "  make generate  - Generate Thrift code for both services"
	@echo "  make clean    - Clean generated code and build artifacts"
	@echo "  make test     - Run tests for both services"
	@echo "  make server   - Start the Go server"
	@echo "  make client   - Start the Node.js client"
	@echo "  make install  - Install dependencies"
	@echo "  make build    - Build both services"
	@echo "  make run      - Run both services"
	@echo "  make help     - Show this help message"

generate-llm:
	@echo "Generating code from thrift files..."
	make clean
	mkdir -p generated/python generated/go
	thrift --gen py -out generated/python thrift/llm.thrift
	thrift --gen go -out generated/go thrift/llm.thrift
	cp -r generated/go/* go_llm_client/

build-llm-server:
	cd python_llm_server && uv sync

build-llm-client:
	cd go_llm_client && go mod tidy && go build -o llm_client

run-llm-server:
	cd python_llm_server && uv run python server.py

run-llm-client:
	cd go_llm_client && go run main.go

clean-llm:
	make clean
	rm -rf go_llm_client/llm

generate-weather:
	make clean
	mkdir -p generated/go generated/nodejs
	thrift --gen go -out generated/go thrift/weather.thrift
	thrift --gen js:node -out generated/nodejs thrift/weather.thrift
	cp -r generated/go/* go_stream_server/
	mkdir -p nodejs_stream_client/src/generated
	cp -r generated/nodejs/* nodejs_stream_client/src/generated/

build-weather-server:
	cd go_stream_server && (test -f go.mod || go mod init github.com/example/weather-stream-server) && go mod tidy && go build -o weather_server

build-weather-client:
	cd nodejs_stream_client && npm install && npm run build

run-weather-server:
	cd go_stream_server && go run server.go

run-weather-client:
	make build-weather-client && cd nodejs_stream_client && npm run start

clean-weather:
	make clean
	rm -rf go_stream_server/weather_server
	rm -rf nodejs_stream_client/dist
	rm -rf nodejs_stream_client/src/generated
	rm -rf generated/
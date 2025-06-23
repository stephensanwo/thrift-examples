.PHONY: generate build-server build-client run-server run-client clean

generate:
	@echo "Generating code from thrift files..."
	make clean
	mkdir generated generated/python generated/go
	thrift --gen py -out generated/python thrift/llm.thrift
	thrift --gen go -out generated/go thrift/llm.thrift
	cp -r generated/go/* go_client/

build-server:
	cd python_server && uv sync

build-client:
	cd go_client && go mod tidy && go build -o llm_client

run-server:
	cd python_server && uv run python server.py

run-client:
	cd go_client && go run main.go

clean:
	rm -rf generated/
	rm -rf go_client/gen-go/
	rm -f go_client/llm_client
# FBThrift Example Projects

This repository contains two example projects demonstrating the use of Facebook's Thrift (FBThrift) for building microservices:

1. LLM Service (Go + Python)
2. Weather Service (Go + Node.js)

## 1. LLM Service

A language model service implementation using FBThrift, with a Go client and Python server.

### Project Structure
```
llm_service/
├── thrift/
│   └── llm.thrift          # Thrift service definition
├── python_llm_server/
│   ├── server.py           # Python server implementation
│   ├── requirements.txt    # Python dependencies
│   └── generated/          # Generated Python Thrift code
├── go_llm_client/
│   ├── main.go            # Go client implementation
│   ├── go.mod             # Go module file
│   ├── go.sum             # Go dependencies
│   └── generated/         # Generated Go Thrift code
└── Makefile              # Build and run commands
```

### Features
- Text generation endpoint
- Text classification endpoint
- Streaming responses
- Configurable model parameters

### Prerequisites
- Python 3.8+
- Go 1.19+
- FBThrift compiler
- Make

### Setup and Running

1. Install dependencies:
```bash
# Python server dependencies
cd python_llm_server
pip install -r requirements.txt

# Go client dependencies
cd go_llm_client
go mod download
```

2. Generate Thrift code:
```bash
make generate
```

3. Start the Python server:
```bash
make server
```

4. Run the Go client:
```bash
make client
```

### Makefile Commands
- `make generate`: Generate Thrift code for both Go and Python
- `make server`: Start the Python LLM server
- `make client`: Run the Go client
- `make clean`: Clean generated code
- `make test`: Run tests

## 2. Weather Service

A real-time weather service using FBThrift, with a Go server and Node.js client.

### Project Structure
```
weather_service/
├── thrift/
│   └── weather.thrift      # Thrift service definition
├── go_stream_server/
│   ├── server.go          # Go server implementation
│   ├── go.mod             # Go module file
│   ├── go.sum             # Go dependencies
│   └── weather/           # Generated Go Thrift code
├── nodejs_stream_client/
│   ├── src/
│   │   ├── server.ts      # Node.js server implementation
│   │   └── generated/     # Generated TypeScript Thrift code
│   ├── public/
│   │   └── index.html     # Web client interface
│   ├── package.json       # Node.js dependencies
│   └── tsconfig.json      # TypeScript configuration
└── Makefile              # Build and run commands
```

### Features
- Real-time weather data fetching
- OpenMeteo API integration
- Web-based client interface
- Location-based temperature lookup

### Prerequisites
- Go 1.19+
- Node.js 16+
- FBThrift compiler
- Make

### Setup and Running

1. Install dependencies:
```bash
# Node.js client dependencies
cd nodejs_stream_client
npm install

# Go server dependencies
cd go_stream_server
go mod download
```

2. Generate Thrift code:
```bash
make generate
```

3. Start the Go server:
```bash
make server
```

4. Start the Node.js client:
```bash
make client
```

5. Access the web interface:
```
http://localhost:3000
```

### Makefile Commands
- `make generate`: Generate Thrift code for both Go and TypeScript
- `make server`: Start the Go weather server
- `make client`: Start the Node.js client server
- `make clean`: Clean generated code
- `make test`: Run tests


### API Endpoints
- `POST /api/temperature`: Get temperature for a location
  ```json
  {
    "location": "london"
  }
  ```
  Response:
  ```json
  {
    "temperature": 20.5,
    "location": "london",
    "timestamp": 1234567890,
    "unit": "celsius"
  }
  ```
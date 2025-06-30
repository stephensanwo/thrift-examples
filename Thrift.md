# Understanding and Implementing Apache Thrift

## RPC 101: The Basics

### What is RPC?
Remote Procedure Call (RPC) enables programs to execute procedures on remote systems as if they were local calls. This abstraction simplifies distributed systems development by hiding the complexity of network communication.

### Why RPC?
- **Simplicity**: Write distributed applications as if they're local
- **Language Agnostic**: Connect services written in different programming languages
- **Performance**: More efficient than REST for high-frequency internal service calls
- **Type Safety**: Compile-time type checking across language boundaries

### RPC vs REST

When building distributed systems, choosing between RPC (Remote Procedure Call) and REST (Representational State Transfer) is a crucial architectural decision. While both enable service-to-service communication, they serve different purposes and excel in different scenarios.

**REST (Representational State Transfer)**
- Architectural style built on HTTP
- Resource-centric approach (nouns)
- Uses standard HTTP methods (GET, POST, PUT, DELETE)
- Self-documenting through URLs
- Great for public APIs and web services
- Example: `GET /api/weather/london` to get London's weather

**RPC (Remote Procedure Call)**
- Protocol for direct function calls between services
- Action-centric approach (verbs)
- Methods can have any name
- Contract-first development with IDL
- Optimized for internal service communication
- Example: `getWeather("london")` as a direct function call

| Aspect | RPC | REST |
|--------|-----|------|
| **Mental Model** | Everything is a procedure call<br>`getWeather("london")`<br>`updateTemperature("london", 25.5)` | Everything is a resource<br>`GET /api/weather/london`<br>`PUT /api/weather/london` |
| **Interface Design** | Focus on actions and parameters<br>`searchWeather(location, date, unit)`<br>`streamTemperature(location, interval)` | Focus on resources and relationships<br>`GET /weather?location=london&date=2024-03-20`<br>`GET /weather/london/forecast` |
| **State Management** | Can be stateless or stateful<br>`openWeatherStream()`<br>`readNextUpdate()`<br>`closeStream()` | Stateless by design<br>`GET /weather/stream?from=timestamp`<br>Each request is independent |
| **Use Cases** | Microservices, internal APIs<br>`updateUserPreferences(userId, prefs)`<br>`batchProcessWeather(locations[])` | Public APIs, CRUD operations<br>`PUT /users/{id}/preferences`<br>`GET /weather/batch?locations=london,paris` |
| **Protocol** | Binary (typically)<br>`[0x02][4C 6F 6E 64 6F 6E]` | HTTP<br>`Content-Type: application/json` |
| **Contract** | Strict IDL/Schema required<br>```thrift<br>service WeatherService {<br>  Weather getWeather(1: string location)<br>}``` | Loose (OpenAPI/Swagger)<br>```yaml<br>paths:<br>  /weather/{location}:<br>    get:``` |
| **Versioning** | Field-level in IDL<br>```thrift<br>struct WeatherV2 {<br>  1: string location<br>  2: optional double humidity<br>}``` | URL/Media type versioning<br>`/api/v1/weather`<br>`Accept: application/vnd.weather.v2+json` |
| **Error Handling** | Strongly typed exceptions<br>```thrift<br>exception WeatherError {<br>  1: string message<br>}``` | HTTP status codes<br>`404 Not Found`<br>`{"error": "Location not found"}` |
| **Discovery** | Service registry needed<br>```json<br>{"service": "weather",<br> "endpoint": "rpc://host:9090"}``` | URLs and HATEOAS<br>```json<br>{"_links": {<br>  "forecast": "/weather/london/forecast"<br>}}``` |
| **Network Efficiency** | Efficient binary format<br>`[length][method][data]`<br>~50 bytes total | Headers + JSON<br>`{numerous HTTP headers}`<br>~500 bytes total |
| **Testing** | Unit testing focused<br>```go<br>func TestGetWeather(t *testing.T) {<br>  result := client.GetWeather("london")<br>}``` | HTTP client testing<br>```javascript<br>fetch('/api/weather/london')<br>  .then(response => ...)``` |
| **Performance** | Higher (binary protocol, fewer round trips) | Lower (text-based, more round trips) |
| **Debugging** | More difficult (binary format) | Easier (human-readable) |
| **Learning Curve** | Steeper (IDL, code generation) | Gentler (standard HTTP) |
| **Security** | Custom authentication/encryption | Standard HTTP security (OAuth, JWT) |
| **Caching** | Custom implementation needed | Built into HTTP (ETag, Cache-Control) |
| **Scalability** | Vertical (function complexity) | Horizontal (resource scaling) |
| **Browser Support** | Requires additional libraries | Native support |
| **Documentation** | Generated from IDL | OpenAPI/Swagger ecosystem |

### Data Transmission: RPC vs REST

#### REST Data Flow
```bash
HTTP Request
POST /api/weather/temperature
Headers:
  Content-Type: application/json
  Authorization: Bearer token123
Body:
{
  "location": "London",
  "unit": "celsius"
}

HTTP Response
Status: 200 OK
Headers:
  Content-Type: application/json
Body:
{
  "location": "London",
  "temperature": 20.5,
  "unit": "celsius"
}
```

#### Thrift RPC Data Flow
```bash
Binary Message Format:
[Message Length][Protocol Version][Method Name Length][Method Name][Type][Sequence ID][Field ID][Field Type][Field Data]...

Example Weather Request (Binary representation):
00 00 00 4A          // Message length: 74 bytes
80 01                // Protocol version & message type
00 00 00 0D          // Method name length: 13
67 65 74 54 65 6D... // "getTemperature" in ASCII
00 00 00 01          // Sequence ID: 1
0B                   // Field type: String
00 01                // Field ID: 1
00 00 00 06          // String length: 6
4C 6F 6E 64 6F 6E    // "London" in ASCII
00                   // End of struct
```

#### Key Differences in Data Transmission

1. **Serialization**
   - **REST**:
     ```json
     // Human-readable JSON
     {
       "location": "London",
       "unit": "celsius"
     }
     ```
   - **Thrift RPC**:
     ```
     // Binary format (hex representation)
     0B 00 01 00 00 00 06 4C 6F 6E 64 6F 6E
     ```

2. **Protocol Overhead**
   - **REST**:
     ```http
     // Headers add significant overhead
     POST /api/weather/temperature HTTP/1.1
     Host: weather-service.com
     Content-Type: application/json
     Authorization: Bearer token123
     Accept: application/json
     Content-Length: 47
     ```
   - **Thrift RPC**:
     ```
     // Minimal protocol overhead
     [4-byte length][2-byte protocol][method name][payload]
     ```

3. **Type Safety**
   - **REST**:
     ```typescript
     // Types must be validated at runtime
     interface WeatherRequest {
       location?: string;  // Optional in REST
       unit?: string;     // Optional in REST
     }
     ```
   - **Thrift RPC**:
     ```thrift
     // Compile-time type checking
     struct WeatherRequest {
       1: required string location,
       2: optional string unit = "celsius"
     }
     ```

4. **Network Usage Example**

For the same weather request:

```
Data: {"location": "London", "unit": "celsius"}

REST HTTP Request Size:
- Headers: ~200 bytes
- Body: 47 bytes
- Total: ~247 bytes

Thrift RPC Request Size:
- Protocol overhead: 8 bytes
- Method name: 13 bytes
- Data: ~20 bytes
- Total: ~41 bytes
```

5. **Processing Steps**

REST:
```
Client → Server
1. Construct HTTP request
2. Serialize JSON
3. Add HTTP headers
4. Send over TCP
5. Server receives HTTP request
6. Parse HTTP headers
7. Deserialize JSON
8. Validate types
9. Process request

Server → Client
1. Construct response object
2. Serialize to JSON
3. Add HTTP headers
4. Send over TCP
5. Client receives HTTP response
6. Parse HTTP headers
7. Deserialize JSON
8. Validate types
```

Thrift RPC:
```
Client → Server
1. Serialize directly to binary
2. Add minimal protocol header
3. Send over TCP
4. Server receives binary data
5. Deserialize with schema
6. Process request

Server → Client
1. Serialize directly to binary
2. Add minimal protocol header
3. Send over TCP
4. Client receives binary data
5. Deserialize with schema
```

6. **Error Handling**
   - **REST**:
     ```http
     HTTP/1.1 404 Not Found
     Content-Type: application/json
     
     {
       "error": "Location not found",
       "code": "NOT_FOUND"
     }
     ```
   - **Thrift RPC**:
     ```thrift
     exception LocationNotFound {
       1: string message,
       2: string errorCode
     }
     
     service WeatherService {
       WeatherResponse getTemperature(1: WeatherRequest request)
         throws (1: LocationNotFound notFound)
     }
     ```

7. **Connection Management**
   - **REST**: New TCP connection per request (unless using HTTP/2 or Keep-Alive)
   - **Thrift RPC**: Persistent connections with multiplexing


| Aspect | RPC (Thrift) | REST (HTTP) | Example/Notes |
|--------|--------------|-------------|---------------|
| **Serialization Format** | Binary encoding | JSON/Text encoding | RPC: `0B 00 01 4C 6F 6E 64 6F 6E`<br>REST: `{"location": "London"}` |
| **Message Structure** | [Length][Version][Method][Payload] | [Headers][Method][URL][Body] | RPC: Compact binary format<br>REST: HTTP protocol format |
| **Headers/Metadata** | Minimal protocol headers<br>(~10 bytes) | HTTP headers<br>(200-800 bytes) | RPC: Version, sequence ID<br>REST: Content-Type, Auth, etc. |
| **Request Example** | ```getTemperature("London")```<br>Total size: ~30-50 bytes | ```GET /api/weather/london```<br>Total size: ~200-500 bytes | RPC: Compact binary format<br>REST: HTTP protocol format |
| **Type Information** | Embedded in protocol<br>Compile-time checking | Content-Type header<br>Runtime validation | RPC: Type safety by design<br>REST: Schema validation needed |
| **Error Handling** | ```exception WeatherError {<br>  1: string message<br>}``` | ```HTTP 404: Not Found<br>{"error": "Location not found"}``` | RPC: Strongly typed<br>REST: Status codes |
| **Processing Steps** | 1. Serialize to binary<br>2. Send over TCP<br>3. Deserialize with schema | 1. Build HTTP request<br>2. Add headers<br>3. Serialize JSON<br>4. Send over TCP<br>5. Parse headers<br>6. Deserialize JSON | RPC: Fewer steps<br>REST: More overhead |
| **Connection** | Persistent, multiplexed | New TCP connection<br>(unless HTTP/2) | RPC: Better for high frequency<br>REST: Better for occasional calls |
| **Data Size Example**<br>(Weather request) | Method name: 13 bytes<br>Protocol overhead: 8 bytes<br>Data: ~20 bytes<br>**Total: ~41 bytes** | Headers: ~200 bytes<br>URL: ~30 bytes<br>JSON data: ~47 bytes<br>**Total: ~277 bytes** | RPC uses ~15% of REST size |
| **Validation** | Compile-time<br>Generated code | Runtime<br>Schema validation | RPC: Earlier error detection<br>REST: More flexible |


This explains why Thrift RPC is generally more efficient for internal service communication:
- Less protocol overhead
- Binary format is more compact
- Fewer processing steps
- Type safety at compile time
- Efficient connection reuse
- Purpose-built for service-to-service communication

## RPC Implementations

### Popular Options
1. **gRPC**: Google's modern RPC framework using HTTP/2
2. **Apache Thrift**: Originally from Facebook, now Apache project
3. **FBThrift**: Facebook's fork with additional features
4. **Protocol Buffers**: Google's data serialization (often used with gRPC)

### Why Choose Thrift?
- Mature and battle-tested
- Supports many programming languages
- Efficient binary protocol
- Simple IDL (Interface Definition Language)

## Apache Thrift vs FBThrift

### History
- 2007: Facebook creates Thrift
- 2008: Donated to Apache Software Foundation
- 2014: Facebook forks as FBThrift with custom improvements

### Key Differences
- FBThrift has better C++ support
- FBThrift includes RocketServer (high-performance server)
- Apache Thrift has broader language support
- Apache Thrift is more commonly used in open source

### Language Support in Our Project
- Go (Server)
- Node.js (Client)
- Python (LLM Service)

## Getting Started with Apache Thrift

### Components
1. **IDL Compiler**: Generates code from Thrift definitions
2. **Protocol Layer**: Handles data serialization
3. **Transport Layer**: Manages network communication
4. **Server Layer**: Processes incoming requests

### Transport Layer Deep Dive

The transport layer provides a simple abstraction for reading/writing from/to the network. It's responsible for the actual data transmission.

#### Available Transports

1. **TSocket**
   - Basic socket transport
   - Uses TCP for data transmission
   - Most common for direct server-client communication
   ```go
   transport := thrift.NewTSocketConf("localhost:9090", &thrift.TConfiguration{})
   ```

2. **TBufferedTransport**
   - Adds buffering to another transport
   - Improves performance by reducing system calls
   - Recommended for production use
   ```go
   transport := thrift.NewTBufferedTransport(socket, 8192)
   ```

3. **TFramedTransport**
   - Messages are framed with a length prefix
   - Required for non-blocking servers
   - Essential for async processing
   ```typescript
   const transport = new thrift.TFramedTransport(socket);
   ```

4. **THttpTransport**
   - Uses HTTP as transport protocol
   - Useful for browser-based clients
   - Can traverse firewalls more easily
   ```python
   transport = THttpClient.THttpClient('http://localhost:8080/api')
   ```

### Protocol Layer Deep Dive

The protocol layer defines how types are converted to/from bytes. It handles data serialization and deserialization.

#### Available Protocols

1. **TBinaryProtocol**
   - Simple binary format
   - Fast and compact
   - Our project's default choice
   ```go
   protocol := thrift.NewTBinaryProtocolConf(transport, &thrift.TConfiguration{})
   ```

2. **TCompactProtocol**
   - More compact than binary
   - Variable-length integers
   - Better network utilization
   ```typescript
   const protocol = new thrift.TCompactProtocol(transport);
   ```

3. **TJSONProtocol**
   - JSON-based protocol
   - Human readable
   - Good for debugging
   ```python
   protocol = TJSONProtocol(transport)
   ```

4. **TSimpleJSONProtocol**
   - Write-only JSON protocol
   - Useful for JavaScript clients
   - No support for reading

### Protocol and Transport Combinations

Here's how we use different combinations in our project:

#### Go Weather Server
```go
// Server setup
transport := thrift.NewTServerSocket(":9090")
processor := weather.NewWeatherMonitorProcessor(handler)
server := thrift.NewTSimpleServer4(
    processor,
    transport,
    thrift.NewTBufferedTransportFactory(8192),
    thrift.NewTBinaryProtocolFactoryConf(&thrift.TConfiguration{}),
)
```

#### Node.js Weather Client
```typescript
// Client setup
const transport = thrift.createConnection("localhost", 9090, {
    transport: thrift.TBufferedTransport,
    protocol: thrift.TBinaryProtocol
});

const client = thrift.createClient(WeatherMonitor, transport);
```

#### Python LLM Server
```python
# Server setup
transport = TSocket.TServerSocket(host="127.0.0.1", port=8080)
tfactory = TTransport.TBufferedTransportFactory()
pfactory = TBinaryProtocol.TBinaryProtocolFactory()

processor = LanguageModel.Processor(handler)
server = TServer.TSimpleServer(processor, transport, tfactory, pfactory)
```

### Performance Considerations

1. **Transport Selection**
   - TBufferedTransport for general use
   - TFramedTransport for async operations
   - THttpTransport when HTTP is required

2. **Protocol Selection**
   - TBinaryProtocol for balance of speed/size
   - TCompactProtocol for network efficiency
   - TJSONProtocol for debugging only

3. **Combinations**
   | Transport | Protocol | Use Case |
   |-----------|----------|----------|
   | TBuffered | TBinary  | General Purpose |
   | TFramed   | TCompact | High Performance |
   | THttpTransport | TJSON | Debugging |

### Security Considerations

1. **Transport Security**
   - TSSLSocket for encrypted communication
   - Custom transport wrappers for additional security

2. **Authentication**
   - Custom processors for auth headers
   - Middleware for token validation

3. **Best Practices**
   - Never expose binary protocols to public internet
   - Use TLS for all production services
   - Implement rate limiting
   - Add request validation

### Installation
```bash
# macOS
brew install thrift

# Ubuntu
apt-get install thrift-compiler
```

## Thrift IDL by Example

### Basic Types
```thrift
// Basic types available
bool    // Boolean value
i32     // 32-bit integer
i64     // 64-bit integer
double  // Double precision float
string  // String
binary  // Byte array
```

### Weather Service Example
```thrift
// weather.thrift
namespace go weather
namespace js weather

struct WeatherRequest {
    1: string location
}

struct WeatherResponse {
    1: string location
    2: double temperature
    3: string unit
}

service WeatherMonitor {
    WeatherResponse getTemperature(1: WeatherRequest request)
}
```

### Key IDL Features
- Field numbers for versioning
- Required vs Optional fields
- Namespaces for language-specific code organization
- Services define RPC interfaces

### Type Evolution and Schema Management

#### Field Numbers and Immutability

Field numbers are critical in Thrift - they are the contract between clients and servers. They determine how data is serialized and deserialized.

```thrift
// Original version
struct WeatherResponse {
    1: string location,        // Never change this field number
    2: double temperature,     // Never change this field number
    3: string unit            // Never change this field number
}

// WRONG - Never do this
struct WeatherResponse {
    1: string city,           // Don't rename field 1
    3: string unit,           // Don't reorder fields
    2: double temp           // Don't rename field 2
}
```

#### Adding New Fields

When adding new fields, always:
1. Make them optional
2. Use new field numbers
3. Provide default values

```thrift
// Evolution v1 -> v2
struct WeatherResponse {
    1: string location,
    2: double temperature,
    3: string unit,
    4: optional double humidity = 0.0,         // New optional field
    5: optional string condition = "unknown"   // New optional field with default
}
```

#### Deprecating Fields

Never delete fields directly. Instead:
1. Mark them as deprecated in comments
2. Make them optional
3. Consider renaming with 'DEPRECATED_' prefix

```thrift
struct WeatherResponse {
    1: string location,
    2: double temperature,
    3: string unit,
    // @deprecated - Use condition field instead (since v2.1)
    4: optional double humidity,
    5: string condition,
    6: optional list<string> DEPRECATED_old_conditions  // Clear deprecation signal
}
```

#### Type Changes and Compatibility

##### Safe Changes
```thrift
// Original
struct UserProfile {
    1: required i32 id,
    2: required string name
}

// Safe evolution
struct UserProfile {
    1: required i64 id,        // Safe: i32 -> i64
    2: required string name,
    3: optional list<string> tags = []  // Safe: new optional field
}
```

##### Unsafe Changes
```thrift
// UNSAFE changes - Don't do these
struct UserProfile {
    1: required string id,     // Unsafe: i32 -> string
    2: required binary name    // Unsafe: string -> binary
}
```

#### Required vs Optional Fields

##### When to Use Required
- Primary keys
- Essential business logic fields
- Fields that must be validated

```thrift
struct WeatherRequest {
    1: required string location,     // Location is essential
    2: optional string language = "en"  // Language can have default
}
```

##### When to Use Optional
- New fields in schema evolution
- Fields that might be empty
- Fields with default values

```thrift
struct WeatherAlert {
    1: required string alertType,
    2: required string location,
    3: optional string severity = "moderate",
    4: optional string description,              // Might be empty
    5: optional i64 expirationTime = 0          // Added in v2
}
```

#### Versioning Strategies

##### Using Struct Versioning
```thrift
// Version 1
struct DataV1 {
    1: required string field1
}

// Version 2
struct DataV2 {
    1: required string field1,
    2: optional string field2
}

// Wrapper struct
struct Data {
    1: optional DataV1 v1,
    2: optional DataV2 v2
}
```

##### Using Optional Fields
```thrift
struct FeatureFlags {
    1: optional bool legacy_feature = true,      // Original
    2: optional bool beta_feature = false,       // Added in v2
    3: optional bool experimental = false        // Added in v3
}
```

#### Breaking Changes Management

1. **Forward Compatibility**
```thrift
// Original
struct Message {
    1: required string content
}

// Forward compatible change
struct Message {
    1: required string content,
    2: optional map<string, string> metadata = {},  // New clients can use this
    3: optional i32 version = 1                    // Version tracking
}
```

2. **Backward Compatibility**
```thrift
// Handling removed functionality
struct ApiResponse {
    1: required string data,
    // @deprecated - Removed in v2, kept for backward compatibility
    2: optional string legacy_field,
    3: optional string new_field = "default"  // Replacement for legacy_field
}
```

#### Best Practices for Schema Evolution

1. **Documentation**
```thrift
/**
 * WeatherResponse represents current weather conditions
 * @version 2.1
 * @since 1.0
 * @deprecated field: humidity (use condition instead)
 */
struct WeatherResponse {
    // ... fields ...
}
```

2. **Version Tracking**
```thrift
const string API_VERSION = "2.1.0"

struct BaseResponse {
    1: required bool success,
    2: optional string error_message,
    3: optional string api_version = API_VERSION
}
```

3. **Migration Support**
```thrift
service WeatherService {
    // Current version
    WeatherResponse getWeather(1: WeatherRequest request),
    
    // Legacy support, marked for deprecation
    // @deprecated: Use getWeather instead
    WeatherResponse getWeatherV1(1: string location)
}
```

## Code Generation

### Command Structure
```bash
thrift --gen <language> -out <dir> <thrift_file>
```

### Our Project Example
```bash
# Generate Go server code
thrift --gen go -out generated/go weather.thrift

# Generate Node.js client code
thrift --gen js:node -out generated/nodejs weather.thrift
```

## Implementing Servers

### Go Server Example
```go
type WeatherMonitorHandler struct{}

func (h *WeatherMonitorHandler) GetTemperature(ctx context.Context, req *weather.WeatherRequest) (*weather.WeatherResponse, error) {
    return &weather.WeatherResponse{
        Location:    req.Location,
        Temperature: 25.0,
        Unit:       "celsius",
    }, nil
}
```

### Key Server Concepts
- Implement generated interface
- Handle concurrent requests
- Manage errors appropriately
- Choose appropriate transport/protocol

## Implementing Clients

### Node.js Client Example
```typescript
const client = thrift.createClient(WeatherMonitor, connection);

async function getWeather(location: string) {
    const response = await client.getTemperature({
        location: location
    });
    console.log(`Temperature in ${response.location}: ${response.temperature}°${response.unit}`);
}
```

### Client Best Practices
- Connection pooling
- Error handling
- Retry logic
- Timeout management

## Advanced Topics

### Error Handling
```thrift
exception WeatherServiceError {
    1: string message
    2: i32 errorCode
}

service WeatherMonitor {
    WeatherResponse getTemperature(1: WeatherRequest request) throws (1: WeatherServiceError error)
}
```

### Versioning
- Never change existing field numbers
- Add only optional fields
- Use default values wisely
- Consider backward compatibility

### Testing
```bash
# Run Go server tests
make test-weather-server

# Run Python LLM service tests
make test-llm-server
```

## Security in Thrift

### Security Layer Overview

Thrift's security can be implemented at multiple layers, each providing different types of protection:

```
Application Layer (Custom Logic)
├── Access control
├── Request validation
└── Custom authentication logic
           ↓
Protocol Layer (Data Format)
├── Authentication tokens
├── Custom security headers
└── Session management
           ↓
Transport Layer (TLS/SSL)
├── Certificate-based authentication
├── Encryption in transit
└── Server/Client verification
           ↓
Network Layer (Firewalls/VPNs)
├── Network segmentation
├── Firewall rules
└── Access control lists
```

### Transport Layer Security

TLS/SSL Socket components:
```
TLS/SSL Socket
├── Certificate-based authentication
├── Encryption in transit
└── Server/Client verification
```

1. **TLS/SSL Configuration**
```go
// Server-side TLS configuration
transport := thrift.NewTSSLServerSocket(
    ":9090",
    &thrift.TSSLServerSocketConfig{
        CertFile: "/path/to/server.crt",
        KeyFile:  "/path/to/server.key",
        ClientCAFile: "/path/to/ca.crt",  // For client certificate validation
        ClientAuth: tls.RequireAndVerifyClientCert,
    },
)

// Client-side TLS configuration
transport := thrift.NewTSSLSocket(
    "localhost",
    9090,
    &thrift.TSSLSocketConfig{
        CertFile: "/path/to/client.crt",
        KeyFile:  "/path/to/client.key",
        CAFile:   "/path/to/ca.crt",
        ServerName: "expected.server.name",
    },
)
```

2. **Certificate Management**
```bash
# Generate self-signed certificates
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365
openssl req -x509 -newkey rsa:4096 -keyout client.key -out client.crt -days 365

# Generate CA for mutual TLS
openssl genrsa -out ca.key 4096
openssl req -new -x509 -key ca.key -out ca.crt -days 365
```

### Protocol Layer Security

Protocol security components:
```
Headers & Metadata
├── Authentication tokens
├── Custom security headers
└── Session management
```

1. **Authentication Headers**
```thrift
struct AuthenticationHeader {
    1: required string token,
    2: optional i64 timestamp,
    3: optional string signature
}

struct SecureRequest {
    1: required AuthenticationHeader auth,
    2: required WeatherRequest request
}
```

2. **Custom Protocol Factory**
```go
type SecureProtocolFactory struct {
    thrift.TProtocolFactory
    authKey string
}

func (f *SecureProtocolFactory) GetProtocol(trans thrift.TTransport) thrift.TProtocol {
    proto := f.TProtocolFactory.GetProtocol(trans)
    return NewSecureProtocol(proto, f.authKey)
}
```

### Application Layer Security

Application security components:
```
Application Security
├── Access control
├── Request validation
└── Custom authentication logic
```

1. **Request Validation**
```go
func (h *WeatherHandler) validateRequest(req *weather.WeatherRequest) error {
    if req.Location == "" {
        return &weather.WeatherServiceError{
            Message:   "Location is required",
            ErrorCode: 400,
        }
    }
    return nil
}
```

2. **Rate Limiting**
```go
type RateLimitedHandler struct {
    handler    weather.WeatherMonitor
    limiter    *rate.Limiter
}

func (h *RateLimitedHandler) GetTemperature(ctx context.Context, req *weather.WeatherRequest) (*weather.WeatherResponse, error) {
    if !h.limiter.Allow() {
        return nil, &weather.WeatherServiceError{
            Message:   "Rate limit exceeded",
            ErrorCode: 429,
        }
    }
    return h.handler.GetTemperature(ctx, req)
}
```

3. **Access Control**
```go
type AuthenticatedHandler struct {
    handler weather.WeatherMonitor
    auth    Authenticator
}

func (h *AuthenticatedHandler) GetTemperature(ctx context.Context, req *weather.WeatherRequest) (*weather.WeatherResponse, error) {
    if !h.auth.IsAuthorized(ctx) {
        return nil, &weather.WeatherServiceError{
            Message:   "Unauthorized",
            ErrorCode: 401,
        }
    }
    return h.handler.GetTemperature(ctx, req)
}
```

### Network Layer Security

1. **Firewall Configuration**
```bash
# Allow Thrift traffic only from trusted IPs
iptables -A INPUT -p tcp --dport 9090 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 9090 -j DROP
```

2. **Network Segmentation**
```yaml
# Docker Compose example with network isolation
version: '3'
services:
  weather_service:
    networks:
      - internal_net
    ports:
      - "9090:9090"
  
networks:
  internal_net:
    internal: true
```

### Security Best Practices

1. **Configuration Management**
```go
type SecurityConfig struct {
    TLSEnabled      bool
    CertFile        string
    KeyFile         string
    ClientCAFile    string
    TokenValidation bool
    RateLimit       int
}

func NewSecureServer(config SecurityConfig) (*thrift.TSimpleServer, error) {
    // Initialize server with security settings
}
```

2. **Logging and Monitoring**
```go
func (h *SecureHandler) GetTemperature(ctx context.Context, req *weather.WeatherRequest) (*weather.WeatherResponse, error) {
    // Audit logging
    audit.Log(ctx, "GetTemperature", map[string]interface{}{
        "user":     ctx.Value("user"),
        "location": req.Location,
        "time":     time.Now(),
    })
    
    // Request tracking
    metrics.IncCounter("weather.requests.total")
    defer metrics.ObserveLatency("weather.requests.duration")
    
    return h.handler.GetTemperature(ctx, req)
}
```

3. **Error Handling**
```thrift
exception SecurityError {
    1: string message,
    2: i32 errorCode,
    3: optional string details
}

service SecureWeatherMonitor {
    WeatherResponse getTemperature(1: WeatherRequest request)
        throws (
            1: WeatherServiceError error,
            2: SecurityError securityError
        )
}
```

### Security Checklist

- [ ] Enable TLS/SSL for all production services
- [ ] Implement authentication and authorization
- [ ] Set up rate limiting
- [ ] Configure network security (firewalls, VPNs)
- [ ] Implement audit logging
- [ ] Set up monitoring and alerting
- [ ] Regular security updates
- [ ] Certificate rotation
- [ ] Input validation
- [ ] Error handling without information leakage

## Best Practices

### Project Structure
```
├── thrift/
│   ├── weather.thrift
│   └── llm.thrift
├── generated/
│   ├── go/
│   ├── nodejs/
│   └── python/
├── go_stream_server/
├── nodejs_stream_client/
└── python_llm_server/
```

### Development Workflow
1. Define Thrift IDL
2. Generate code
3. Implement handlers
4. Write tests
5. Build and deploy

### Common Pitfalls
- Changing field numbers
- Missing required fields
- Incorrect namespace configuration
- Forgetting to regenerate code

## Conclusion

Thrift provides a robust foundation for building distributed systems. Its code generation, type safety, and multi-language support make it an excellent choice for internal service communication. While it has a steeper learning curve than REST, the benefits in terms of performance and maintainability make it worthwhile for many use cases.

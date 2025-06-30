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

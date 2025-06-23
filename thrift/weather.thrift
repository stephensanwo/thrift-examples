namespace go weather
namespace js weather

struct TemperatureReading {
    1: double temperature
    2: string location
    3: i64 timestamp
    4: string unit = "celsius"
}

struct WeatherRequest {
    1: string location
}

exception WeatherServiceError {
    1: string message
    2: string details
}

service WeatherMonitorService {
    TemperatureReading getTemperature(1: WeatherRequest request) throws (1: WeatherServiceError error)
} 
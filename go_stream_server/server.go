package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/apache/thrift/lib/go/thrift"
	"github.com/example/weather-stream-server/weather"
)

type OpenMeteoResponse struct {
	Current struct {
		Temperature float64 `json:"temperature_2m"`
	} `json:"current"`
	Error   bool   `json:"error"`
	Reason  string `json:"reason"`
}

type WeatherMonitorHandler struct{}

func (h *WeatherMonitorHandler) GetTemperature(ctx context.Context, req *weather.WeatherRequest) (*weather.TemperatureReading, error) {
	log.Printf("Getting temperature for location: %s\n", req.Location)
	
	latitude, longitude := getCoordinatesForLocation(req.Location)
	log.Printf("Using coordinates: lat=%.6f, lon=%.6f\n", latitude, longitude)
	
	url := fmt.Sprintf("https://api.open-meteo.com/v1/forecast?latitude=%.6f&longitude=%.6f&current=temperature_2m", 
		latitude, longitude)
	log.Printf("Making request to: %s\n", url)

	resp, err := http.Get(url)
	if err != nil {
		log.Printf("Error fetching weather data: %v\n", err)
		return nil, &weather.WeatherServiceError{
			Message: "Failed to fetch weather data",
			Details: err.Error(),
		}
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Error reading response body: %v\n", err)
		return nil, &weather.WeatherServiceError{
			Message: "Failed to read response",
			Details: err.Error(),
		}
	}
	log.Printf("Raw API response: %s\n", string(body))

	if resp.StatusCode != http.StatusOK {
		log.Printf("API returned non-200 status code: %d\n", resp.StatusCode)
		return nil, &weather.WeatherServiceError{
			Message: "Weather API error",
			Details: fmt.Sprintf("Status code: %d", resp.StatusCode),
		}
	}

	var weatherData OpenMeteoResponse
	if err := json.Unmarshal(body, &weatherData); err != nil {
		log.Printf("Error decoding weather data: %v\n", err)
		return nil, &weather.WeatherServiceError{
			Message: "Failed to decode weather data",
			Details: err.Error(),
		}
	}

	if weatherData.Error {
		log.Printf("API returned error: %s\n", weatherData.Reason)
		return nil, &weather.WeatherServiceError{
			Message: "Weather API error",
			Details: weatherData.Reason,
		}
	}

	log.Printf("Received temperature: %.2f°C\n", 
		weatherData.Current.Temperature)

		reading := &weather.TemperatureReading{
		Temperature: weatherData.Current.Temperature,
		Location:   req.Location,
		Timestamp:  time.Now().Unix(),
		Unit:       "celsius",
	}

	return reading, nil
}

// simplified getCoordinatesForLocation returns latitude and longitude for a given location
func getCoordinatesForLocation(location string) (float64, float64) {
	coordinates := map[string]struct{ lat, lon float64 }{
		"new york":    {40.7128, -74.0060},
		"london":      {51.5074, -0.1278},
		"tokyo":       {35.6762, 139.6503},
		"paris":       {48.8566, 2.3522},
		"sydney":      {-33.8688, 151.2093},
		"san francisco": {37.7749, -122.4194},
	}

	if coord, ok := coordinates[location]; ok {
		return coord.lat, coord.lon
	}
	// Return default coordinates (New York) if location not found
	return 40.7128, -74.0060
}

func main() {
	transportFactory := thrift.NewTFramedTransportFactoryConf(thrift.NewTTransportFactory(), nil)
	protocolFactory := thrift.NewTBinaryProtocolFactoryConf(nil)

	serverTransport, err := thrift.NewTServerSocket(":9091")
	if err != nil {
		log.Fatalf("Failed to create server socket: %v", err)
	}

	handler := &WeatherMonitorHandler{}
	processor := weather.NewWeatherMonitorServiceProcessor(handler)

	server := thrift.NewTSimpleServer4(
		processor,
		serverTransport,
		transportFactory,
		protocolFactory,
	)

	fmt.Println("Starting Weather Monitor Server on :9091...")
	if err := server.Serve(); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
} 
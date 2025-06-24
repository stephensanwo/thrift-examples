package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/apache/thrift/lib/go/thrift"
	utils "github.com/example/weather-stream-server/utils"
	"github.com/example/weather-stream-server/weather"
)

type WeatherMonitorHandler struct{}

func (h *WeatherMonitorHandler) GetTemperature(ctx context.Context, req *weather.WeatherRequest) (*weather.TemperatureReading, error) {
	log.Printf("Getting temperature for location: %s\n", req.Location)
	
	latitude, longitude := utils.GetCoordinatesForLocation(req.Location)
	log.Printf("Using coordinates: lat=%.6f, lon=%.6f\n", latitude, longitude)
	
	weatherData, err := utils.GetWeatherData(latitude, longitude)
	if err != nil {
		return nil, &weather.WeatherServiceError{
			Message: "Failed to get weather data",
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

	log.Printf("Received temperature: %.2f°C\n", weatherData.Current.Temperature)

	reading := &weather.TemperatureReading{
		Temperature: weatherData.Current.Temperature,
		Location:   req.Location,
		Timestamp:  time.Now().Unix(),
		Unit:       "celsius",
	}

	return reading, nil
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
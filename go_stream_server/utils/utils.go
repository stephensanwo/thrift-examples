package utils

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
)

type OpenMeteoResponse struct {
	Current struct {
		Temperature float64 `json:"temperature_2m"`
	} `json:"current"`
	Error   bool   `json:"error"`
	Reason  string `json:"reason"`
}

func GetWeatherData(latitude, longitude float64) (*OpenMeteoResponse, error) {
	url := fmt.Sprintf("https://api.open-meteo.com/v1/forecast?latitude=%.6f&longitude=%.6f&current=temperature_2m", 
		latitude, longitude)
	log.Printf("Making request to: %s\n", url)

	resp, err := http.Get(url)
	if err != nil {
		log.Printf("Error fetching weather data: %v\n", err)
		return nil, fmt.Errorf("failed to fetch weather data: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Error reading response body: %v\n", err)
		return nil, fmt.Errorf("failed to read response: %v", err)
	}
	log.Printf("Raw API response: %s\n", string(body))

	if resp.StatusCode != http.StatusOK {
		log.Printf("API returned non-200 status code: %d\n", resp.StatusCode)
		return nil, fmt.Errorf("weather API error: status code %d", resp.StatusCode)
	}

	var weatherData OpenMeteoResponse
	if err := json.Unmarshal(body, &weatherData); err != nil {
		log.Printf("Error decoding weather data: %v\n", err)
		return nil, fmt.Errorf("failed to decode weather data: %v", err)
	}

	return &weatherData, nil
}

// GetCoordinatesForLocation returns latitude and longitude for a given location
func GetCoordinatesForLocation(location string) (float64, float64) {
	coordinates := map[string]struct{ lat, lon float64 }{
		"new york":      {40.7128, -74.0060},
		"london":        {51.5074, -0.1278},
		"tokyo":         {35.6762, 139.6503},
		"paris":         {48.8566, 2.3522},
		"sydney":        {-33.8688, 151.2093},
		"san francisco": {37.7749, -122.4194},
	}

	if coord, ok := coordinates[location]; ok {
		return coord.lat, coord.lon
	}
	// Return default coordinates (New York) if location not found
	return 40.7128, -74.0060
} 
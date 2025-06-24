package main

import (
	"context"
	"testing"

	"github.com/example/weather-stream-server/weather"
)

func TestGetTemperature(t *testing.T) {
	handler := &WeatherMonitorHandler{}
	
	testCases := []struct {
		name     string
		location string
		wantErr  bool
	}{
		{
			name:     "Valid location - London",
			location: "london",
			wantErr:  false,
		},
		{
			name:     "Valid location - Tokyo",
			location: "tokyo",
			wantErr:  false,
		},
		{
			name:     "Unknown location - defaults to New York",
			location: "unknown_city",
			wantErr:  false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := &weather.WeatherRequest{
				Location: tc.location,
			}

			result, err := handler.GetTemperature(context.Background(), req)
			if tc.wantErr {
				if err == nil {
					t.Errorf("Expected error but got none")
				}
				return
			}

			if err != nil {
				t.Errorf("Unexpected error: %v", err)
				return
			}

			if result == nil {
				t.Error("Expected result but got nil")
				return
			}

			if result.Location != tc.location {
				t.Errorf("Expected location %s but got %s", tc.location, result.Location)
			}

			if result.Unit != "celsius" {
				t.Errorf("Expected unit celsius but got %s", result.Unit)
			}

			if result.Temperature == 0 {
				t.Error("Expected non-zero temperature")
			}
		})
	}
} 
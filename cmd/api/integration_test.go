package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestServerIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	app := newTestApplication(t)

	// Create a test server
	ts := httptest.NewServer(app.routes())
	defer ts.Close()

	// Test health endpoint
	resp, err := http.Get(ts.URL + "/v1/health/")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status OK, got %v", resp.Status)
	}

	// Test general endpoint
	resp, err = http.Get(ts.URL + "/v1/")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status OK, got %v", resp.Status)
	}

	// Test metrics endpoint
	resp, err = http.Get(ts.URL + "/v1/health/metrics")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status OK, got %v", resp.Status)
	}
}

func TestCORSHeaders(t *testing.T) {
	app := newTestApplication(t)

	req, err := http.NewRequest("OPTIONS", "/v1/health/", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Origin", "http://localhost")
	req.Header.Set("Access-Control-Request-Method", "GET")

	rr := httptest.NewRecorder()
	handler := app.routes()
	handler.ServeHTTP(rr, req)

	// Check CORS headers are present
	if rr.Header().Get("Access-Control-Allow-Origin") == "" {
		t.Error("Expected CORS headers to be set")
	}
}

func TestRateLimiting(t *testing.T) {
	app := newTestApplication(t)
	handler := app.routes()

	// Make multiple requests quickly to test rate limiting
	// Note: This is a basic test - adjust based on your rate limit settings
	for i := 0; i < 5; i++ {
		req, err := http.NewRequest("GET", "/v1/health/", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)

		// For the first few requests, we should get 200
		if i < 3 && rr.Code != http.StatusOK {
			t.Errorf("Request %d: expected 200, got %d", i+1, rr.Code)
		}

		// Small delay to avoid hitting rate limits too hard in tests
		time.Sleep(10 * time.Millisecond)
	}
}

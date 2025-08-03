package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"go.uber.org/zap"
)

// newTestApplication returns an application instance configured for testing.
func newTestApplication(t *testing.T) *application {
	logger, _ := zap.NewDevelopment()

	cfg := config{
		port: 4000,
		env:  "test",
		cors: struct {
			trustedOrigins []string
		}{
			trustedOrigins: []string{"http://localhost"},
		},
	}

	return &application{
		config: cfg,
		logger: logger,
	}
}

func TestHealthCheckHandler(t *testing.T) {
	app := newTestApplication(t)

	// Create a request to pass to our handler
	req, err := http.NewRequest("GET", "/v1/health", nil)
	if err != nil {
		t.Fatal(err)
	}

	// Create a ResponseRecorder to record the response
	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(app.healthCheckHandler)

	// Call the handler with our request and recorder
	handler.ServeHTTP(rr, req)

	// Check the status code
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Check the response body contains "healthy"
	expected := "{\n\t\"status\": \"healthy\"\n}\n"
	if rr.Body.String() != expected {
		t.Errorf("handler returned unexpected body: got %v want %v",
			rr.Body.String(), expected)
	}
}

func TestGeneralHandler(t *testing.T) {
	app := newTestApplication(t)

	req, err := http.NewRequest("GET", "/v1", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(app.generalHandler)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	expected := "{\n\t\"status\": \"welcome to inko_moko\"\n}\n"
	if rr.Body.String() != expected {
		t.Errorf("handler returned unexpected body: got %v want %v",
			rr.Body.String(), expected)
	}
}

func TestRoutes(t *testing.T) {
	app := newTestApplication(t)

	// Test that routes are properly set up
	handler := app.routes()
	if handler == nil {
		t.Error("routes() returned nil handler")
	}

	// Test health endpoint through full router
	req, err := http.NewRequest("GET", "/v1/health/", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("health route returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Test general endpoint through full router
	req, err = http.NewRequest("GET", "/v1/", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr = httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("general route returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}
}

func TestMetricsEndpoint(t *testing.T) {
	app := newTestApplication(t)

	req, err := http.NewRequest("GET", "/v1/health/metrics", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := app.routes()
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("metrics endpoint returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Check that response contains prometheus metrics format
	body := rr.Body.String()
	if len(body) == 0 {
		t.Error("metrics endpoint returned empty body")
	}

	// Basic check for prometheus format (should contain "# HELP" or "# TYPE")
	if !contains(body, "# HELP") && !contains(body, "# TYPE") {
		t.Error("metrics endpoint doesn't appear to return prometheus format")
	}
}

// Helper function to check if string contains substring
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(substr) == 0 ||
		(len(s) > len(substr) && (s[:len(substr)] == substr || s[len(s)-len(substr):] == substr ||
			containsHelper(s, substr))))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

package main

import (
	"net/http"

	"github.com/go-chi/chi"
	"github.com/go-chi/cors"
	"github.com/justinas/alice"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// routes sets up the main router for the application, including middleware and route groups.
func (app *application) routes() http.Handler {
	router := chi.NewRouter()
	router.Use(cors.Handler(cors.Options{
		AllowedOrigins:   app.config.cors.trustedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "PATCH"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"link"},
		AllowCredentials: false,
		MaxAge:           300, // Maximum value not ignored by any of major browsers
	})) // Make our categorized routes
	//Use alice to make a global middleware chain.
	globalMiddleware := alice.New(app.recoverPanic, app.rateLimit).Then

	// Apply the global middleware to the router
	router.Use(globalMiddleware)

	v1Router := chi.NewRouter()

	v1Router.Mount("/", app.generalRoutes())
	v1Router.Mount("/health", app.healthRoutes())
	// this are hybrid routes

	// Mount the v1Router to the main base router
	router.Mount("/v1", v1Router)
	return router
}

// generalRoutes returns a router for general endpoints.
func (app *application) generalRoutes() http.Handler {
	router := chi.NewRouter()

	// Define your general routes here
	router.Get("/", app.generalHandler)

	return router
}

// healthRoutes returns a router for health check and metrics endpoints.
func (app *application) healthRoutes() http.Handler {
	router := chi.NewRouter()

	// Define your health check routes here
	router.Get("/", app.healthCheckHandler)       // This makes /v1/health/ the health check
	router.Handle("/metrics", promhttp.Handler()) // This makes /v1/health/metrics the metrics

	return router
}

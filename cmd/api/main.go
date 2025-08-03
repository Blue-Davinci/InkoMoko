package main

import (
	"flag"
	"fmt"
	"strings"

	"github.com/Blue-Davinci/inko_moko/internal/logger"
	"go.uber.org/zap"
)

var (
	version = "1.0.0" // Version of the application, set at build time
)

// config holds the configuration for the application.
type config struct {
	port int
	env  string
	api  struct {
		name   string
		author string
	}
	cors struct {
		trustedOrigins []string
	}
	limiter struct {
		rps     float64
		burst   int
		enabled bool
	}
}

// application holds the dependencies for the HTTP handlers.
type application struct {
	config config
	logger *zap.Logger
}

func main() {
	// config
	var cfg config
	logger, err := logger.InitJSONLogger()
	if err != nil {
		fmt.Printf("Error initializing logger: %s. Version:  %s", err, version)
		return
	}
	// Port & env
	flag.IntVar(&cfg.port, "port", 4000, "API server port")
	flag.StringVar(&cfg.env, "env", "development", "Environment (development|staging|production)")
	// api configuration
	flag.StringVar(&cfg.api.name, "api-name", "SavannaCart", "API Name")
	flag.StringVar(&cfg.api.author, "api-author", "Blue-Davinci", "API Author")
	// CORS configuration
	flag.Func("cors-trusted-origins", "Trusted CORS origins (space separated)", func(val string) error {
		cfg.cors.trustedOrigins = strings.Fields(val)
		return nil

	})
	// Rate limiter flags
	flag.Float64Var(&cfg.limiter.rps, "limiter-rps", 5, "Rate limiter maximum requests per second")
	flag.IntVar(&cfg.limiter.burst, "limiter-burst", 10, "Rate limiter maximum burst")
	flag.BoolVar(&cfg.limiter.enabled, "limiter-enabled", true, "Enable rate limiter")

	// Parse the flags
	flag.Parse()

	// initialize our app
	app := &application{
		config: cfg,
		logger: logger,
	}
	// Initialize the server
	logger.Info("Loaded Cors Origins", zap.Strings("origins", cfg.cors.trustedOrigins))
	err = app.server()
	if err != nil {
		logger.Fatal("Error while starting server.", zap.String("error", err.Error()))
	}
}

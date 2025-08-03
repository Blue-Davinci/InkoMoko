package main

import "go.uber.org/zap"

var (
	version = "1.0.0" // Version of the application, set at build time
)

type config struct {
	port int
	env  string
	api  struct {
		name   string
		author string
	}
}

type application struct {
	config config
	logger *zap.Logger
}

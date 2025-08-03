package main

import (
	"net/http"

	"go.uber.org/zap"
)

func (app *application) generalHandler(w http.ResponseWriter, r *http.Request) {
	err := app.writeJSON(w, http.StatusOK, envelope{"status": "welcome to inko_moko"}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
	// logger
	app.logger.Info("Handled general request", zap.String("method", r.Method), zap.String("path", r.URL.Path))
}

func (app *application) healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	err := app.writeJSON(w, http.StatusOK, envelope{"status": "healthy"}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
	// logger
	app.logger.Info("Handled health check request", zap.String("method", r.Method), zap.String("path", r.URL.Path))
}

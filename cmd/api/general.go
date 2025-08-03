package main

import (
	"net/http"
)

func (app *application) generalHandler(w http.ResponseWriter, r *http.Request) {
	err := app.writeJSON(w, http.StatusOK, envelope{"status": "welcome to inko_moko"}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

func (app *application) healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	err := app.writeJSON(w, http.StatusOK, envelope{"status": "healthy"}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

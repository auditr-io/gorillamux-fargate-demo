package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/auditr-io/auditr-agent-go/wrappers/auditrgorilla"
	"github.com/gorilla/mux"
)

// a sample implementation with gorilla/mux
func main() {
	a, err := auditrgorilla.NewAgent()
	if err != nil {
		log.Fatal(err)
	}

	router := mux.NewRouter()
	router.Use(a.Middleware)
	router.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	router.HandleFunc("/hi/{name}", func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)

		w.Header().Add("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(fmt.Sprintf(`{
			"hi": "%s"
		}`, vars["name"])))
	})

	srv := &http.Server{
		Handler:      router,
		Addr:         ":8000",
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}

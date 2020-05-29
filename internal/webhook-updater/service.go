package webhook_updater

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

type Service struct {
	Port               int
	CertUpdaterHandler func(*CertUpdater) error

	server *http.Server
}

func (s *Service) Listen() error {
	http.HandleFunc("/", s.handleRequest)
	s.server = &http.Server{Addr: fmt.Sprintf(":%d", s.Port)}

	err := s.server.ListenAndServe()
	if err != nil && err != http.ErrServerClosed {
		return err
	}
	return nil
}

func (s *Service) Close() error {
	return s.server.Close()
}

type statusResponse struct {
	Status int    `json:"status"`
	Error  string `json:"error,omitempty"`
}

func (s *Service) handleRequest(writer http.ResponseWriter, request *http.Request) {
	if request.Method != "POST" {
		writer.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	response := statusResponse{Status: http.StatusOK}
	err := s.handlePostRequest(request.Body)
	if err != nil {
		response.Status = http.StatusBadRequest
		response.Error = err.Error()
		Log.Infof("Bad request: %s", err)
	}

	writer.WriteHeader(response.Status)
	encoder := json.NewEncoder(writer)
	err = encoder.Encode(response)
	if err != nil {
		Log.Errorf("Error encoding response: %s", err)
	}
}

func (s *Service) handlePostRequest(body io.Reader) error {
	decoder := json.NewDecoder(body)
	decoder.DisallowUnknownFields()
	certUpdater := &CertUpdater{}
	err := decoder.Decode(&certUpdater)
	if err != nil {
		return err
	}
	return s.CertUpdaterHandler(certUpdater)
}

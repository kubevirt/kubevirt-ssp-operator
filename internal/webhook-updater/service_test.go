package webhook_updater

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Test service", func() {
	var (
		service *Service
	)

	BeforeEach(func() {
		service = &Service{
			CertUpdaterHandler: func(*CertUpdater) error { return nil },
		}
	})

	It("should fail not POST methods", func() {
		Expect(getResponse("GET", "", service).Code).To(Equal(http.StatusMethodNotAllowed))
		Expect(getResponse("PUT", "", service).Code).To(Equal(http.StatusMethodNotAllowed))
	})

	It("should fail on incorrect request", func() {
		badRequest := "1234__not_a_json_1234"
		response := getResponse("POST", badRequest, service)
		Expect(response.Code).To(Equal(http.StatusBadRequest))
	})

	It("should fail on unknown JSON fields", func() {
		body := `{"key":"val"}`
		response := getResponse("POST", body, service)
		Expect(response.Code).To(Equal(http.StatusBadRequest))
	})

	It("should fail on handler failure", func() {
		validationError := errors.New("validation failed")
		service.CertUpdaterHandler = func(*CertUpdater) error {
			return validationError
		}

		body := `{"webhook":"test","ca_dir":"test-dir","ca_file":"test-file"}`
		response := getResponse("POST", body, service)
		Expect(response.Code).To(Equal(http.StatusBadRequest))

		var status statusResponse
		Expect(json.NewDecoder(response.Body).Decode(&status)).ToNot(HaveOccurred())
		Expect(status.Status).To(Equal(http.StatusBadRequest))
		Expect(status.Error).To(Equal(validationError.Error()))
	})

})

func TestService(t *testing.T) {
	log.SetOutput(ioutil.Discard)
	RegisterFailHandler(Fail)
	RunSpecs(t, "Service Suite")
}

func getResponse(method string, body string, service *Service) *httptest.ResponseRecorder {
	request, err := http.NewRequest(method, "/", strings.NewReader(body))
	Expect(err).ToNot(HaveOccurred())

	response := httptest.NewRecorder()
	handler := http.HandlerFunc(service.handleRequest)
	handler.ServeHTTP(response, request)
	return response
}

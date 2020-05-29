package webhook_updater

import (
	"encoding/base64"
	"errors"
	"fmt"
	"k8s.io/client-go/rest"
	"net/http"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

type ClientProxy interface {
	CheckWebhookExists(name string) error
	PatchWebhookCaBundle(name string, caBundle []byte) error
}

var WebhookNotFoundError = errors.New("webhook not found")

func NewClientProxy(kubeconfig string) (ClientProxy, error) {
	clientProxy := &clientProxy{kubeconfig: kubeconfig}

	// Validate that it is possible to create the kubernetes client
	_, err := clientProxy.createK8sClient()
	if err != nil {
		return nil, err
	}
	return clientProxy, nil
}

type clientProxy struct {
	kubeconfig string
}

func (c *clientProxy) CheckWebhookExists(name string) error {
	client, err := c.createK8sClient()
	if err != nil {
		return err
	}
	_, err = client.AdmissionregistrationV1beta1().
		ValidatingWebhookConfigurations().
		Get(name, metav1.GetOptions{})
	return err
}

func (c *clientProxy) PatchWebhookCaBundle(name string, caBundle []byte) error {
	client, err := c.createK8sClient()
	if err != nil {
		return err
	}

	caBundleEncoded := base64.StdEncoding.EncodeToString(caBundle)

	patch := fmt.Sprintf(`[{"op":"replace", "path":"/webhooks/0/clientConfig/caBundle", "value":"%s"}]`, caBundleEncoded)
	_, err = client.AdmissionregistrationV1beta1().
		ValidatingWebhookConfigurations().
		Patch(name, types.JSONPatchType, []byte(patch))

	if err != nil {
		if err.(*apierrors.StatusError).ErrStatus.Code == http.StatusNotFound {
			return WebhookNotFoundError
		}
		return err
	}
	return nil
}

// This method is used to recreate the client every time it is needed.
// It creates some overhead, but the client is not used often, so performance
// penalty is not an issue. This way the client always has the current
// token and CA.
func (c *clientProxy) createK8sClient() (kubernetes.Interface, error) {
	var config *rest.Config
	var err error
	if c.kubeconfig == "" {
		config, err = rest.InClusterConfig()
	} else {
		config, err = clientcmd.BuildConfigFromFlags("", c.kubeconfig)
	}
	if err != nil {
		return nil, err
	}
	return kubernetes.NewForConfig(config)
}

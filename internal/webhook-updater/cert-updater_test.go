package webhook_updater

import (
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"testing"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

const (
	webhookName = "test-webhook"
	caFileName  = "test.crt"
)

var _ = Describe("Test file processing", func() {
	var (
		tempDir     string
		updater     *CertUpdater
		clientProxy *clientProxy_mock
	)

	BeforeEach(func() {
		var err error
		tempDir, err = ioutil.TempDir("", "cert-dir")
		Expect(err).ToNot(HaveOccurred())

		updater = &CertUpdater{
			Webhook: webhookName,
			CaFile:  caFileName,
			CaDir:   tempDir,
		}
		clientProxy = &clientProxy_mock{}
	})

	AfterEach(func() {
		os.RemoveAll(tempDir)
	})

	It("should not patch if no file exists", func() {
		Expect(updater.Start(clientProxy)).To(Succeed())
		defer updater.Stop()
		consistentlyPatchCount(clientProxy, 0)
	})

	It("should patch CaBundle on start", func() {
		writeCertificate(tempDir, certPemData1)
		Expect(updater.Start(clientProxy)).To(Succeed())
		defer updater.Stop()
		eventuallyPatchCount(clientProxy, 1)
	})

	It("should patch CaBundle on file change", func() {
		writeCertificate(tempDir, certPemData1)

		Expect(updater.Start(clientProxy)).To(Succeed())
		defer updater.Stop()
		eventuallyPatchCount(clientProxy, 1)

		writeCertificate(tempDir, certPemData2)
		eventuallyPatchCount(clientProxy, 2)
	})

	It("should patch only once, if file is equal after change", func() {
		writeCertificate(tempDir, certPemData1)

		Expect(updater.Start(clientProxy)).To(Succeed())
		defer updater.Stop()
		eventuallyPatchCount(clientProxy, 1)

		writeCertificate(tempDir, certPemData1)
		consistentlyPatchCount(clientProxy, 1)
	})

	It("should not patch when cert is invalid", func() {
		writeCertificate(tempDir, certPemData1)

		Expect(updater.Start(clientProxy)).To(Succeed())
		defer updater.Stop()
		eventuallyPatchCount(clientProxy, 1)

		writeCertificate(tempDir, certPemDataInvalid)
		consistentlyPatchCount(clientProxy, 1)
	})

	It("should stop if webhook is removed", func() {
		writeCertificate(tempDir, certPemData1)

		Expect(updater.Start(clientProxy)).To(Succeed())
		defer updater.Stop()
		eventuallyPatchCount(clientProxy, 1)

		clientProxy.webhookDoesNotExist = true
		writeCertificate(tempDir, certPemData2)
		Eventually(updater.IsRunning, time.Second).Should(BeFalse())
	})
})

func TestCertUpdater(t *testing.T) {
	log.SetOutput(ioutil.Discard)
	RegisterFailHandler(Fail)
	RunSpecs(t, "CertUpdater Suite")
}

func writeCertificate(dir string, data string) {
	Expect(ioutil.WriteFile(filepath.Join(dir, caFileName), []byte(data), 0777)).To(Succeed())
}

func eventuallyPatchCount(proxy *clientProxy_mock, count int) {
	Eventually(func() int {
		return proxy.patchCount
	}, time.Second).Should(Equal(count))
}

func consistentlyPatchCount(proxy *clientProxy_mock, count int) {
	Consistently(func() int {
		return proxy.patchCount
	}, time.Second).Should(Equal(count))
}

type clientProxy_mock struct {
	patchCount          int
	webhookDoesNotExist bool
}

func (c *clientProxy_mock) CheckWebhookExists(name string) error {
	if name != webhookName {
		return WebhookNotFoundError
	}
	return nil
}

func (c *clientProxy_mock) PatchWebhookCaBundle(name string, caBundle []byte) error {
	if c.webhookDoesNotExist {
		return WebhookNotFoundError
	}
	c.patchCount += 1
	return nil
}

const certPemData1 = `-----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUZrjqifnU/JrbrjMvmOu1KKqAf5swDQYJKoZIhvcNAQEL
BQAwQjELMAkGA1UEBhMCWFgxFTATBgNVBAcMDERlZmF1bHQgQ2l0eTEcMBoGA1UE
CgwTRGVmYXVsdCBDb21wYW55IEx0ZDAgFw0yMDA1MTQxMTM4MjJaGA8yMTIwMDQy
MDExMzgyMlowQjELMAkGA1UEBhMCWFgxFTATBgNVBAcMDERlZmF1bHQgQ2l0eTEc
MBoGA1UECgwTRGVmYXVsdCBDb21wYW55IEx0ZDCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAMvehkrnrXKkiaGuHIoPtgv71Ed6PojvtGU9686d3jaVm31c
tjhABDh4L5/sE6VPYHkPY7RSyPVt9sdYu7ZlMpxPMYegRmN2B4SParZKO710rV5W
yRZ70LjvkVgxFsCWOOD1TMPMRMbQXeS3lmf/3DazJ+2ASyxNRR4JzYt9S8++inOk
ohUsZoqA2n1n8n2HEWKja/YUSIWHDxVycxl4v7MoNUoz62l35BLIfI+poqWoqnWd
heB7mgOnSzNA3c9P0cjFwztEOEANLll4Ln7GrWz2Je7SmkL0TsiGUZPsxmJeGjMI
6BlZkUdL4QO3KTioMLPMWegPzkZfsv2fE+r+CgECAwEAAaNTMFEwHQYDVR0OBBYE
FJR4IHKeBY3vAapvb2bsTJAYIq0FMB8GA1UdIwQYMBaAFJR4IHKeBY3vAapvb2bs
TJAYIq0FMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAC7AHUSt
Csvt4usQ2421hBkJ4zkHlx1GTerm/5sZHrV/BJn8eedyRCvfWMdi51s/z4WE8Vtn
crs1f5mlmhmKGWcAj9BJ3KURo9GMpkkvwVJGB3QQnZEtEfVHszL717XuoN4O8oeU
VdmsBe8BZrE3lRY7alNdkFdAcMt7mkm/DA6YlA9nLBGr0A/CTDxszCJKU6x5NWLH
X4UcUn4Wa6xeY9GtFpiW/bT4o3N8C17LMP3FXpB6vZtgOzHKBKIb1nTWYmFlHMh6
Czu4uzXNOLOztQXJUXfYojfT++75icmU4baSD5t+wPZz4KlT6ZjKuN4vlek4Enzk
u/jLMJFKSO1HwEw=
-----END CERTIFICATE-----

`

const certPemData2 = `-----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUXEJNbMpSy7Bf1Or0QR/1oE3oamgwDQYJKoZIhvcNAQEL
BQAwQjELMAkGA1UEBhMCWFgxFTATBgNVBAcMDERlZmF1bHQgQ2l0eTEcMBoGA1UE
CgwTRGVmYXVsdCBDb21wYW55IEx0ZDAgFw0yMDA1MTQxMTM4NDJaGA8yMTIwMDQy
MDExMzg0MlowQjELMAkGA1UEBhMCWFgxFTATBgNVBAcMDERlZmF1bHQgQ2l0eTEc
MBoGA1UECgwTRGVmYXVsdCBDb21wYW55IEx0ZDCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAMl5b/CGXPGRNoA/FiVD86lXGQhhrSVGRuaDEyalGT8oYQWu
28IXgA0UEjdEnxR1DJG/dd2oyflDzgQnSKB8axtJCz1lDVIHv5kuPuUUr6oEt7iJ
TKPYn3DgHuWmisyG0HF22URuJbTlqADkj8ZxWTBDYIK0Gimd4cI9JctL9INLOtFt
L+aTvhek9Uc4D2brdsfDvG9fETRBUys0WghZMvZPFZlfiPpmtrkxqP/8AEv7YNwi
FcMZ6ax7KgPDtb41DD4aYkXzLMDlCB91DHIrfVUrWM9lkSOi353YEUq3uQ3nHiiA
iiB/Wmb007BpZHnBErc/dWGuyewPyXn8rCniqoMCAwEAAaNTMFEwHQYDVR0OBBYE
FBAtDdCPe2VEyTJvHuj11cTmTVwfMB8GA1UdIwQYMBaAFBAtDdCPe2VEyTJvHuj1
1cTmTVwfMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAI3pI9oa
lXTeqbsuvvVZvbdZzOXQneCuSmjiMdIQex3sMdEQFSAIkccsn3uI/xHvhcPf2Osh
+g8/eVWpUiGEB9t1y1UxJqUCQlzR9RayaDiT7ZIe6Wlir/agFLzxSZTWf66Gn1XB
jyC/d88m7YqtqJOh3CRJTLvBkEgJFKgKF8clwgF+4AHLKFIAQySq9V1rWl157+o1
lSgtqTVoU06GLGTisRftGdce63ph4Yqd47D6ZtptLv9jmztLJRsBxv/KayL7S0rK
F839DkwtOGmdfzsoiGwP+sc8bAZcWNY6BPfGIhnSJnHmWCOZSGhYvoMcrj6vCLjh
PlqlMWet5NrRvAg=
-----END CERTIFICATE-----
`

const certPemDataInvalid = `-----BEGIN CERTIFICATE-----
elozcElQbENLNnNIMEFGNTBjaEQ0dHdyL1AyQXlsVWM0bUV3V1NKN0lxOEFaNnN6
ai9BZDh5WHZzbXppY2ZKQXdxbE94eVlnRHlHUAo=
-----END CERTIFICATE-----
`

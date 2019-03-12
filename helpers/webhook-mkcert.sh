#!/bin/bash
# source: https://github.com/istio/istio/blob/release-0.7/install/kubernetes/webhook-create-signed-cert.sh

set -e

usage() {
    cat <<EOF
Generate certificate suitable for use with a webhook service.

This script uses k8s' CertificateSigningRequest API to a generate a
certificate signed by k8s CA suitable for use with Istio webhook
services. This requires permissions to create and approve CSR. See
https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster for
detailed explantion and additional instructions.

The server key/cert k8s CA cert are stored in a k8s secret.

usage: ${0} [OPTIONS]

The following flags are required.

       --service          Service name of webhook.
       --namespace        Namespace where webhook service and secret reside.
       --secret           Secret name for CA certificate and server certificate/key pair.
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case ${1} in
        --service)
            service="$2"
            shift
            ;;
        --secret)
            secret="$2"
            shift
            ;;
        --namespace)
            namespace="$2"
            shift
            ;;
        *)
            usage
            ;;
    esac
    shift
done

[ -z ${namespace} ] && namespace=kubevirt
[ -z ${service} ] && service=virtualmachine-template-validator
[ -z ${secret} ] && secret=virtualmachine-template-validator-certs

if [ ! -x "$(command -v openssl)" ]; then
    echo "openssl not found"
    exit 1
fi

csrName=${service}.${namespace}
tmpdir=$(mktemp -d)

cat <<EOF >> ${tmpdir}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${service}
DNS.2 = ${service}.${namespace}
DNS.3 = ${service}.${namespace}.svc
EOF

openssl genrsa -out ${tmpdir}/server-key.pem 2048
openssl req -new -key ${tmpdir}/server-key.pem -subj "/CN=${service}.${namespace}.svc" -out ${tmpdir}/server.csr -config ${tmpdir}/csr.conf

base64 -w 0 < ${tmpdir}/server-key.pem > ${tmpdir}/server-key.pem.b64

# create  server cert/key CSR and  send to k8s API
cat <<EOF> ${tmpdir}/webhook-csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${csrName}
spec:
  groups:
  - system:authenticated
  request: $(cat ${tmpdir}/server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

echo -e "{"
echo -e "\t\"serverkey\": \"${tmpdir}/server-key.pem\","
echo -e "\t\"serverkeyb64\": \"${tmpdir}/server-key.pem.b64\","
echo -e "\t\"servercsr\": \"${tmpdir}/server.csr\","
echo -e "\t\"webhookcsr\": \"${tmpdir}/webhook-csr.yaml\"",
echo -e "\t\"csrname\": \"${csrName}\"",
echo -e "\t\"secret\": \"${secret}\"",
echo -e "\t\"basedir\": \"${tmpdir}\""
echo -e "}"

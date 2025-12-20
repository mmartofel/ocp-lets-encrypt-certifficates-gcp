#!/bin/bash

# Specify the directory where the certifficates are stored
export CERTDIR=certificates

# Set the API domain name
export LE_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')

echo
echo "Creating TLS secret 'api-certs' in 'openshift-config' namespace..."
echo

oc create secret tls api-certs \
  --cert=${CERTDIR}/fullchain.pem \
  --key=${CERTDIR}/key.pem \
  -n openshift-config

echo
echo "Patching API server to use the new TLS secret 'api-certs'..."
echo

oc patch apiserver cluster \
  --type=merge \
  --patch="{\"spec\": {\"servingCerts\": {\"namedCertificates\": [ { \"names\": [  \"$LE_API\"  ], \"servingCertificate\": {\"name\": \"api-certs\" }}]}}}"

# Wait for API server pods to be restarted and ready
echo "Waiting for API server pods to be restarted and ready..."
echo
API_PODS=$(oc get pods -n openshift-apiserver -l app=apiserver -o jsonpath='{.items[*].metadata.name}')
for POD in $API_PODS; do
  echo "Waiting for pod $POD to be restarted and ready..."
  oc wait --for=condition=Ready pod/$POD -n openshift-apiserver --timeout=300s
done

echo
echo "All API server pods are restarted and ready."
echo

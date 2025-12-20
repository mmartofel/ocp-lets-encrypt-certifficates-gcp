#!/bin/bash

# Specify the directory where the certifficates are stored
export CERTDIR=certificates

echo
echo "Creating TLS secret 'router-certs' in 'openshift-ingress' namespace..."
echo

oc create secret tls router-certs \
  --cert=${CERTDIR}/fullchain.pem \
  --key=${CERTDIR}/key.pem \
  -n openshift-ingress

echo
echo "Patching default ingresscontroller to use the new TLS secret 'router-certs'..."
echo

oc patch ingresscontroller default \
  -n openshift-ingress-operator \
  --type=merge \
  --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'

echo
echo "Waiting for ingresscontroller pods to be restarted and ready..."
INGRESS_PODS=$(oc get pods -n openshift-ingress -l app=router -o jsonpath='{.items[*].metadata.name}')
for POD in $INGRESS_PODS; do
  echo "Waiting for pod $POD to be restarted and ready..."
  oc wait --for=condition=Ready pod/$POD -n openshift-ingress --timeout=300s
done

echo
echo "All ingresscontroller pods are restarted and ready."
echo

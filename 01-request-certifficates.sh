#!/usr/bin/env bash
set -euo pipefail

##############################################
# CONFIGURATION
##############################################
CERTDIR="certificates"
ACME_HOME="acme.sh"

# GCP DNS configuration
export GCP_PROJECT="${GCP_PROJECT_ID:-my-gcp-project-id}"
export GCP_SERVICE_ACCOUNT_FILE="${GCP_SERVICE_ACCOUNT_FILE:-./gcp_service_account.json}"

##############################################
# CLEANUP
##############################################
echo "🧹 Cleaning up previous certificates and acme.sh data..."
rm -rf "${CERTDIR}"
rm -rf "${HOME}/.acme.sh"

##############################################
# CHECK OPENSHIFT LOGIN
##############################################
if ! oc whoami >/dev/null 2>&1; then
  echo
  echo "❌ You are not logged in to OpenShift CLI."
  echo "Please run 'oc login' and try again."
  echo
  exit 1
fi

echo
echo "✅ Logged in to OpenShift as: $(oc whoami)"
echo

##############################################
# DETECT DOMAINS
##############################################
LE_API=$(oc whoami --show-server \
  | awk -F[/:] '{print $4}' \
  | sed 's/^api\.//')

LE_WILDCARD=$(oc get ingresscontroller default \
  -n openshift-ingress-operator \
  -o jsonpath='{.status.domain}')

echo "🌐 Domain names for the certificates:"
echo "  API:        ${LE_API}"
echo "  Wildcard:   *.${LE_WILDCARD}"
echo

##############################################
# CHECK GCP CONFIG
##############################################
if [[ ! -f "$GCP_SERVICE_ACCOUNT_FILE" ]]; then
  echo "❌ GCP service account file not found:"
  echo "   $GCP_SERVICE_ACCOUNT_FILE"
  exit 1
fi

if [[ -z "$GCP_PROJECT" ]]; then
  echo "❌ GCP_PROJECT is not set."
  exit 1
fi

##############################################
# EMAIL PROMPT
##############################################
read -rp "📧 Enter email address for Let's Encrypt notifications: " EMAIL
echo

##############################################
# INSTALL ACME.SH (LOCAL)
##############################################
if [[ ! -x "./acme.sh/acme.sh" ]]; then
  echo "📦 Installing acme.sh locally..."
  curl -s https://get.acme.sh | sh -s email="$EMAIL"
fi

##############################################
# REGISTER ACCOUNT (ZeroSSL)
##############################################
echo "🔐 Registering ACME account with ZeroSSL..."
"${ACME_HOME}/acme.sh" --register-account -m "$EMAIL" --server zerossl
"${ACME_HOME}/acme.sh" --set-default-ca --server zerossl

##############################################
# ISSUE CERTIFICATES (DNS-01 via GCP)
##############################################
echo "🚀 Issuing certificates using Google Cloud DNS..."
"${ACME_HOME}/acme.sh" --log --issue \
  -d "${LE_API}" \
  -d "*.${LE_WILDCARD}" \
  --dns dns_gcloud

##############################################
# INSTALL CERTIFICATES
##############################################
mkdir -p "${CERTDIR}"

"${ACME_HOME}/acme.sh" --install-cert \
  -d "${LE_API}" \
  -d "*.${LE_WILDCARD}" \
  --cert-file "${CERTDIR}/cert.pem" \
  --key-file "${CERTDIR}/key.pem" \
  --fullchain-file "${CERTDIR}/fullchain.pem" \
  --ca-file "${CERTDIR}/ca.cer"

echo
echo "✅ Certificates successfully issued and installed in:"
echo "   ${CERTDIR}"
echo

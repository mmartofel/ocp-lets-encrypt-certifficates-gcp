#!/usr/bin/env bash
set -euo pipefail

##############################################
# CONFIGURATION
##############################################
export CERTDIR="certificates"
export ACME_HOME="${HOME}/.acme.sh"
export ACME_SH=./acme.sh/acme.sh

# GCP DNS configuration
export GCP_PROJECT="${GCP_PROJECT_ID:-my-gcp-project-id}"
export GCP_SERVICE_ACCOUNT_FILE="${GCP_SERVICE_ACCOUNT_FILE:-./gcp_service_account.json}"
export GOOGLE_APPLICATION_CREDENTIALS="${GCP_SERVICE_ACCOUNT_FILE:-./gcp_service_account.json}"

##############################################
# CLEANUP
##############################################
echo "🧹 Cleaning up previous certificates and acme.sh data..."
rm -rf "${CERTDIR}"
rm -rf "${ACME_HOME}"
mkdir -p "${ACME_HOME}" "${CERTDIR}"

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
# INSTALL ACME.SH
##############################################
if [[ ! -x "$ACME_SH" ]]; then
  echo "📦 Installing acme.sh..."
  curl -s https://get.acme.sh | sh -s email="$EMAIL" --home "$ACME_HOME"
fi

##############################################
# REGISTER ACCOUNT (Let's Encrypt)
##############################################
echo "🔐 Registering ACME account with Let's Encrypt..."
"${ACME_SH}" --set-default-ca --server letsencrypt
"${ACME_SH}" --register-account -m "$EMAIL" --server letsencrypt

##############################################
# ISSUE CERTIFICATES (GCP)
##############################################
echo "🚀 Issuing certificates using Google Cloud DNS..."
"${ACME_SH}" --log --issue \
  -d "${LE_API}" \
  -d "*.${LE_WILDCARD}" \
  --dns dns_gcloud

##############################################
# INSTALL CERTIFICATES
##############################################
mkdir -p "${CERTDIR}"

"${ACME_SH}" --install-cert \
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

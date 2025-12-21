
DEFAULT_GCP_SA_FILE="gcp_service_account.json"
DEFAULT_GCP_PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)

# Clone or update acme.sh
echo
echo "Cloning or updating acme.sh..."
echo

if [ -d "acme.sh" ]; then
    echo "acme.sh already exists — updating..."
    (cd acme.sh && git pull --ff-only) || true
else
    git clone https://github.com/neilpang/acme.sh
fi

# Set GCP credentials, set GCP service account file
echo
echo "Please provide your GCP credentials."
echo     "These will be used by acme.sh to complete the DNS challenge."
echo

printf "GCP Service Account File [%s]: " "$DEFAULT_GCP_SA_FILE"
read -r GCP_SERVICE_ACCOUNT_FILE

# Set GCP credentials, set GCP project ID
if [[ -z "$DEFAULT_GCP_PROJECT_ID" ]]; then
  printf "Please provide GCP project ID: "
else
  printf "Please provide GCP project ID [%s]: " "$DEFAULT_GCP_PROJECT_ID"
fi

read -r GCP_PROJECT_ID
GCP_PROJECT_ID="${GCP_PROJECT_ID:-$DEFAULT_GCP_PROJECT_ID}"

if [[ -z "$GCP_PROJECT_ID" ]]; then
  echo "❌ GCP project ID is required."
  exit 1
fi

# Export so that acme.sh can use them
export GCP_SERVICE_ACCOUNT_FILE="${GCP_SERVICE_ACCOUNT_FILE:-$DEFAULT_GCP_SA_FILE}"
export GCP_PROJECT_ID="$GCP_PROJECT_ID"
export GOOGLE_APPLICATION_CREDENTIALS="$GCP_SERVICE_ACCOUNT_FILE:-${DEFAULT_GCP_SA_FILE}"

echo
echo "You have provided the following GCP credentials:"
echo "GCP_SERVICE_ACCOUNT_FILE=$GCP_SERVICE_ACCOUNT_FILE"
echo "GCP_PROJECT_ID=$GCP_PROJECT_ID"
echo
echo "GCP credentials set."
echo

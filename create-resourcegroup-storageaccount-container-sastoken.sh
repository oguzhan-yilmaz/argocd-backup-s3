#!/bin/bash
#
# This script creates the required Azure infrastructure (Resource Group,
# Storage Account, Container) for ArgoCD backups and generates a
# SAS Token with the correct permissions for 'azcopy'.
#

set -e
set -o pipefail

# --- CONFIGURABLE VARIABLES ---
MY_RESOURCE_GROUP="argocd-backup-rg"
MY_LOCATION="westeurope"
MY_STORAGE_ACCOUNT_PREFIX="argocdbck"
MY_CONTAINER_NAME="argocd-backups"
# -----------------------------------

MY_STORAGE_ACCOUNT="${MY_STORAGE_ACCOUNT_PREFIX}$(openssl rand -hex 4)"

echo "Azure Infrastructure Setup Script Initialized."
echo "Using the following values:"
echo "  Resource Group  : $MY_RESOURCE_GROUP"
echo "  Location        : $MY_LOCATION"
echo "  Storage Account : $MY_STORAGE_ACCOUNT (Generated)"
echo "  Container       : $MY_CONTAINER_NAME"
echo ""

# --- STEP 0: AZURE LOGIN ---
echo "--- Step 0: Azure Login ---"
echo "A browser window will open. Please log in to your Azure account..."
az login
echo "Login successful."
echo ""

# --- STEP 1: CREATE RESOURCE GROUP ---
echo "--- Step 1: Creating Resource Group: $MY_RESOURCE_GROUP ---"
az group create \
  --name $MY_RESOURCE_GROUP \
  --location $MY_LOCATION \
  -o table
echo ""

# --- STEP 2: CREATE STORAGE ACCOUNT ---
echo "--- Step 2: Creating Storage Account: $MY_STORAGE_ACCOUNT ---"
echo "(This step may take a few minutes...)"
az storage account create \
  --name $MY_STORAGE_ACCOUNT \
  --resource-group $MY_RESOURCE_GROUP \
  --location $MY_LOCATION \
  --sku Standard_LRS \
  -o table
echo ""

# --- STEP 3: CREATE CONTAINER ---
echo "--- Step 3: Creating Container: $MY_CONTAINER_NAME ---"
az storage container create \
  --name $MY_CONTAINER_NAME \
  --account-name $MY_STORAGE_ACCOUNT \
  --auth-mode login \
  -o table
echo ""

# --- STEP 4: GENERATE SAS TOKEN (1 Year Expiry) ---
echo "--- Step 4: Generating SAS Token for 'azcopy' (Expires in 1 Year) ---"


echo "Calculating expiry date..."
OS_TYPE=$(uname)

if [ "$OS_TYPE" == "Darwin" ]; then
    # macOS/BSD syntax
    EXPIRY_DATE=$(date -u -v+1y +%Y-%m-%dT%H:%MZ)
elif [ "$OS_TYPE" == "Linux" ] || [[ "$OS_TYPE" == "MINGW"* ]]; then
    # GNU/Linux syntax (used by Linux and Git Bash on Windows)
    EXPIRY_DATE=$(date -u -d "+1 year" +%Y-%m-%dT%H:%MZ)
else
    echo "Error: Unsupported OS ('$OS_TYPE') for date calculation."
    exit 1
fi
echo "Expiry date set to: $EXPIRY_DATE"


# Generate the token with the correct permissions ('b', 'co', 'cwl')
SAS_TOKEN=$(az storage account generate-sas \
  --account-name $MY_STORAGE_ACCOUNT \
  --services b \
  --resource-types co \
  --permissions cwl \
  --expiry $EXPIRY_DATE \
  -o tsv)

echo "SAS Token generated successfully."
echo ""


echo "========================================================================="
echo "SETUP COMPLETE!"
echo ""
echo "AZURE_STORAGE_ACCOUNT: \"$MY_STORAGE_ACCOUNT\""
echo "AZURE_STORAGE_CONTAINER: \"$MY_CONTAINER_NAME\""
echo ""
echo "--- PLEASE STORE THIS TOKEN SECURELY ---"
echo "AZURE_STORAGE_SAS_TOKEN: \"?$SAS_TOKEN\""
echo "========================================================================="
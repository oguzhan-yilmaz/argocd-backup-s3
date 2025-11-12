# argocd-backup-s3

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/argocd-backup-s3)](https://artifacthub.io/packages/helm/argocd-backup-s3/argocd-backup-s3)
[![Build and publish Docker image to ghcr.io](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/docker-build-and-push.yaml/badge.svg)](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/docker-build-and-push.yaml)
[![Helm package and push to Github Pages](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/helm-package-and-publish.yaml/badge.svg)](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/helm-package-and-publish.yaml)


## Backup your ArgoCD Instance — the easy way

- 🔄 Automated backups using Kubernetes CronJob
- 📦 Uses official `argocd admin export` command for reliable backups
- 🗄️ Supports any S3-compatible storage (AWS S3, MinIO, etc.) and Azure Blob Storage
- 🔒 Secure credential management through Kubernetes secrets
- 🚀 Easy deployment via Helm chart or ArgoCD application
- ⏰ Configurable backup schedule and timezone
- 🔍 Detailed logging and error reporting

## Quick Links

- 🐋 [Docker Image](https://github.com/oguzhan-yilmaz/argocd-backup-s3/pkgs/container/argocd-backup-s3)
- 📜 [Helm Package](https://artifacthub.io/packages/helm/argocd-backup-s3/argocd-backup-s3)
- 🔰 [Helm Index](https://oguzhan-yilmaz.github.io/argocd-backup-s3/)
- 📝 [Github Releases](https://github.com/oguzhan-yilmaz/argocd-backup-s3/releases)

---

## Installation

### Option 1: Install with Helm

1. Add the Helm repository:
```bash
helm repo add argocd-backup-s3 https://oguzhan-yilmaz.github.io/argocd-backup-s3/
helm repo update argocd-backup-s3
```


2. Get the default values file:
```bash
helm show values argocd-backup-s3/argocd-backup-s3 > my-argocd-backup-s3.values.yaml
```

3. Configure the required values in `my-argocd-backup-s3.values.yaml`:
```yaml
timeZone: 'Asia/Istanbul'  # optional -- https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
schedule: "00 20 * * *"    # https://crontab.guru/#00_20_*_*_*

secretEnvVars:
  AWS_ACCESS_KEY_ID: ""
  AWS_SECRET_ACCESS_KEY: ""
  AWS_DEFAULT_REGION: ""
  S3_UPLOAD_PREFIX: ""
  S3_BUCKET_NAME: ""
  ARGOCD_SERVER: ""
  ARGOCD_ADMIN_USERNAME: "admin"
  ARGOCD_ADMIN_PASSWORD: ""

  # If you want to use S3 compatible storage, you can use the following env var
  #  https://docs.aws.amazon.com/sdkref/latest/guide/feature-ss-endpoints.html
  # AWS_ENDPOINT_URL_S3: 'https://s3.amazonaws.com' 

```

4. Install the chart:
```bash
helm upgrade --install \
  -n argocd \
  -f my-argocd-backup-s3.values.yaml \
  argocd-backup-s3 argocd-backup-s3/argocd-backup-s3
```

4. Install the chart for Azure:

```bash
helm upgrade --install \
  -n argocd \
  -f azure-values.yaml \
  argocd-backup-s3 argocd-backup-s3/argocd-backup-s3
```

### Option 2: Install with ArgoCD

1. Download the ArgoCD application manifest:
```bash
curl -sL https://raw.githubusercontent.com/oguzhan-yilmaz/argocd-backup-s3/refs/heads/main/argocd-application.yaml -o argocd-backup-s3.argoapp.yaml
```

- Download the ArgoCD application manifest for Azure Blob Storage

```bash
curl -sL https://raw.githubusercontent.com/oguzhan-yilmaz/argocd-backup-s3/refs/heads/main/azure-argocd-application.yaml -o argocd-backup-azure.argoapp.yaml
```

2. Edit the `.valuesObject` section in the manifest with your configuration

3. Apply the manifest:
```bash
kubectl apply -f argocd-backup-s3.argoapp.yaml
```

- Apply the manifest for Azure Blob Storage

```bash
kubectl apply -f argocd-backup-azure.argoapp.yaml
```

---

## AWS S3 Setup

The following script helps you set up the required AWS resources (S3 bucket and IAM user) for the backup solution:

```bash
# Set your company prefix
PREFIX="mycompany-argocd-backup-s3"

# Get AWS Account Info
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region 2>/dev/null || echo "eu-west-1")

echo "AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
echo "AWS_REGION: ${AWS_REGION}"

# Create bucket name using AWS Account ID as suffix
BUCKET_NAME="${PREFIX}-${AWS_ACCOUNT_ID}"
IAM_USER_NAME="${BUCKET_NAME}"

echo "BUCKET_NAME: ${BUCKET_NAME}"
echo "IAM_USER_NAME: ${IAM_USER_NAME}"

# Create S3 Bucket
aws s3 mb "s3://${BUCKET_NAME}" --region "${AWS_REGION}"

# Create IAM User and Policy
aws iam create-user --user-name "${IAM_USER_NAME}"

POLICY_NAME="${IAM_USER_NAME}-bucket-access-policy"
aws iam create-policy \
    --policy-name "${POLICY_NAME}" \
    --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::'"${BUCKET_NAME}"'",
                "arn:aws:s3:::'"${BUCKET_NAME}"'/*"
            ]
        }
    ]
}'

# Attach Policy to User
aws iam attach-user-policy \
    --user-name "${IAM_USER_NAME}" \
    --policy-arn "$(aws iam list-policies --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text)"

# Create Access Keys
CREDENTIALS=$(aws iam create-access-key --user-name "${IAM_USER_NAME}")

# Print Helm Values
echo "------ SUCCESS ------"
echo "Helm values.yaml:"
echo ""
echo "secretEnvVars:"
echo "  AWS_ACCESS_KEY_ID: '$(echo "${CREDENTIALS}" | jq -r '.AccessKey.AccessKeyId')'"
echo "  AWS_SECRET_ACCESS_KEY: '$(echo "${CREDENTIALS}" | jq -r '.AccessKey.SecretAccessKey')'"
echo "  AWS_DEFAULT_REGION: ${AWS_REGION}"
echo "  S3_BUCKET_NAME: ${BUCKET_NAME}"
echo "  S3_UPLOAD_PREFIX: my-argo-instance/"
echo "  ARGOCD_SERVER: argocd-server.argocd"
echo "  ARGOCD_ADMIN_USERNAME: 'admin'"
echo "  ARGOCD_ADMIN_PASSWORD: ''"
echo "  AWS_ENDPOINT_URL_S3: 'https://s3.amazonaws.com'"
```

## Azure Setup
The following script helps you set up the required Azure resources (Resource Group, Storage Account, Container and SAS Token ) for the backup solution:

```bash
#!/bin/bash

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
```

## Configuration

### Required Environment Variables for AWS

- `AWS_ACCESS_KEY_ID`: AWS access key for S3 access
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for S3 access
- `AWS_DEFAULT_REGION`: AWS region for S3 bucket
- `S3_BUCKET_NAME`: Name of the S3 bucket
- `S3_UPLOAD_PREFIX`: Prefix for uploaded backup files
- `ARGOCD_SERVER`: ArgoCD server address
- `ARGOCD_ADMIN_PASSWORD`: ArgoCD admin password


### Required Environment Variables for AZURE

- `AZURE_STORAGE_ACCOUNT`: Azure Storage Account for Blob Storage
- `AZURE_STORAGE_CONTAINER`: Azure Container for Blob Storage
- `AZURE_STORAGE_SAS_TOKEN`: Azure Access Token for Blob Storage
- `AZURE_UPLOAD_PREFIX`: Prefix for uploaded backup files
- `ARGOCD_SERVER`: ArgoCD server address
- `ARGOCD_ADMIN_PASSWORD`: ArgoCD admin password


### Optional Configuration

- `timeZone`: Timezone for the CronJob (default: UTC)  <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones>
- `schedule`: Cron schedule for backups (default: "00 20 * * *")
- `AWS_ENDPOINT_URL_S3`: (env var) Custom S3 endpoint for non-AWS S3 storage
- `ARGOCD_ADMIN_USERNAME`: Custom ArgoCD Admin Username
- `serviceAccount.irsaEnabled`: This value allows your pods to access AWS S3 API via IAM Role please check the <a href="https://aws.amazon.com/tr/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/">details</a>

## Credits

- [WoodProgrammer](https://github.com/WoodProgrammer): added Service Account EKS IRSA support 
- [lieblinger](https://github.com/lieblinger): added `ca-certificates` and fixed `ARGOCD_EXTRA_ARGS` in entrypoint script

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.



# argocd-backup-s3

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/argocd-backup-s3)](https://artifacthub.io/packages/helm/argocd-backup-s3/argocd-backup-s3)
[![Build and publish Docker image to ghcr.io](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/docker-build-and-push.yaml/badge.svg)](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/docker-build-and-push.yaml)
[![Helm package and push to Github Pages](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/helm-package-and-publish.yaml/badge.svg)](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/helm-package-and-publish.yaml)


## Backup your ArgoCD Instance — the easy way

- 🔄 Automated backups using Kubernetes CronJob
- 📦 Uses official `argocd admin export` command for reliable backups
- 🗄️ Supports any S3-compatible storage (AWS S3, MinIO, etc.)
- 🔒 Secure credential management through Kubernetes secrets
- 🚀 Easy deployment via Helm chart or ArgoCD application
- ⏰ Configurable backup schedule and timezone
- 🔍 Detailed logging and error reporting

## Prerequisites

- Kubernetes cluster with ArgoCD installed
- Access to an S3-compatible storage service
- `kubectl` and `helm` installed (for manual installation)
- AWS CLI (for setting up S3 bucket and IAM user)

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
timeZone: 'Asia/Istanbul'  # optional
schedule: "00 20 * * *"   # cron schedule

secretEnvVars:
  AWS_ACCESS_KEY_ID: ""
  AWS_SECRET_ACCESS_KEY: ""
  AWS_DEFAULT_REGION: ""
  S3_UPLOAD_PREFIX: ""
  S3_BUCKET_NAME: ""
  ARGOCD_SERVER: ""
  ARGOCD_ADMIN_PASSWORD: ""
```

4. Install the chart:
```bash
helm upgrade --install \
  -n argocd \
  -f my-argocd-backup-s3.values.yaml \
  argocd-backup-s3 argocd-backup-s3/argocd-backup-s3
```

### Option 2: Install with ArgoCD

1. Download the ArgoCD application manifest:
```bash
curl -sL https://raw.githubusercontent.com/oguzhan-yilmaz/argocd-backup-s3/refs/heads/main/argocd-application.yaml -o argocd-backup-s3.argoapp.yaml
```

2. Edit the `.valuesObject` section in the manifest with your configuration
3. Apply the manifest:
```bash
kubectl apply -f argocd-backup-s3.argoapp.yaml
```

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
echo "  ARGOCD_ADMIN_PASSWORD: ''"
echo "  AWS_S3_ENDPOINT: 'https://s3.amazonaws.com'"
```

## Configuration

### Required Environment Variables

- `AWS_ACCESS_KEY_ID`: AWS access key for S3 access
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for S3 access
- `AWS_DEFAULT_REGION`: AWS region for S3 bucket
- `S3_BUCKET_NAME`: Name of the S3 bucket
- `S3_UPLOAD_PREFIX`: Prefix for uploaded backup files
- `ARGOCD_SERVER`: ArgoCD server address
- `ARGOCD_ADMIN_PASSWORD`: ArgoCD admin password

### Optional Configuration

- `timeZone`: Timezone for the CronJob (default: UTC)
- `schedule`: Cron schedule for backups (default: "00 20 * * *")
- `AWS_S3_ENDPOINT`: Custom S3 endpoint for non-AWS S3 storage

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.



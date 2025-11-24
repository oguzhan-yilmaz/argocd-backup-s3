# argocd-backup-s3

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/argocd-backup-s3)](https://artifacthub.io/packages/helm/argocd-backup-s3/argocd-backup-s3)
[![Build and publish Docker image to ghcr.io](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/docker-build-and-push.yaml/badge.svg)](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/docker-build-and-push.yaml)
[![Helm package and push to Github Pages](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/helm-package-and-publish.yaml/badge.svg)](https://github.com/oguzhan-yilmaz/argocd-backup-s3/actions/workflows/helm-package-and-publish.yaml)


## Backup your ArgoCD Instance — the easy way

- 🔄 Automated backups using Kubernetes CronJob
- 📦 Uses official `argocd admin export` command for reliable backups
- 🗄️ Supports **any S3-compatible storage** (AWS S3, MinIO, etc.) and **Azure Blob Storage**
- 🔒 Secure credential management through Kubernetes secrets
- 🚀 Easy deployment via Helm chart or ArgoCD application
- ⏰ Configurable backup schedule and timezone

#### Quick Links

- 🐋 [Docker Image](https://github.com/oguzhan-yilmaz/argocd-backup-s3/pkgs/container/argocd-backup-s3)
- 📜 [ArtifactHub](https://artifacthub.io/packages/helm/argocd-backup-s3/argocd-backup-s3)
- 📝 [Github Releases](https://github.com/oguzhan-yilmaz/argocd-backup-s3/releases)

---

## Installation

### Install with Helm

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

### Helm — Use Azure Blob Storage 

```bash
curl -sL https://raw.githubusercontent.com/oguzhan-yilmaz/argocd-backup-s3/refs/heads/main/argocd-backup-s3/azure-blob.values.yaml -o azure-blob.values.yaml

# Configure the required values in `azure-blob.values.yaml`:

helm upgrade --install \
  -n argocd \
  -f azure-blob.values.yaml \
  argocd-backup-s3 argocd-backup-s3/argocd-backup-s3
```
---

## Install with ArgoCD

1. Download the ArgoCD application manifest:
```bash
curl -sL https://raw.githubusercontent.com/oguzhan-yilmaz/argocd-backup-s3/refs/heads/main/argocd-application.yaml -o argocd-backup-s3.argoapp.yaml
```

2. Edit the `.valuesObject` section in the manifest with your configuration


3. Apply the manifest:
```bash
kubectl apply -f argocd-backup-s3.argoapp.yaml
```

#### ArgoCD Application: Run Custom Entrypoint Script 
```bash
# 1. Download the ArgoCD application manifest:
curl -sL https://raw.githubusercontent.com/oguzhan-yilmaz/argocd-backup-s3/refs/heads/main/custom-command.argocd-application.yaml -o custom-command.argocd-application.yaml

# 2. Edit the `.valuesObject` section in the manifest with your configuration

# 3. Apply the manifest:
kubectl apply -f custom-command.argocd-application.yaml
```


#### ArgoCD Application: Use Azure Blob Storage
```bash
# 1. Download the ArgoCD application manifest:
curl -sL https://raw.githubusercontent.com/oguzhan-yilmaz/argocd-backup-s3/refs/heads/main/azure-blob.argocd-application.yaml -o azure-blob.argocd-application.yaml

# 2. Edit the `.valuesObject` section in the manifest with your configuration

kubectl apply -f azure-blob.argocd-application.yaml
```



---



## Configuration

### Required Environment Variables for AWS

- `AWS_ACCESS_KEY_ID`: AWS access key for S3 access
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for S3 access
- `AWS_DEFAULT_REGION`: AWS region for S3 bucket
- `S3_BUCKET_NAME`: Name of the S3 bucket
- `S3_UPLOAD_PREFIX`: Prefix for uploaded backup files
- `ARGOCD_SERVER`: ArgoCD server address
- `ARGOCD_ADMIN_PASSWORD`: ArgoCD admin password


### Required Environment Variables for AZURE Blob Storage

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


## Setup Helpers 
- **AWS S3 Setup Script**
  The following script helps you set up the required AWS resources (S3 bucket and IAM user) for the backup solution:
  - [create-iam-user-and-s3-bucket.sh](./create-iam-user-and-s3-bucket.sh)

- **Azure Setup Script**
  The following script helps you set up the required Azure resources (Resource Group, Storage Account, Container and SAS Token ) for the backup solution:
  - [create-azure-blob-storage-and-sastoken.sh](./create-azure-blob-storage-and-sastoken.sh)

## Credits

- [WoodProgrammer](https://github.com/WoodProgrammer): added Service Account EKS IRSA support 
- [lieblinger](https://github.com/lieblinger): added `ca-certificates` and fixed `ARGOCD_EXTRA_ARGS` in entrypoint script
- [ersinsari13](https://github.com/ersinsari13): added Azure Blob Storage support  

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

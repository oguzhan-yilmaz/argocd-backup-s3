# argocd-backup-s3

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/argocd-backup-s3)](https://artifacthub.io/packages/helm/argocd-backup-s3/argocd-backup-s3)

[ghcr.io - Docker Image](https://github.com/oguzhan-yilmaz/argocd-backup-s3/pkgs/container/argocd-backup-s3)


```bash
manual trigger
kubectl create job -n argocd --from=cronjob/backup-job manual-backup-1
```


## Install with Helm


```bash
helm repo add argocd-backup-s3 https://oguzhan-yilmaz.github.io/argocd-backup-s3/

helm repo update argocd-backup-s3
```

### Helm Values

Get the default `values.yaml` in order to edit.

```bash
helm show values argocd-backup-s3/argocd-backup-s3 > my-argocd-backup-s3.values.yaml
```

#### [Helm Values Dependencies](Dependencies.README.md)

#### ArgoCD CLI Access for export

This job makes use of `argocd admin export` command to create a yaml file export.

So, we need to provide the ArgoCD admin account access.

Follow the documentation: [ArgoCD Server Addr. and admin pass](Dependencies.README.md#argocd-cli-access)

#### AWS S3 Bucket and IAM User Access Keys

Follow the bash script to:

- creates S3 Bucket
- creates IAM User (access only to S3 Bucket)
- creates IAM User Access Keys 

[Bash script for creating S3 Bucket and IAM User Access Keys](Dependencies.README.md#aws-s3-bucket-and-access-credentials)




<!-- 
```bash
git clone ..
cd abcdefg


# vim values.yaml

helm install -n argocd \
    argocd-backup-s3 ./argocd-backup-s3
```
 -->

## Install with ArgoCD


You can use the `argocd-application.yaml` manifest in the Github repo: <https://github.com/oguzhan-yilmaz/argocd-backup-s3/blob/main/argocd-application.yaml>

```bash
kubectl apply -f https://raw.githubusercontent.com/oguzhan-yilmaz/argocd-backup-s3/refs/heads/main/argocd-application.yaml
```
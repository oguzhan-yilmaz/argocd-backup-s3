# argocd-backup-s3

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/argocd-backup-s3)](https://artifacthub.io/packages/helm/argocd-backup-s3/argocd-backup-s3)

```bash
manual trigger
kubectl create job -n argocd --from=cronjob/backup-job manual-backup-1
```


## Install auto-blacbox-exporter

```bash
helm repo add argocd-backup-s3 https://oguzhan-yilmaz.github.io/argocd-backup-s3/

helm repo update argocd-backup-s3

helm install -n argocd \
    argocd-backup-s3 argocd-backup-s3/argocd-backup-s3
```


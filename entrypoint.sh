#!/bin/bash
set -e
set -o pipefail
# ----------- ENV VAR CHECKS -----------
for var in ARGOCD_SERVER ARGOCD_ADMIN_PASSWORD S3_BUCKET_NAME S3_UPLOAD_PREFIX; do
    if [ -z "${!var}" ]; then
    echo "ERROR: Env Var '$var' is not set. Aborting."
    exit 1
    fi
done
echo "------------*------------*------------"
# ----------- AWS CLI CHECKS -----------
echo "CHECK: Do we have AWS S3 access to the $S3_BUCKET_NAME  bucket?"
aws s3api head-bucket --bucket "$S3_BUCKET_NAME" || {
    echo "ERROR: Bucket access failed, current AWS identity:"
    aws sts get-caller-identity
    echo "ERROR: Please fix AWS permissions or the region. Aborting..."
    exit 1
} 
echo "------------*------------*------------"

# ----------- LOGIN TO ARGOCD -----------
echo "Logging in to ArgoCD Server: ${ARGOCD_SERVER}"
if [ -z "${ARGOCD_ADMIN_USERNAME}" ];then
  echo "WARNING: ARGOCD_ADMIN_USERNAME is empty; continue with default one"
  export ARGOCD_ADMIN_USERNAME="admin"
fi

argocd login "${ARGOCD_SERVER}" --username ${ARGOCD_ADMIN_USERNAME} --password "${ARGOCD_ADMIN_PASSWORD}" "${ARGOCD_EXTRA_ARGS:-''}" --plaintext || {
    echo "ERROR: ArgoCD login failed. Make sure to use admin account password!"
    exit 1
}

echo "Logged in to ArgoCD Server, checking current context: ${ARGOCD_SERVER}"
argocd context
argocd account get-user-info
echo "------------*------------*------------"

# ----------- ARGOCD EXPORT -----------

export FILENAME="argocd-export-$(date +"%Y-%m-%d--%H-%M").yaml"
echo "Setting the export filename to: ${FILENAME}"

echo "Running the 'argocd admin export' command"
argocd admin export > "$FILENAME"

echo "Export yaml file line count: $(wc -l $FILENAME)"
echo "------------*------------*------------"

# ----------- S3 UPLOAD -----------
echo "Uploading to  s3://${S3_BUCKET_NAME}/${S3_UPLOAD_PREFIX%/}/${FILENAME}"
aws s3 cp ${FILENAME} s3://${S3_BUCKET_NAME}/${S3_UPLOAD_PREFIX%/}/${FILENAME}
echo "------------*------------*------------"

echo "Listing  s3://${S3_BUCKET_NAME}/${S3_UPLOAD_PREFIX}"
echo "---"
aws s3 ls s3://${S3_BUCKET_NAME}/${S3_UPLOAD_PREFIX}
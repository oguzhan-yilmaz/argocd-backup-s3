#!/bin/bash
# ----------- ENV VAR CHECKS -----------
for var in ARGOCD_SERVER ARGOCD_ADMIN_PASSWORD S3_BUCKET_NAME S3_UPLOAD_PREFIX; do
    if [ -z "${!var}" ]; then
    echo "ERROR: Env Var '$var' is not set. Aborting."
    exit 1
    fi
done

# ----------- AWS CLI CHECKS -----------
aws s3api head-bucket --bucket "$S3_BUCKET_NAME" || {
    echo "ERROR: Bucket access failed, current AWS identity:"
    aws sts get-caller-identity
    echo "ERROR: Please fix AWS permissions or the region. Aborting..."
    exit 1
} 

# ----------- LOGIN TO ARGOCD -----------
echo "Logging in to ArgoCD Server: ${ARGOCD_SERVER}"
argocd login "${ARGOCD_SERVER}" --username admin --password "${ARGOCD_ADMIN_PASSWORD}" --plaintext || {
    echo "ERROR: ArgoCD login failed. Make sure to use admin account password!"
    exit 1
}
argocd context
argocd account get-user-info
export FILENAME="argocd-export-$(date +"%Y-%m-%d--%H-%M").yaml"

# sleep infinity

# ----------- ARGOCD EXPORT -----------
echo "Running the 'argocd admin export' command"
argocd admin export > "$FILENAME"
# file "$FILENAME"
echo "Export yaml file line count: $(wc -l $FILENAME)"

# ----------- S3 UPLOAD -----------
echo "Uploading to  s3://${S3_BUCKET_NAME}/${S3_UPLOAD_PREFIX%/}/${FILENAME}"
aws s3 cp ${FILENAME} s3://${S3_BUCKET_NAME}/${S3_UPLOAD_PREFIX%/}/${FILENAME}
echo "Listing  s3://${S3_BUCKET_NAME}/${S3_UPLOAD_PREFIX}"
aws s3 ls s3://${S3_BUCKET_NAME}/${S3_UPLOAD_PREFIX}
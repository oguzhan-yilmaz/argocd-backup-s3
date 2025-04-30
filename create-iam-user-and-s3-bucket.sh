#!/bin/bash

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
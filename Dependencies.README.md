# Dependencies Script

## Bash

#### Set default PREFIX if not provided

```bash
# PREFIX="${PREFIX:-argocd-backup-s3}"
PREFIX="mycompany-argocd-backup-s3"
```
#### Get AWS Account ID

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region 2>/dev/null || echo "eu-west-1")

echo "AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
echo "AWS_REGION: ${AWS_REGION}"
```
#### Create bucket name using AWS Account ID as suffix


```bash
BUCKET_NAME="${PREFIX}-${AWS_ACCOUNT_ID}"
IAM_USER_NAME="${BUCKET_NAME}"

echo "BUCKET_NAME: ${BUCKET_NAME}"
echo "IAM_USER_NAME: ${IAM_USER_NAME}"
```

#### Create S3 Bucket

```bash
echo "Creating S3 Bucket: s3://${BUCKET_NAME}"
aws s3 mb "s3://${BUCKET_NAME}" --region "${AWS_REGION}"
```

#### Create IAM User

```bash
echo "Creating IAM User: s3://${IAM_USER_NAME}"
aws iam create-user --user-name "${IAM_USER_NAME}"
```

#### Create Restrictive IAM Policy

```bash
POLICY_NAME="${IAM_USER_NAME}-bucket-access-policy"
echo "Creating IAM Policy: ${POLICY_NAME}"
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
```

#### Attach Policy to User

```bash
echo "Attach the IAM Policy to User"
aws iam attach-user-policy \
    --user-name "${IAM_USER_NAME}" \
    --policy-arn "$(aws iam list-policies --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text)"
```

#### Create Access Keys

```bash
CREDENTIALS=$(aws iam create-access-key --user-name "${IAM_USER_NAME}")
```

#### Print Credentials and Information

```bash
echo "------ SUCCESS ------"

echo "Bucket Name: ${BUCKET_NAME}"
echo "IAM User: ${IAM_USER_NAME}"
echo "AWS Region: ${AWS_REGION}"
echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
echo "Access Key ID: $(echo "${CREDENTIALS}" | jq -r '.AccessKey.AccessKeyId')"
echo "Secret Access Key: $(echo "${CREDENTIALS}" | jq -r '.AccessKey.SecretAccessKey')"
```

#!/bin/bash

set -euo pipefail

# ==== Input Parameters ====
PROJECT="santoses"
ENVIRONMENT="$1"     # vadev, vastaging, vaprod
REGION="$2"          # AWS region, e.g., us-east-1

# ==== Safety checks ====
if [[ -z "$ENVIRONMENT" || -z "$REGION" ]]; then
  echo "Usage: $0 <environment> <account-id> <region>"
  exit 1
fi

# ==== Derived names ====
S3_BUCKET="${PROJECT}-${ENVIRONMENT}-tf"
DDB_TABLE="${PROJECT}-${ENVIRONMENT}-tf-lock"
#KMS_ALIAS="alias/${PROJECT}-${ENVIRONMENT}-tf-backend"

echo "=== Starting bootstrap for ${PROJECT} - ${ENVIRONMENT} in ${REGION} ==="

# ==== Create KMS CMK ====
#KMS_KEY_ID=$(aws kms describe-key --key-id "${KMS_ALIAS}" --region "${REGION}" --query 'KeyMetadata.KeyId' --output text 2>/dev/null || true)
#
#if [[ -z "$KMS_KEY_ID" || "$KMS_KEY_ID" == "None" ]]; then
#  echo "Creating new KMS key..."
#  KMS_KEY_ID=$(aws kms create-key --description "${PROJECT} ${ENVIRONMENT} Terraform backend key" --region "${REGION}" \
#      --query 'KeyMetadata.KeyId' --output text)
#  aws kms create-alias --alias-name "${KMS_ALIAS}" --target-key-id "${KMS_KEY_ID}" --region "${REGION}"
#else
#  echo "KMS key already exists: ${KMS_KEY_ID}"
#fi

# ==== Create S3 Bucket ====
if aws s3api head-bucket --bucket "${S3_BUCKET}" 2>/dev/null; then
  echo "S3 bucket ${S3_BUCKET} already exists."
else
  echo "Creating S3 bucket: ${S3_BUCKET}..."
  aws s3api create-bucket \
    --bucket "${S3_BUCKET}" \
    --region "${REGION}"

  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "${S3_BUCKET}" \
    --versioning-configuration Status=Enabled

  # Apply KMS encryption
#  aws s3api put-bucket-encryption \
#    --bucket "${S3_BUCKET}" \
#    --server-side-encryption-configuration "{
#        \"Rules\": [{
#          \"ApplyServerSideEncryptionByDefault\": {
#            \"SSEAlgorithm\": \"aws:kms\",
#            \"KMSMasterKeyID\": \"${KMS_KEY_ID}\"
#          }
#        }]
#    }"

  echo "S3 bucket ${S3_BUCKET} configured."
fi

## ==== Attach bucket policy (hardened Terraform-only access) ====
#echo "Applying S3 bucket policy..."
#aws s3api put-bucket-policy \
#  --bucket "${S3_BUCKET}" \
#  --policy "{
#    \"Version\": \"2012-10-17\",
#    \"Statement\": [{
#      \"Effect\": \"Allow\",
#      \"Principal\": \"*\",
#      \"Action\": [
#        \"s3:GetObject\",
#        \"s3:PutObject\",
#        \"s3:DeleteObject\",
#        \"s3:ListBucket\"
#      ],
#      \"Resource\": [
#        \"arn:aws:s3:::${S3_BUCKET}\",
#        \"arn:aws:s3:::${S3_BUCKET}/*\"
#      ]
#    }]
#  }"

# ==== Create DynamoDB Lock Table ====
if aws dynamodb describe-table --table-name "${DDB_TABLE}" --region "${REGION}" 2>/dev/null; then
  echo "DynamoDB table ${DDB_TABLE} already exists."
else
  echo "Creating DynamoDB lock table: ${DDB_TABLE}..."
  aws dynamodb create-table \
    --table-name "${DDB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
fi

echo "✅ Hardened bootstrap complete for ${PROJECT} - ${ENVIRONMENT} - ${REGION}"
#!/bin/bash

if [ $# -lt 3 ]; then
  echo 'You specify the environment, the template name, and the source directory'
  echo '    (e.g. ./sam-build=and-package.sh dev logger ./src/lambda/layer/logger)'
  exit 1
fi

ORIGINAL_DIR=$(pwd)
FUNCTION_NAME="dmptool-$2-$1"
SCEPTRE_CONFIG_FILE="${ORIGINAL_DIR}/config/${1}/lambda/layer/${2}.yaml"

# Retrieve the S3 bucket name from the CloudFormation stack
PREFIX_QUERY="Stacks[0].Outputs[?OutputKey==\`S3PrivateBucketID\`].OutputValue"
S3_BUCKET=$(aws cloudformation describe-stacks --stack-name "dmp-tool-${1}-s3" --query $PREFIX_QUERY --output text)

# Navigate to the source directory
cd $3

# Build the application
rm -rf dist
rm "${FUNCTION_NAME}.zip"
rm checksum

echo "${FUNCTION_NAME} --> Building function ..."
npm run build

# Remove all test files
echo "${LAYER_NAME} --> Removing test files from dist ..."
rm -rf dist/__tests__

# Generate the unique hash for the current files
HASH_SRC=$(sha256sum ./src/index.ts | awk '{print $1}')
HASH_PKG=$(sha256sum ./package-lock.json | awk '{print $1}')
echo $HASH_SRC+$HASH_PKG >> checksum
HASH_KEY=$(sha256sum ./checksum | awk '{print $1}')

# Publish the artifact to S3 if the hash is different
VERSIONED_KEY="lambda/function/${FUNCTION_NAME}-${HASH_KEY}.zip"
EXISTING_KEY=$(cat $SCEPTRE_CONFIG_FILE | grep 'S3Key:' | awk -F": " '{print $2}' | tr -d "'")

if [ "$VERSIONED_KEY" = "$EXISTING_KEY" ]; then
  echo "${FUNCTION_NAME} --> Code is unchanged, skipping upload to S3 ..."
else
  # ZIP the application
  echo "${FUNCTION_NAME} --> Zipping artifact ..."
  zip -r -q "${FUNCTION_NAME}.zip" dist/*.*

  echo "${FUNCTION_NAME} --> Uploading to S3 ..."
  aws s3 cp "${FUNCTION_NAME}.zip" "s3://${S3_BUCKET}/${VERSIONED_KEY}"

  # Update the Sceptre config with the new S3Key
  cd $ORIGINAL_DIR
  echo "${FUNCTION_NAME} --> Updating Sceptre config with new S3Key ..."
  SCEPTRE_CONFIG_FILE="./config/${1}/lambda/function/${2}.yaml"
  if grep -q "S3Key:" "$SCEPTRE_CONFIG_FILE"; then
    sed -i "" "s|^\( *S3Key: \).*|\1'${VERSIONED_KEY}'|" "$SCEPTRE_CONFIG_FILE"
  fi
fi

echo "${FUNCTION_NAME} --> Done."

#!/bin/bash

if [ $# -lt 3 ]; then
  echo 'You specify the environment, the template name, and the source directory'
  echo '    (e.g. ./sam-build=and-package.sh dev logger ./src/lambda/layer/logger)'
  exit 1
fi

ORIGINAL_DIR=$(pwd)
LAYER_NAME="dmptool-$2-$1"
SCEPTRE_CONFIG_FILE="${ORIGINAL_DIR}/config/${1}/lambda/layer/${2}.yaml"

# Retrieve the S3 bucket name from the CloudFormation stack
PREFIX_QUERY="Stacks[0].Outputs[?OutputKey==\`S3PrivateBucketID\`].OutputValue"
S3_BUCKET=$(aws cloudformation describe-stacks --stack-name "dmp-tool-${1}-s3" --query $PREFIX_QUERY --output text)

# Navigate to the source directory
cd $3

# Build the SAM application
rm -rf nodejs
rm "${LAYER_NAME}.zip"
rm checksum

echo "${LAYER_NAME} --> Building layer ..."
npm run build

# Removing all test files
echo "${LAYER_NAME} --> Removing test files from dist ..."
rm -rf nodejs/__tests__

# Copy the package.json and then install the prod dependencies
echo "${LAYER_NAME} --> Copying package.json and installing deps ..."
cp package.json nodejs/package.json
cd nodejs
npm install --omit=dev
mkdir -p "node_modules/dmptool-${2}/"
mv *.js "node_modules/dmptool-${2}/"
cd ..

# Generate the unique hash for the current files
HASH_SRC=$(sha256sum ./src/index.ts | awk '{print $1}')
HASH_PKG=$(sha256sum ./package-lock.json | awk '{print $1}')
echo $HASH_SRC+$HASH_PKG >> checksum
HASH_KEY=$(sha256sum ./checksum | awk '{print $1}')

# Publish the artifact to S3 if the hash is different
VERSIONED_KEY="lambda/layer/${LAYER_NAME}-${HASH_KEY}.zip"
EXISTING_KEY=$(cat $SCEPTRE_CONFIG_FILE | grep 'S3Key:' | awk -F": " '{print $2}' | tr -d "'")

if [ "$VERSIONED_KEY" = "$EXISTING_KEY" ]; then
  echo "${LAYER_NAME} --> Code is unchanged, skipping upload to S3 ..."
else
  # ZIP the application
  echo "${LAYER_NAME} --> Zipping artifact ..."
  zip -r -q ${LAYER_NAME}.zip ./nodejs/

  echo "${LAYER_NAME} --> Uploading to S3 ..."
  aws s3 cp "${LAYER_NAME}.zip" "s3://${S3_BUCKET}/${VERSIONED_KEY}"

  # Update the Sceptre config with the new S3Key
  cd $ORIGINAL_DIR
  echo "${LAYER_NAME} --> Updating Sceptre config with new S3Key ..."
  if grep -q "S3Key:" "$SCEPTRE_CONFIG_FILE"; then
    sed -i "" "s|^\( *S3Key: \).*|\1'${VERSIONED_KEY}'|" "$SCEPTRE_CONFIG_FILE"
  fi
fi

echo "${LAYER_NAME} --> Done."

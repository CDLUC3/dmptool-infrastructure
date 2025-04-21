# !bin/bash
ENV=$1
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ECR_ID=$ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com
if [ "$ENV" = '' ]; then
  ECR_REPO_NAME="dmptool/nodejs-mysql"
else
  ECR_REPO_NAME="dmptool-${ENV}/nodejs-mysql"
fi

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_ID
# Build the image
docker buildx build --platform linux/amd64 -t $ECR_REPO_NAME  --load .
# Tag the image
docker tag $ECR_REPO_NAME:latest $ECR_ID/$ECR_REPO_NAME:latest
# Push the image up to ECR
docker push $ECR_ID/$ECR_REPO_NAME:latest

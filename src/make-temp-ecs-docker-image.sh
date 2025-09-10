if [ $# -lt 4 ]; then
  echo 'You specify the environment, the image prefix, port and ALB healthcheck path! (e.g. dev apollo-latest 4000 up)'
  exit 1
fi

ECR_STACK_NAME="dmp-tool-$1-ecr"
PREFIX_QUERY="Stacks[0].Outputs[?OutputKey==\`EcrURIPrefix\`].OutputValue"
URI_QUERY="Stacks[0].Outputs[?OutputKey==\`EcrRepositoryURI\`].OutputValue"

ECR_PREFIX=$(aws cloudformation describe-stacks --stack-name $ECR_STACK_NAME --query $PREFIX_QUERY --output text)
ECR_URI=$(aws cloudformation describe-stacks --stack-name $ECR_STACK_NAME --query $URI_QUERY --output text)

echo "Creating a temporary ECS Docker image for $2 on $1 environment at $3 ..."

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_PREFIX

# Build a placeholder image for the ECS architecture that runs a simple HTTP server
# docker build --platform linux/amd64 -t temp-image - <<EOF
#   FROM python:3.12-alpine
#
#   WORKDIR /app
#
#   # Create the files that will respond to both "/" and "/${4}"
#   RUN echo "OK" > index.html && mkdir -p $4 && echo "OK" > $4/index.html && chmod -R 755 /app
#
#  EXPOSE $3
#
#  # Force run as root to avoid permission problems
#  # USER root
#
#  # CMD ["python", "-m", "http.server", "$3", "--bind", "0.0.0.0", "--directory", "/app"]
#  CMD ["sh", "-c", "echo Starting server on $3 && python -m http.server $3 --bind 0.0.0.0 --directory /app"]
#EOF

docker build --platform linux/amd64 -t temp-image - <<EOF
FROM node:20-alpine

WORKDIR /app

RUN apk update && \
    apk add curl

# Install http-server
RUN npm install -g http-server

# Create test files
RUN echo "OK" > /app/index.html && mkdir -p /app/$4 && echo "OK" > /app/$4/index.html && chmod -R 755 /app

EXPOSE $3

CMD sh -c "echo 'Starting server on port $3...' && http-server /app -p $3 -a 0.0.0.0"
EOF

#CMD ["http-server", "/app", "-p", "$3", "-a", "0.0.0.0"]

# Push the placeholder image to ECR
docker tag temp-image ${ECR_URI}:$2
docker push ${ECR_URI}:$2

echo "Temporary ECS Docker image created and pushed to ECR at ${ECR_URI}:$2"

# echo "Adding lifecycle policy to ECR repository ..."
# aws ecr put-lifecycle-policy \
#   --repository-name dmptool-$1/$2 \
#   --lifecycle-policy-text '{"rules": [{"action": {"type": "expire"},"selection": {"countType": "imageCountMoreThan","countNumber": 1,"tagStatus": "tagged","tagPrefixList": ["latest"]},"description": "Ensure that we do not have more than 1 tagged version","rulePriority": 1},{"action": {"type": "expire"},"selection": {"countType": "imageCountMoreThan","countNumber": 3,"tagStatus": "untagged"},"description": "Only retain the last 3 versions","rulePriority": 2}]}'

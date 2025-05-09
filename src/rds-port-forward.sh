#!/bin/bash

if [ $# -lt 2 ]; then
  echo 'You must specify the environment and a local port'
  echo '    (e.g. ./rds-port-forward.sh dev 3306)'
  exit 1
fi

echo "Note that you must be logged into the correct AWS environment!"

PREFIX_QUERY="Stacks[0].Outputs[?OutputKey==\`EcsFargateClusterId\`].OutputValue"
ECS_CLUSTER=$(aws cloudformation describe-stacks --stack-name "dmp-tool-${1}-ecs-cluster" --query $PREFIX_QUERY --output text)
DB_HOST=$(aws ssm get-parameter --name /uc3/dmp/tool/${1}/RdsHost | jq -r .Parameter.Value)
DB_PORT=$(aws ssm get-parameter --name /uc3/dmp/tool/${1}/RdsPort | jq -r .Parameter.Value)

DB_NAME=$(aws ssm get-parameter --name /uc3/dmp/tool/${1}/RdsName | jq -r .Parameter.Value)
DB_USER=$(aws ssm get-parameter --name /uc3/dmp/tool/${1}/RdsUsername | jq -r .Parameter.Value)
DB_PWD=$(aws ssm get-parameter --name /uc3/dmp/tool/${1}/RdsPassword | jq -r .Parameter.Value)

# If ECS_CLUSTER is empty, exit
if [ -z "$ECS_CLUSTER" ]; then
  echo ""
  echo "ECS cluster not found. Please make sure you are logged in to the correct AWS env."
  echo ""
  exit 1
fi

echo ""
echo "When you see the 'Waiting for connections' message, you can switch to your"
echo "local database client (e.g. Sequel Pro) and connect to the database using:"
echo ""
echo "   host: localhost"
echo "   database: $DB_NAME"
echo "   port: $2"
echo "   user: $DB_USER"
echo "   password: $DB_PWD"
echo ""

cd ~/.cdl-ssm-util || exit

# source from bash if the file exists otherwise from zsh
if [ -f ~/.zshrc ]; then
  source ~/.zshrc
elif [ -f ~/.bashrc ]; then
  source ~/.bashrc
elif [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
elif [ -f ~/.profile ]; then
  source ~/.profile
else
  echo "No shell profile found!"
  exit 1
fi

echo "Preparing to forward port $2 to $DB_HOST:$DB_PORT on cluster $ECS_CLUSTER"
echo ""
echo "Select one of the Apollo containers when asked."

python3 session.py port $ECS_CLUSTER $DB_HOST $2:$DB_PORT

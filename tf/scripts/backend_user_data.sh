#!/bin/bash

# Install Datadog Agent v7
DD_API_KEY="${datadog_api_key}" DD_SITE="datadoghq.eu" DD_AGENT_MAJOR_VERSION=7 bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
systemctl start datadog-agent

# Install Docker
yum update -y
yum install -y docker unzip
service docker start

# Deploy backend from S3
aws s3 cp s3://lti-project-code-bucket/backend.zip /home/ec2-user/backend.zip
unzip /home/ec2-user/backend.zip -d /home/ec2-user/

cd /home/ec2-user/backend
docker build -t lti-backend .
docker run -d -p 8080:8080 lti-backend

echo "Timestamp: ${timestamp}"

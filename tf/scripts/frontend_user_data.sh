#!/bin/bash

# Install Datadog Agent v7
DD_API_KEY="${datadog_api_key}" DD_SITE="datadoghq.eu" DD_AGENT_MAJOR_VERSION=7 bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
systemctl start datadog-agent

# Install Docker
yum update -y
yum install -y docker unzip
service docker start

# Deploy frontend from S3
aws s3 cp s3://lti-project-code-bucket/frontend.zip /home/ec2-user/frontend.zip
unzip /home/ec2-user/frontend.zip -d /home/ec2-user/

cd /home/ec2-user/frontend
docker build -t lti-frontend .
docker run -d -p 3000:3000 lti-frontend

echo "Timestamp: ${timestamp}"

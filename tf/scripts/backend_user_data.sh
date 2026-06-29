#!/bin/bash

# Install Datadog Agent v7
DD_INSTALLER=$(mktemp /tmp/dd-install-XXXXXX.sh)
curl --fail -L https://install.datadoghq.com/scripts/install_script_agent7.sh -o "$DD_INSTALLER"
DD_API_KEY="${datadog_api_key}" DD_SITE="datadoghq.eu" DD_AGENT_MAJOR_VERSION=7 DD_HOST_TAGS="project:lti-project,service:backend" bash "$DD_INSTALLER"
rm -f "$DD_INSTALLER"
systemctl start datadog-agent

# Install Docker
yum update -y
yum install -y docker unzip
systemctl enable docker
systemctl start docker

# Deploy backend from S3
aws s3 cp s3://lti-project-code-bucket-xvb/backend.zip /home/ec2-user/backend.zip
unzip /home/ec2-user/backend.zip -d /home/ec2-user/

cd /home/ec2-user/backend
docker build -t lti-backend .
docker run -d -p 8080:8080 lti-backend

echo "Timestamp: ${timestamp}"

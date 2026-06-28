data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "datadog_policy" {
  name        = "DatadogAWSPolicy"
  description = "Permisos para que Datadog lea métricas de CloudWatch y metadatos de EC2"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "ec2:DescribeInstances",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_instances" "running" {
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

resource "datadog_integration_aws" "main" {
  account_id  = data.aws_caller_identity.current.account_id
  role_name   = "DatadogIntegrationRole"
  filter_tags = ["Datadog:true"]
}

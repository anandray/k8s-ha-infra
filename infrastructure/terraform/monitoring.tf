# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/${var.environment}/logs"
  retention_in_days = 30

  tags = {
    Name = "${var.environment}-logs"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"],
            ["AWS/EC2", "NetworkIn", "InstanceId", "i-1234567890abcdef0"],
            ["AWS/EC2", "NetworkOut", "InstanceId", "i-1234567890abcdef0"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.mysql.identifier],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.mysql.identifier]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      }
    ]
  })
}

# CloudWatch Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.environment}-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EC2 CPU utilization"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = "i-1234567890abcdef0"
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-alerts"
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "alerts@example.com"
}

# IAM Role for LogDNA
resource "aws_iam_role" "logdna" {
  name = "${var.environment}-logdna-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for LogDNA
resource "aws_iam_policy" "logdna" {
  name = "${var.environment}-logdna-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Role Policy Attachment for LogDNA
resource "aws_iam_role_policy_attachment" "logdna" {
  role       = aws_iam_role.logdna.name
  policy_arn = aws_iam_policy.logdna.arn
}

# LogDNA Integration
resource "aws_cloudwatch_log_subscription_filter" "logdna" {
  name            = "${var.environment}-logdna-filter"
  log_group_name  = aws_cloudwatch_log_group.main.name
  filter_pattern  = ""
  destination_arn = "arn:aws:lambda:${var.aws_region}:123456789012:function:logdna-integration"
  role_arn        = aws_iam_role.logdna.arn
}

# Grafana Workspace
resource "aws_grafana_workspace" "main" {
  name                     = "${var.environment}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type         = "SERVICE_MANAGED"
  role_arn                = aws_iam_role.grafana.arn
}

# IAM Role for Grafana
resource "aws_iam_role" "grafana" {
  name = "${var.environment}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Grafana
resource "aws_iam_policy" "grafana" {
  name = "${var.environment}-grafana-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# IAM Role Policy Attachment for Grafana
resource "aws_iam_role_policy_attachment" "grafana" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana.arn
} 
# --- CloudWatch Log Groups ---

resource "aws_cloudwatch_log_group" "app" {
  name              = "/eks/${local.name}/app"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${local.name}-cluster/cluster"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# --- SNS Topic for Alerts ---

resource "aws_sns_topic" "alerts" {
  name = "${local.name}-alerts"
  tags = local.common_tags
}

# --- CloudWatch Alarms ---

resource "aws_cloudwatch_metric_alarm" "node_cpu" {
  alarm_name          = "${local.name}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS node CPU > 80% for 3 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_eks_cluster.main.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "node_memory" {
  alarm_name          = "${local.name}-node-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS node memory > 80% for 3 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_eks_cluster.main.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "pod_restart" {
  alarm_name          = "${local.name}-pod-restarts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Maximum"
  threshold           = 3
  alarm_description   = "Pod restarts > 3 in 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_eks_cluster.main.name
  }

  tags = local.common_tags
}

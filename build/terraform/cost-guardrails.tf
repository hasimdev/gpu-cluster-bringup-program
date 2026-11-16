# Cost guardrails for RAID risk R3 (spend runs past budget).

resource "aws_budgets_budget" "program" {
  name         = "gpu-cluster-bringup"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Project$gpu-cluster-bringup"]
  }

  dynamic "notification" {
    for_each = [50, 80, 100]
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [var.budget_alert_email]
    }
  }

  # Forecast alert gives warning before the money is actually spent.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}

# Auto-stop: if an instance's CPU stays under 5% for idle_stop_minutes, AWS
# stops it. Stopped instances don't bill for compute (EBS storage still bills).
#
# Caveat: this watches CPU, not GPU. A GPU job with a light CPU load could in
# theory look idle. The training benchmark keeps CPU busy enough feeding data,
# but for the 24h burn-in, check the alarm hasn't fired before trusting the
# result. A GPU-aware version would publish DCGM utilization as a custom
# CloudWatch metric and alarm on that instead.
resource "aws_cloudwatch_metric_alarm" "idle_stop" {
  count = var.node_count

  alarm_name          = "gpu-node-${count.index}-idle-stop"
  alarm_description   = "Stops gpu-node-${count.index} after ${var.idle_stop_minutes} idle minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = ceil(var.idle_stop_minutes / 5)
  threshold           = 5
  comparison_operator = "LessThanThreshold"

  dimensions = {
    InstanceId = aws_instance.gpu_node[count.index].id
  }

  alarm_actions = ["arn:aws:automate:${var.region}:ec2:stop"]
}

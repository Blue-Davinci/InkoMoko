# CloudWatch Log Group for container logs
resource "aws_cloudwatch_log_group" "container_logs" {
  name              = "/aws/ec2/inkomoko"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_prefix}-container-logs"
    }
  )
}

# CloudWatch Log Group for user-data logs
resource "aws_cloudwatch_log_group" "user_data_logs" {
  name              = "/aws/ec2/user-data"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_prefix}-user-data-logs"
    }
  )
}

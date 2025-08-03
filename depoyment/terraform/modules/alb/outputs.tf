output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "The name of the target group"
  value       = aws_lb_target_group.main.name
}

output "http_listener_arn" {
  description = "The ARN of the HTTP load balancer listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS load balancer listener"
  value       = var.enable_https && var.domain_name != "" && var.route53_zone_id != "" ? aws_lb_listener.https[0].arn : null
}

output "alb_security_group_id" {
  description = "The security group ID of the ALB"
  value       = aws_security_group.alb_sg.id
}

output "target_group_resource_label" {
  description = "Resource label for ALB target tracking scaling policies"
  value       = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.main.arn_suffix}"
}

output "certificate_arn" {
  description = "The ARN of the SSL certificate"
  value       = var.enable_https && var.domain_name != "" && var.route53_zone_id != "" ? aws_acm_certificate.main[0].arn : null
}

output "domain_name" {
  description = "The domain name associated with the certificate"
  value       = var.enable_https && var.domain_name != "" ? var.domain_name : null
}

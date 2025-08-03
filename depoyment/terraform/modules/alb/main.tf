# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id] # Use the security group created below
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_alb_deletion
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = var.alb_name
    }
  )
}

# ALB security group to allow incoming traffic on port 80 and 443 from the internet
resource "aws_security_group" "alb_sg" {
  name        = "${var.alb_name}-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = var.vpc_id

  # HTTP traffic on port 80
  ingress {
    description      = "Allow HTTP traffic on port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # HTTPS traffic on port 443
  ingress {
    description      = "Allow HTTPS traffic on port 443"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # egress for all traffic to anywhere
  egress {
    description      = "Allow all outbound traffic from anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # -1 means all protocols
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
}

# Target group - receives forwarded traffic from the listener and routes it to EC2 instances on port 80 (nginx)
resource "aws_lb_target_group" "main" {
  name     = "${var.alb_name}-tg"
  port     = 80 # 80 to match nginx
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health" # Matches nginx /health endpoint
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2 # Reduced for faster recovery
    unhealthy_threshold = 3
    port                = "traffic-port" # Use same port as target group (80)
  }

  # Connection draining
  deregistration_delay = 300

  tags = merge(
    var.tags,
    {
      Name = "${var.alb_name}-tg"
    }
  )
}

# ALB HTTP Listener - redirects to HTTPS if enabled, otherwise forwards to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https && var.domain_name != "" ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = !var.enable_https || var.domain_name == "" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main.arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.alb_name}-http-listener"
    }
  )
}

# ALB HTTPS Listener - forwards traffic to target group
resource "aws_lb_listener" "https" {
  count             = var.enable_https && var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.main[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.alb_name}-https-listener"
    }
  )
}

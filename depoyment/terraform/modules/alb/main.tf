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

# ALB security group to allow incoming traffic on port 80 from the internet
resource "aws_security_group" "alb_sg" {
  name        = "${var.alb_name}-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id
  # rules
  ingress {
    description      = "Allow HTTP traffic on port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false # This is not a self-referencing security group
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

# ALB Listener - forwards traffic to target group
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.alb_name}-listener"
    }
  )
}

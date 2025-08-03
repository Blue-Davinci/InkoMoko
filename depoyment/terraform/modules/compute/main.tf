# Create a security group to hook up with our ec2 instance
resource "aws_security_group" "asg_ec2_sg" {
  name        = "${var.instance_prefix}-ec2-sg"
  description = "Security group for the EC2 instance allowing only http"
  vpc_id      = var.vpc_id
  # ingress for port 80 (nginx) from ALB
  ingress {
    description      = "Allow HTTP traffic on port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = [var.alb_sg_id]
    self             = false # This is not a self-referencing security group
  }
  # egress for all traffic to anywhere
  egress {
    description      = "Allow all outbound traffic from anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
  tags = merge(var.tags, { Name = "${var.instance_prefix}-ec2-sg" })
}

# Instance profile for our EC2 instances
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.instance_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
  tags = merge(
    var.tags,
    {
      Name = "${var.instance_prefix}-ec2-instance-profile"
    }
  )
}

# launch template that will be used
resource "aws_launch_template" "ec2_launch_template" {
  name_prefix   = "${var.instance_prefix}-lt-"
  image_id      = var.instance_ami
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.asg_ec2_sg.id]

  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh.tpl", {
    vpc_cidr_block   = var.vpc_cidr,
    docker_image_url = var.docker_image_url,
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  lifecycle {
    create_before_destroy = true # create a resource before destroying an old one
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.instance_prefix}-ec2-instance"
      }
    )
  }
}

# AG
resource "aws_autoscaling_group" "asg" {
  name                      = "${var.instance_prefix}-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  health_check_type         = "ELB" # Changed from EC2 to ELB for ALB integration
  health_check_grace_period = 300
  target_group_arns         = [var.target_group_arn]

  launch_template {
    id = aws_launch_template.ec2_launch_template.id
    # ToDo: consider making this a var especially in Prod as
    # latest can cause issues inase of problems with template
    # maybe use a specific version, maybe 1?
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.instance_prefix}-asg"
    propagate_at_launch = true # propagate the tag to instances launched by the ASG
  }
  lifecycle {
    create_before_destroy = true
  }
}

# make a policy to scale up and down the ASG using Target Tracking
# we will use ALBRequestCountPerTargetas the metric to scale on
resource "aws_autoscaling_policy" "asg_scale_up" {
  name                   = "${var.instance_prefix}-asg-scale-up"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      # expected format: app/load-balancer-name/load-balancer-id/targetgroup/target-group-name/target-group-id
      resource_label = var.target_tracking_resource_label
    }
    target_value     = 100 # Each instance should handle 100 requests per second
    disable_scale_in = false
  }
}

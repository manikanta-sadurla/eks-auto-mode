# rabbitmq-module/main.tf

locals {
  name_prefix = "${var.environment}-${var.name}"
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
      Service     = "rabbitmq"
      Name        = local.name_prefix
    }
  )
}

# Security Group
resource "aws_security_group" "rabbitmq" {
  name_prefix = "${local.name_prefix}-rabbitmq-"
  description = "Security group for RabbitMQ cluster"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "rabbitmq_ports" {
  for_each = {
    amqp       = [5672, 5672, "AMQP"]
    management = [15672, 15672, "Management UI"]
    epmd       = [4369, 4369, "EPMD"]
    cluster    = [25672, 25672, "Inter-node communication"]
  }

  type              = "ingress"
  from_port         = each.value[0]
  to_port           = each.value[1]
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.rabbitmq.id
  description       = each.value[2]
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rabbitmq.id
}

# IAM Role and Instance Profile
resource "aws_iam_role" "rabbitmq" {
  name_prefix = "${local.name_prefix}-rabbitmq-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "rabbitmq" {
  name_prefix = "${local.name_prefix}-rabbitmq-"
  role        = aws_iam_role.rabbitmq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "rabbitmq" {
  name_prefix = "${local.name_prefix}-rabbitmq-"
  role        = aws_iam_role.rabbitmq.name
}

# Launch Template
resource "aws_launch_template" "rabbitmq" {
  name_prefix   = "${local.name_prefix}-rabbitmq-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.rabbitmq.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.rabbitmq.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type          = "gp3"
      iops                 = var.volume_iops
      encrypted            = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    cluster_name     = local.name_prefix
    environment      = var.environment
    admin_password   = var.admin_password
    enable_clustering = var.enable_clustering
    region           = data.aws_region.current.name
    cloudwatch_config = data.template_file.cloudwatch_config.rendered
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tags = local.common_tags
}

data "template_file" "cloudwatch_config" {
  template = file("${path.module}/templates/cloudwatch_config.json.tpl")

  # vars = {
  #   cluster_name = local.cluster_name
  #   instance_id  = local.instance_id
  # }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "rabbitmq" {
  name_prefix               = "${local.name_prefix}-rabbitmq-"
  desired_capacity         = var.instance_count
  max_size                = var.instance_count
  min_size                = var.instance_count
  vpc_zone_identifier     = var.subnet_ids
  target_group_arns       = var.target_group_arns
  health_check_type       = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.rabbitmq.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-rabbitmq-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = var.cpu_threshold
  alarm_actions      = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.rabbitmq.name
  }
}

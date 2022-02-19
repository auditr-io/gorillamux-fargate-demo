resource "aws_lb_target_group" "gmuxdemo_alb_target_group" {
  name        = "${var.application}-${var.environment}-alb-target-group"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.gmuxdemo_ecs_vpc.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.gmuxdemo_alb]

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_alb" "gmuxdemo_alb" {
  name               = "${var.application}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.gmuxdemo_ecs_public_subnet1.id,
    aws_subnet.gmuxdemo_ecs_public_subnet2.id
  ]

  security_groups = [
    aws_security_group.gmuxdemo_http_security_group.id,
    # aws_security_group.gmuxdemo_https_security_group.id,
    aws_security_group.gmuxdemo_ecs_security_group_egress.id
  ]

  depends_on = [aws_internet_gateway.gmuxdemo_ecs_igw]


  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_alb_listener" "gmuxdemo_alb_http" {
  load_balancer_arn = aws_alb.gmuxdemo_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gmuxdemo_alb_target_group.arn
  }

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

output "alb_url" {
  value = "http://${aws_alb.gmuxdemo_alb.dns_name}"
}

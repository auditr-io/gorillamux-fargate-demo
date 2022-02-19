terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "terraform-cloud"
}


data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "gmuxdemo_ecs_ecr_repo" {
  name = "${var.application}-${var.environment}"

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_ecr_lifecycle_policy" "gmuxdemo_ecs_ecr_repo_policy" {
  repository = aws_ecr_repository.gmuxdemo_ecs_ecr_repo.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 2 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 2
      }
    }]
  })
}

resource "aws_cloudwatch_log_group" "gmuxdemo_ecs_container_cloudwatch_loggroup" {
  name = "${var.application}-${var.environment}-cloudwatch-log-group"

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_cloudwatch_log_stream" "gmuxdemo_ecs_container_cloudwatch_logstream" {
  name           = "${var.application}-${var.environment}-cloudwatch-log-stream"
  log_group_name = aws_cloudwatch_log_group.gmuxdemo_ecs_container_cloudwatch_loggroup.name
}

locals {
  ecr_repo  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.application}-${var.environment}"
  log_group = aws_cloudwatch_log_group.gmuxdemo_ecs_container_cloudwatch_loggroup.name
}

resource "aws_iam_role" "gmuxdemo_ecs_task_execution_role" {
  name = "${var.application}-${var.environment}-ecs-taskexecution-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}
resource "aws_iam_role" "gmuxdemo_ecs_task_role" {
  name = "${var.application}-${var.environment}-ecs-task-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "gmuxdemo_ecs_taskexecution_role_policy_attachment" {
  role       = aws_iam_role.gmuxdemo_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_cluster" "gmuxdemo_ecs_cluster" {
  name = "${var.application}-${var.environment}-ecs-cluster"

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_ecs_task_definition" "gmuxdemo_ecs_task_def" {
  family                   = "${var.application}-${var.environment}-gmux-demo-ecs-task-def"
  task_role_arn            = aws_iam_role.gmuxdemo_ecs_task_role.arn
  execution_role_arn       = aws_iam_role.gmuxdemo_ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode(
    [
      {
        environment = [
          {
            name  = "AUDITR_API_KEY"
            value = var.api_key
          },
          {
            name  = "AUDITR_CONFIG_URL"
            value = var.config_url
          }
        ]
        essential = true
        image     = local.ecr_repo
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = local.log_group
            awslogs-region        = var.region
            awslogs-stream-prefix = "/aws/ecs"
          }
        }
        name = "${var.application}-${var.environment}-ecs-task"
        portMappings = [
          {
            containerPort = 8000
            hostPort      = 8000
            protocol      = "tcp"
          }
        ]
      }
    ]
  )

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_ecs_service" "gmuxdemo_ecs_service" {
  name            = "${var.application}-${var.environment}-ecs-service"
  cluster         = aws_ecs_cluster.gmuxdemo_ecs_cluster.id
  task_definition = aws_ecs_task_definition.gmuxdemo_ecs_task_def.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.gmuxdemo_ecs_security_group_egress.id,
      aws_security_group.gmuxdemo_ecs_security_group_ingress.id
    ]
    subnets = [
      aws_subnet.gmuxdemo_ecs_private_subnet1.id,
      aws_subnet.gmuxdemo_ecs_private_subnet2.id
    ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gmuxdemo_alb_target_group.arn
    container_name   = "${var.application}-${var.environment}-ecs-task"
    container_port   = "8000"
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

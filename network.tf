resource "aws_vpc" "gmuxdemo_ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_subnet" "gmuxdemo_ecs_public_subnet1" {
  vpc_id            = aws_vpc.gmuxdemo_ecs_vpc.id
  cidr_block        = "10.0.1.0/25"
  availability_zone = "us-west-2a"

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_subnet" "gmuxdemo_ecs_private_subnet1" {
  vpc_id            = aws_vpc.gmuxdemo_ecs_vpc.id
  cidr_block        = "10.0.2.0/25"
  availability_zone = "us-west-2a"

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_subnet" "gmuxdemo_ecs_public_subnet2" {
  vpc_id            = aws_vpc.gmuxdemo_ecs_vpc.id
  cidr_block        = "10.0.1.128/25"
  availability_zone = "us-west-2b"

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_subnet" "gmuxdemo_ecs_private_subnet2" {
  vpc_id            = aws_vpc.gmuxdemo_ecs_vpc.id
  cidr_block        = "10.0.2.128/25"
  availability_zone = "us-west-2b"

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_internet_gateway" "gmuxdemo_ecs_igw" {
  vpc_id = aws_vpc.gmuxdemo_ecs_vpc.id

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_route_table" "gmuxdemo_ecs_public_route_table" {
  vpc_id = aws_vpc.gmuxdemo_ecs_vpc.id

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_route" "gmuxdemo_ecs_public_route" {
  route_table_id         = aws_route_table.gmuxdemo_ecs_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gmuxdemo_ecs_igw.id
}

resource "aws_route_table_association" "gmuxdemo_ecs_route_table_public_subnet1_association" {
  subnet_id      = aws_subnet.gmuxdemo_ecs_public_subnet1.id
  route_table_id = aws_route_table.gmuxdemo_ecs_public_route_table.id
}

resource "aws_route_table_association" "gmuxdemo_ecs_route_table_public_subnet2_association" {
  subnet_id      = aws_subnet.gmuxdemo_ecs_public_subnet2.id
  route_table_id = aws_route_table.gmuxdemo_ecs_public_route_table.id
}

resource "aws_eip" "gmuxdemo_elastic_ip" {
  vpc = true

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_nat_gateway" "gmuxdemo_ecs_ngw" {
  allocation_id = aws_eip.gmuxdemo_elastic_ip.id
  subnet_id     = aws_subnet.gmuxdemo_ecs_public_subnet1.id

  tags = {
    "Name" = "${var.application}-${var.environment}"
  }
}

resource "aws_route_table" "gmuxdemo_ecs_private_route_table" {
  vpc_id = aws_vpc.gmuxdemo_ecs_vpc.id

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_route" "gmuxdemo_ecs_private_route" {
  route_table_id         = aws_route_table.gmuxdemo_ecs_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.gmuxdemo_ecs_ngw.id
}

resource "aws_route_table_association" "gmuxdemo_ecs_route_table_private_subnet1_association" {
  subnet_id      = aws_subnet.gmuxdemo_ecs_private_subnet1.id
  route_table_id = aws_route_table.gmuxdemo_ecs_private_route_table.id
}

resource "aws_route_table_association" "gmuxdemo_ecs_route_table_private_subnet2_association" {
  subnet_id      = aws_subnet.gmuxdemo_ecs_private_subnet2.id
  route_table_id = aws_route_table.gmuxdemo_ecs_private_route_table.id
}

resource "aws_route_table" "gmuxdemo_vpce_route_table" {
  vpc_id = aws_vpc.gmuxdemo_ecs_vpc.id

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_route" "gmuxdemo_vpce_route" {
  route_table_id         = aws_route_table.gmuxdemo_vpce_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.gmuxdemo_ecs_ngw.id
}

resource "aws_security_group" "gmuxdemo_ecs_security_group_egress" {
  name        = "${var.application}-${var.environment}-ecs-security-group-egress"
  description = "ecs allowed egress ports"
  vpc_id      = aws_vpc.gmuxdemo_ecs_vpc.id

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_security_group_rule" "gmuxdemo_ecs_security_group_rule_egress" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gmuxdemo_ecs_security_group_egress.id
}

resource "aws_security_group" "gmuxdemo_ecs_security_group_ingress" {
  name        = "${var.application}-${var.environment}-ecs-security-group-ingress"
  description = "ecs allowed ingress ports"
  vpc_id      = aws_vpc.gmuxdemo_ecs_vpc.id

  tags = {
    Name = "${var.application}-${var.environment}"
  }
}

resource "aws_security_group_rule" "gmuxdemo_ecs_security_group_rule_ingress" {
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 8000
  to_port           = 8000
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gmuxdemo_ecs_security_group_ingress.id
}

resource "aws_security_group" "gmuxdemo_http_security_group" {
  name        = "${var.application}-${var.environment}-http-security-group"
  description = "HTTP traffic"
  vpc_id      = aws_vpc.gmuxdemo_ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_security_group" "gmuxdemo_https_security_group" {
#   name        = "${var.application}-${var.environment}-https-security-group"
#   description = "HTTPS traffic"
#   vpc_id      = aws_vpc.gmuxdemo_ecs_vpc.id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "TCP"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

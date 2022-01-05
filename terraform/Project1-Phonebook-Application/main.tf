provider "aws" {
  region     = var.aws_region
  #access_key = "xxxxxxxxxxxxxxxxxxxx"
  #secret_key = "xxxxxxxxxxxxxxxxxxxx"
}

locals {
  availability_zones = split(",", var.availability_zones)
}
resource "aws_vpc" "web_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "web_vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone = "us-east-1d"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "tf_test_ig"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "aws_route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.r.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.r.id
}
resource "aws_security_group" "alb_sg" {
  name        = "terraform_example_sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.web_vpc.id
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "lt_sg" {
  name        = "lt_sg"
  description = "launch template security group"
  vpc_id      = aws_vpc.web_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "rds security group"
  vpc_id      = aws_vpc.web_vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.lt_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0.19"
  instance_class       = "db.t2.micro"
  name                 = var.db_name
  username             = var.db_user_name
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.id
  #parameter_group_name = "db.mysql8.0.19"
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "default" {
  name        = "main_subnet_group"
  description = "Our main group of subnets"
  subnet_ids  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_lb" "web_alb" {
  name               = "terraform-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]           


  # The same availability zone as our instances
  #availability_zones = local.availability_zones

  /* listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  } */
}


resource "aws_lb_target_group" "tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.web_vpc.id
  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  protocol          = "HTTP"
  port              = "80"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn

  }
}

resource "aws_autoscaling_policy" "asgp" {
  name                   = "asgp"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60.0
  }
}

resource "aws_autoscaling_group" "web_asg" {
  depends_on = [aws_launch_configuration.web_lt]
  vpc_zone_identifier  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  name                 = "terraform-asg"
  max_size             = var.asg_max
  min_size             = var.asg_min
  desired_capacity     = var.asg_desired
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete         = true
  launch_configuration = aws_launch_configuration.web_lt.name
  #load_balancers       = [aws_lb.web_alb.id]

  /* lifecycle {
    create_before_destroy = true
  } */

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.id
  alb_target_group_arn   = aws_lb_target_group.tg.arn
  #elb                    = aws_lb.web_alb.id
}

data "template_file" "init" {
  template = "${file("userdata.sh")}"

  vars = {
    rds_endpoint = "${aws_db_instance.db.endpoint}"
  }
}
resource "aws_launch_configuration" "web_lt" {
  name          = "terraform-example-lc"
  image_id      = var.aws_ami

  instance_type = var.instance_type
  security_groups = [aws_security_group.lt_sg.id]

  user_data       = data.template_file.init.rendered
 
  key_name        = var.key_name
}


output "elb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "rds_endpoint" {
  value = "${aws_db_instance.db.endpoint}"
}
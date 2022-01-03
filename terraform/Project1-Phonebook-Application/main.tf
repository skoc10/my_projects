provider "aws" {
  region     = var.aws_region
  #access_key = "xxxxxxxxxxxxxxxxxxxx"
  #secret_key = "xxxxxxxxxxxxxxxxxxxx"
}

locals {
  availability_zones = split(",", var.availability_zones)
}
resource "aws_security_group" "alb_sg" {
  name        = "terraform_example_sg"
  description = "Used in the terraform"

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
  #parameter_group_name = "db.mysql8.0.19"
  skip_final_snapshot  = true
}

resource "aws_lb" "web_alb" {
  name               = "terraform-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  # The same availability zone as our instances
  availability_zones = local.availability_zones

 /*  listener {
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
  availability_zones   = local.availability_zones
  name                 = "terraform-asg"
  max_size             = var.asg_max
  min_size             = var.asg_min
  desired_capacity     = var.asg_desired
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete         = true
  launch_configuration = aws_launch_configuration.web_lt.name
  load_balancers       = [aws_elb.web_elb.name]


}

/* data "template_cloudinit_config" "config" {
  #gzip          = false
  base64_encode = true
  part {
    #filename     = "init.cfg"
    content_type = "text/x-shellscript"
    #content = "${data.template_file.init.rendered}"
    content = templatefile("${path.root}/userdata.sh}",
      {
        rds_endpoint = "${aws_db_instance.db.endpoint}" 
      }
    )
  }
  
} */

resource "aws_launch_configuration" "web_lt" {
  name          = "terraform-example-lc"
  image_id      = var.aws_ami

  instance_type = var.instance_type

  # Security group
  security_groups = [aws_security_group.lt_sg.id]
  user_data       = file("userdata.sh")
  #user_data       = data.template_cloudinit_config.config.renderedserdata.sh
  key_name        = var.key_name
}


output "elb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "rds_endpoint" {
  value = "${aws_db_instance.db.endpoint}"
}
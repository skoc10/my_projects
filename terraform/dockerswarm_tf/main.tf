provider "aws" {
  region = "us-east-1"
  //  access_key = ""
  //  secret_key = ""
  //  If you have entered your credentials in AWS CLI before, you do not need to use these arguments.
}

resource "aws_instance" "swarm_manager" {
  ami             = "ami-04505e74c0741db8d"
  instance_type   = "t2.micro"
  security_groups = ["docker-swarm-sec-gr"]
  key_name        = "key"
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y docker.io",
      "sudo docker swarm init",
      "sudo docker swarm join-token --quiet worker > /home/ubuntu/token",
    ]
    connection {
      type        = "ssh"
      private_key = "your pem file"
      user        = "ubuntu"
      timeout     = "1m"
    }
  }
}

resource "aws_instance" "swarm_worker" {
  count           = 2
  ami             = "ami-04505e74c0741db8d"
  instance_type   = "t2.micro"
  security_groups = ["docker-swarm-sec-gr"]
  key_name        = "key"
  associate_public_ip_address = true


  provisioner "file" {
    source = "keys/key.pem"
    destination = "/home/ubuntu/key.pem"
    connection {
      type        = "ssh"
      private_key = "key"
      user        = "ubuntu"
      timeout     = "1m"
    }
  }


  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y docker.io",
      "sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i key.pem ubuntu@${aws_instance.swarm_manager.private_ip}:/home/ubuntu/token .",
      "sudo chmod 400 /home/ubuntu/key.pem",
      "sudo docker swarm join --token $(cat /home/ubuntu/token) ${aws_instance.swarm_manager.private_ip}:2377"
    ]


    connection {
      type        = "ssh"
      private_key = "key"
      user        = "ubuntu"
      timeout     = "1m"
    }
  }
}

resource "aws_security_group" "tf-docker-sec-gr" {
  name = "docker-swarm-sec-gr"
  tags = {
    Name = "docker-swarm-sec-group"
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2377
    protocol    = "tcp"
    to_port     = 2377
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
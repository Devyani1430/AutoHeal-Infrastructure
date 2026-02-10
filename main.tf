provider "aws" {
  region = "us-west-1"
}

# Create VPC

resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "Custom-VPC"
  }
}

# Create Public Subnet 1

resource "aws_subnet" "public-subnet1" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = var.public-cidr1
  availability_zone = var.AZ1
  tags = {
    Name = "Public-subnet-1"
  }
}

# Create Public Subnet 2

resource "aws_subnet" "public-subnet2" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = var.public-cidr2
  availability_zone = var.AZ2
  tags = {
    Name = "Public-subnet-2"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "My-IGW" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "IGW"
  }
}

#Create default route table
resource "aws_default_route_table" "main-RT" {
  default_route_table_id = aws_vpc.my-vpc.default_route_table_id
  tags = {
    Name = "main-RT"
  }
}

# Add route in main-RT

resource "aws_route" "aws_route" {
  route_table_id = aws_default_route_table.main-RT.id
  destination_cidr_block = var.IGW-cidr
  gateway_id = aws_internet_gateway.My-IGW.id
}

# Create security group

resource "aws_security_group" "Custom-SG" {
  vpc_id = aws_vpc.my-vpc.id

  ingress = {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Lunch Template

resource "aws_launch_template" "app_template" {
  name = "app-template"
  image_id = "ami-0623300d1b7caee89"
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.Custom-SG.id]
  }

  user_data = base64encode(<<-EOF
            #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from terraform" > /var/www/html/index.html
            EOF
          )
}

# Configure Auto Scaling Group

resource "aws_autoscaling_group" "app-asg" {
    vpc_zone_identifier = [aws_subnet.public-subnet1.id]
    desired_capacity = 2
    max_size = 3
    min_size = 1

    launch_template {
      id = aws_launch_template.app_template.id
      version = "$Latest"
    }

    health_check_type = "EC2"
    health_check_grace_period = 300
}

# Attach Load Balancer

resource "aws_lb" "app-lb" {
  name = "App-Load-Balancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.Custom-SG.id]
  subnets = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]

}

# Target Group

resource "aws_lb_target_group" "app-tg" {
  name = "App-Target-Group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.my-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# Listener Rules

resource "aws_lb_listener" "app-listener" {
  load_balancer_arn = aws_lb.app-lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app-tg.arn
  }
  
}
variable "s3_bootstrap_bucket_name" {
  
}

variable "vpc_id" {
  
}

variable "public_subnet_id" {
  
}

variable "private_subnet_id" {
  
}

variable "public_subnet_cidr" {
  
}

variable "ec2_ssh_key_name" {
  
}

variable "default_route_table_id" {
  
}

variable "instance_profile_id" {
  
}

variable "rds_host" {
  
}

data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners = ["amazon"]

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

data "aws_ami" "nat_community_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn-ami-vpc-nat-hvm*"]
  }
}

data "aws_availability_zones" "all" {}

resource "aws_security_group" "allow-ssh-and-http" {
  name = "allow-ssh-and-http"
  vpc_id = "${var.vpc_id}"

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "ssh from anywhere"
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }

  ingress {
    description      = "http from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]
  }

  ingress {
    description      = "https from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow-ssh-and-http-private" {
  name = "allow-ssh-and-http-private"
  vpc_id = "${var.vpc_id}"

  ingress {
    cidr_blocks = [ "10.0.1.0/24" ]
    description = "ssh from public subnet"
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }

  ingress {
    description      = "http from public subnet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      =  ["${var.public_subnet_cidr}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow-elb-access" {
  name = "allow-elb-access"
  vpc_id = "${var.vpc_id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["${var.public_subnet_cidr}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "calc-public" {
  name = "calc-elb"
  subnets = [var.public_subnet_id]
  security_groups = ["${aws_security_group.allow-elb-access.id}"]

  health_check {
    target              = "HTTP:80/actuator/health"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
}

resource "aws_launch_configuration" "java8-launch-configuration" {
  instance_type = "t2.micro"
  image_id = "${data.aws_ami.amazon-linux-2.id}"
  security_groups = ["${aws_security_group.allow-ssh-and-http.id}"]
  key_name = "${var.ec2_ssh_key_name}"
  iam_instance_profile = "${var.instance_profile_id}"

  user_data = <<-EOF
              #!/bin/bash
              set -x
              set -e
              sudo yum install java-1.8.0-openjdk -y
              cd /opt
              aws s3 cp s3://${var.s3_bootstrap_bucket_name}/calc-0.0.2-SNAPSHOT.jar .
              java -jar calc-0.0.2-SNAPSHOT.jar
              EOF
} 

resource "aws_autoscaling_group" "calc-instances" {
  name = "calc-instances-2"
  launch_configuration = "${aws_launch_configuration.java8-launch-configuration.id}"
  min_size = 2
  max_size = 2
  load_balancers = [aws_elb.calc-public.name]
  health_check_type = "ELB"
  vpc_zone_identifier = [var.public_subnet_id]
}

resource "aws_instance" "nat-instance" {
  ami = "${data.aws_ami.nat_community_ami.id}"
  
  instance_type = "t2.micro"
  subnet_id = var.public_subnet_id
  security_groups = ["${aws_security_group.allow-ssh-and-http.id}"]
  source_dest_check = false
  key_name = "${var.ec2_ssh_key_name}"

  tags = {
    "name" = "nat-instance"
  }
}

resource "aws_instance" "persistor-instance" {
  ami = "${data.aws_ami.amazon-linux-2.id}"
  instance_type = "t2.micro"
  subnet_id = var.private_subnet_id
  security_groups = [ "${aws_security_group.allow-ssh-and-http-private.id}" ]
  iam_instance_profile = "${var.instance_profile_id}"
  key_name = "${var.ec2_ssh_key_name}"
  tags = {
    "name" = "persistor-instance-2"
  }


  user_data = <<-EOF
              #!/bin/bash
              export RDS_HOST=${var.rds_host}
              echo $RDS_HOST
              sudo yum install java-1.8.0-openjdk -y
              cd /opt
              aws s3 cp s3://${var.s3_bootstrap_bucket_name}/persist3-0.0.1-SNAPSHOT.jar .
              java -jar persist3-0.0.1-SNAPSHOT.jar
              EOF
}


resource "aws_default_route_table" "defaut-route-table" {
  default_route_table_id = "${var.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = aws_instance.nat-instance.id
  }
}

output "elb-dns-name" {
  value = aws_elb.calc-public.dns_name
}
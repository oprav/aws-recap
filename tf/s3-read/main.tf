provider "aws" {
  region = "us-west-2"
}

resource "aws_security_group" "allow_ssh_and_http" {
  name        = "allow_ssh_and_http"
  description = "Allow to ssh into machine and do http requests"

  ingress {
    description      = "ssh from anywhere x_x"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]
  }

  ingress {
    description      = "http from anywhere"
    from_port        = 80
    to_port          = 80
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

data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners = ["amazon"]

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_instance" "instance-with-injected-s3-file" {
  ami                         = "${data.aws_ami.amazon-linux-2.id}"
  instance_type               = "t2.micro"
  iam_instance_profile        = "${aws_iam_instance_profile.ec2_s3_reader_profile.id}"
  key_name                    = "${var.ec2_ssh_key_name}"
  vpc_security_group_ids      = ["${aws_security_group.allow_ssh_and_http.id}"]
  user_data                   = <<EOF
    #! /bin/bash
    cd /
    aws s3 cp s3://${var.s3_bucket_name}/ . --recursive
    EOF
}
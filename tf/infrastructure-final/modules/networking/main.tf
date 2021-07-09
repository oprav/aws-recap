

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "name" = "public-and-private-subnets"
  }
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    "name" = "main-igw"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    "name" = "public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2a"
  tags = {
    "name" = "private-subnet"
  }
}

resource "aws_subnet" "private-rds-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2b"
  tags = {
    "name" = "private-rds-subnet"
  }
}

resource "aws_route_table" "public-subnet-route-table" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    "name" = "public-subnet-route-table"
  }
}

resource "aws_route" "public-igw-route" {
  route_table_id = "${aws_route_table.public-subnet-route-table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.main-igw.id}"
}

resource "aws_route_table_association" "public-subnet-route-table-association" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.public-subnet-route-table.id}"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public-subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private-subnet.id
}

output "private_rds_subnet_id" {
  value = aws_subnet.private-rds-subnet.id
}

output "public_subnet_cidr" {
  value = aws_subnet.public-subnet.cidr_block
}

output "default_route_table_id" {
  value = aws_vpc.main.default_route_table_id
}

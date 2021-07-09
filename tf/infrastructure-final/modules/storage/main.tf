variable "dynamodb_table_name" {
  
}

variable "vpc_id" {
  
}

variable "db_subnet1_id" {
  
}

variable "db_subnet2_id" {
  
}

resource "aws_dynamodb_table" "calc-public" {
  name           = "${var.dynamodb_table_name}"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "UserName"

  attribute {
    name = "UserName"
    type = "S"
  }

}

resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "db-subnet_group"
  subnet_ids = [var.db_subnet1_id, var.db_subnet2_id]
}

resource "aws_security_group" "rds-security-group" {
  name   = "calc-rds-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "calc-persistor-db" {
  identifier             = "calc-persistor-db"
  name                   = "EduLohikaTrainingAwsRds"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "12.5"
  username               = "rootuser"
  password               = ""
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-group.name
  
  vpc_security_group_ids = [aws_security_group.rds-security-group.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

output "rds_hostname" {
  value  = aws_db_instance.calc-persistor-db.address
}

output "created_dynamodb_table_name" {
  value = aws_dynamodb_table.calc-public.name
}
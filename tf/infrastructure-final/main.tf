provider "aws" {
  region = "us-west-2"
}

module "networking" {
  source = "./modules/networking"
}

module "messaging" {
  source = "./modules/messaging"
  sns_topic_name = "edu-lohika-training-aws-sns-topic"
  sqs_queue_name = "edu-lohika-training-aws-sqs-queue"
}

module "storage" {
  source = "./modules/storage"
  dynamodb_table_name = "edu-lohika-training-aws-dynamodb"
  vpc_id ="${module.networking.vpc_id}"
  db_subnet1_id = "${module.networking.private_subnet_id}"
  db_subnet2_id = "${module.networking.private_rds_subnet_id}"

}

module "iam" {
  source = "./modules/iam"
  target_s3_bucket_name = "oprav-hw"
  target_dynamodb_table_name = "${module.storage.created_dynamodb_table_name}"
  target_sns_topic_name = "${module.messaging.created_sns_topic_name}"
  target_sqs_queue_name = "${module.messaging.created_sqs_queue_name}"
}


module "instances" {
  source = "./modules/instances"
  s3_bootstrap_bucket_name = "oprav-hw"
  ec2_ssh_key_name = "instance key"
  vpc_id = "${module.networking.vpc_id}"
  public_subnet_id = "${module.networking.public_subnet_id}"
  private_subnet_id = "${module.networking.private_subnet_id}"
  public_subnet_cidr = "${module.networking.public_subnet_cidr}"
  default_route_table_id = "${module.networking.default_route_table_id}"
  instance_profile_id = "${module.iam.s3_reader_profile_id}"
  rds_host = "${module.storage.rds_hostname}"
}
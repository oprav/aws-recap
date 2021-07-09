variable "sns_topic_name" {
  
}

variable "sqs_queue_name" {
  
}

resource "aws_sns_topic" "edu-lohika-training-aws-sns-topic" {
  name = "${var.sns_topic_name}"
}

resource "aws_sqs_queue" "edu-lohika-training-aws-sqs-queue" {
  name = "${var.sqs_queue_name}"
}

output "created_sns_topic_name" {
  value = aws_sns_topic.edu-lohika-training-aws-sns-topic.name
}

output "created_sqs_queue_name" {
  value = aws_sqs_queue.edu-lohika-training-aws-sqs-queue.name
}
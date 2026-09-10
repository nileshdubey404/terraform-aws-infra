terraform {
  backend "s3" {
    bucket = "aws-infra-remote-backend-tfstate-bucket-123456"
    key    = "terraform-aws-infra/terraform.tfstate"
    region = "ap-south-1"
  }
}

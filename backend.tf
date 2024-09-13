terraform {
  backend "s3" {
    bucket         = "bimaplan-serverless-code7803"
    key            = "terraform.tfstate"
    region         = var.aws_region
  }
}

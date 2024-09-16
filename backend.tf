terraform {
  backend "s3" {
    bucket         = "nishank-bimaplan-783"
    key            = "terraform.tfstate"
    region         = var.aws_region
  }
}

terraform {
  backend "s3" {
    # Replace these with your actual details
    bucket         = "my-terraform-state-bucket"
    key            = "remote-infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

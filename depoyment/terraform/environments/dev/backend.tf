terraform {
  backend "s3" {
    bucket       = "tfstate-dev-bucket-e7dqlf6b"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

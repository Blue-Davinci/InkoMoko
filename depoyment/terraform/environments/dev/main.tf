provider "aws" {
  region = var.bucket_region
}

module "nat_gateway" {
  source = "../../modules/networking"

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  vpc_cidr        = var.vpc_cidr
  tags            = var.tags
}

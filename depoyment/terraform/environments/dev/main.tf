provider "aws" {
  region = var.bucket_region
}

module "networking" {
  source = "../../modules/networking"

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  vpc_cidr        = var.vpc_cidr
  tags            = var.tags
}

module "alb" {
  source = "../../modules/alb"

  alb_name            = "my-alb-${var.environment}"
  subnet_ids          = module.networking.public_subnet_ids_list
  vpc_id              = module.networking.vpc_id
  tags                = var.tags
  enable_alb_deletion = var.enable_alb_deletion
}

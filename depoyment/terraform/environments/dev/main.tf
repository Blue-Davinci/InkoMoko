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
  enable_https        = false # Set to false for HTTP-only mode initially
}

module "compute" {
  source = "../../modules/compute"

  vpc_id                         = module.networking.vpc_id
  vpc_cidr                       = var.vpc_cidr
  tags                           = var.tags
  alb_sg_id                      = module.alb.alb_security_group_id
  instance_prefix                = "my-instance-${var.environment}"
  instance_ami                   = var.instance_ami
  instance_type                  = var.instance_type
  private_subnet_ids             = module.networking.private_subnet_ids_list
  target_group_arn               = module.alb.target_group_arn
  target_tracking_resource_label = module.alb.target_group_resource_label
  docker_image_url               = var.docker_image_url
}

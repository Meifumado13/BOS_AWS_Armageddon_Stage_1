provider "aws" {
  alias  = "norcal"
  region = var.norcal_config.region
}

module "norcal_network" {
  source = "./modules/network"

  region              = var.norcal_config.region
  name                = var.norcal_config.name
  vpc_cidr            = var.norcal_config.vpc_cidr
  public_subnet_cidr  = var.norcal_config.public_subnet_cidr
  private_subnet_cidr = var.norcal_config.private_subnet_cidr
  tgw_id              = module.norcal_tgw_branch.tgw_id
}

module "norcal_frontend" {
  source = "./modules/frontend"

  region            = var.norcal_config.region
  name              = var.norcal_config.name
  vpc_id            = module.norcal_network.vpc_id
  public_subnet_ids = module.norcal_network.public_subnet_ids
  target_group_arn  = module.norcal_backend.target_group_arn
}

module "norcal_backend" {
  source = "./modules/backend"

  region                = var.norcal_config.region
  name                  = var.norcal_config.name
  vpc_id                = module.norcal_network.vpc_id
  private_subnet_ids    = module.norcal_network.private_subnet_ids
  frontend_sg_id        = module.norcal_frontend.frontend_sg_id
  backend_instance_type = var.backend_config.backend_instance_type[0]
  desired_capacity      = var.backend_config.desired_capacity
  scaling_range         = var.backend_config.scaling_range
  user_data             = var.backend_config.user_data
}

module "norcal_tgw_branch" {
  source = "./modules/tgw_branch"

  providers = {
    aws.default = aws.norcal
    aws.tokyo   = aws.tokyo
  }

  region             = var.norcal_config.region
  name               = var.norcal_config.name
  vpc_id             = module.norcal_network.vpc_id
  private_subnet_ids = module.norcal_network.private_subnet_ids
  peer_tgw_id        = module.tgw_hq.tgw_id
  vpc_cidr           = var.norcal_config.vpc_cidr
}

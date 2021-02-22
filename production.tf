module "production" {
  source = "./modules/networking"
  /*
  region              = var.region
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  #az   = var.az
*/
}
/*
output "vpc-id" {
  value = module.modules.networking.vpc_id
}
*/

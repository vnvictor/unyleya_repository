terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "local" { path = "./statefiles/terraform.tfstate" }
}

provider "aws" {
  region = "sa-east-1"
}

locals {
  region               = "sa-east-1"
  azone                = "${local.region}a"
  igw_cidr             = "0.0.0.0/0"
  vpc_cidr             = "10.0.0.0/20"
  subnet_cidr          = "10.0.1.0/24"
  vpc_instance_tenancy = "default"
}

module "vpc" {
  source           = "./modules/vpc"
  vpc_cidr_block   = local.vpc_cidr
  instance_tenancy = local.vpc_instance_tenancy
}

module "subnet_public" {
  depends_on = [
    module.vpc
  ]
  source                   = "./modules/subnets"
  vpc_id                   = module.vpc.vpc_id
  azone                    = local.azone
  subnets_cidr_public_list = ["${local.subnet_cidr}"]
  igw_cidr_block           = local.igw_cidr
  igw_id                   = module.vpc.internet_gateway_id
}

module "secgroup" {
  depends_on = [
    module.vpc
  ]
  source         = "./modules/security/security_groups"
  sec_group_name = "windows_sg"
  vpc_id         = module.vpc.vpc_id
}

module "secgroup_ingress" {
  depends_on = [
    module.secgroup
  ]
  source = "./modules/security/security_groups_rules_ingress"
  #allow incoming traffic from ports below
  ingress_port        = ["80", "3389"]
  protocol            = "TCP"
  allowed_cidr_blocks = ["${local.igw_cidr}"]
  sec_group_id        = module.secgroup.security_group_id
}

module "secgroup_egress" {
  depends_on = [
    module.secgroup
  ]
  source              = "./modules/security/security_groups_rules_egress"
  allowed_cidr_blocks = ["${local.igw_cidr}"]
  sec_group_id        = module.secgroup.security_group_id
}

module "keys_pair" {
  source = "./modules/tks_key"
}

module "windows_instance" {
  depends_on = [
    module.vpc,
    module.subnet_public
  ]
  source                = "./modules/instance"
  windows_instance_type = "t2.micro"
  
  public_subnet_id      = module.subnet_public.public_subnets_id[0]
  security_groups_ids   = ["${module.secgroup.security_group_id}"]
  windows_instance_name = "my_server"
  is_public_ip          = true
  key_pair_name         = module.keys_pair.key_pair_name
  root_block_device = {
    windows_root_volume_size = 30
    windows_root_volume_type = "gp2"
  }
}

# 
terraform {
  required_version = ">= 1.5.0"
  backend "local" {} # troque para S3/Dynamo se quiser remoto
}

provider "aws" {
  region = var.region
  # profile = var.profile
}

module "vpc" {
  source = "../../vpc-ipam"

  environment_name   = var.environment_name
  ipam_pool_id       = var.ipam_pool_id
  vpc_netmask_length = var.vpc_netmask_length
  az_count           = var.az_count
  subnet_newbits     = var.subnet_newbits

  # TGW
  enable_tgw         = var.enable_tgw
  transit_gateway_id = var.transit_gateway_id

  # SG intra-VPC
  enable_intra_vpc_sg = var.enable_intra_vpc_sg
  intra_vpc_tcp_ports = var.intra_vpc_tcp_ports

  # NACL
  enable_default_nacl  = var.enable_default_nacl
  default_nacl_ingress = var.default_nacl_ingress
  default_nacl_egress  = var.default_nacl_egress

  # PHZ/Resolver (deixa comentado se não for usar)
  # enable_phz                               = var.enable_phz
  # dns_private_zone                         = var.dns_private_zone
  # child_domain_resolver_rule_id            = var.child_domain_resolver_rule_id
  # aws_dns_resolution                       = var.aws_dns_resolution
  # on_prem_domain_resolver_rule_id          = var.on_prem_domain_resolver_rule_id
  # on_prem_legacy_cloud_domain_resolver_rule_id = var.on_prem_legacy_cloud_domain_resolver_rule_id

  # FLOW LOGS -> S3 (IMPORTANTE)
  enable_flow_logs                   = var.enable_flow_logs
  flow_logs_bucket_name              = var.flow_logs_bucket_name
  flow_logs_prefix                   = var.flow_logs_prefix
  flow_logs_file_format              = var.flow_logs_file_format
  flow_logs_per_hour_partition       = var.flow_logs_per_hour_partition
  flow_logs_hive_compatible          = var.flow_logs_hive_compatible
  flow_logs_max_aggregation_interval = var.flow_logs_max_aggregation_interval

  tags = {
    Project = "baseline"
    Owner   = "network"
  }
}

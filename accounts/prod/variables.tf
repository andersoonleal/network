variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Região do provider AWS"
}

# envs/dev/variables.tf

variable "environment_name" {
  type        = string
  default     = "Prod"
  description = "Friendly name do ambiente"
}

variable "ipam_pool_id" {
  type        = string
  description = "Pool ID do IPAM (ou vazio se for pegar via SSM/local)"
  default     = ""
}

variable "vpc_netmask_length" {
  type    = number
  default = 22
}

variable "az_count" {
  type    = number
  default = 3
}

variable "subnet_newbits" {
  type    = number
  default = 2
}

# TGW
variable "enable_tgw" {
  type    = bool
  default = false
}
variable "transit_gateway_id" {
  type    = string
  default = ""
}

# SG intra-VPC
variable "enable_intra_vpc_sg" {
  type    = bool
  default = true
}
variable "intra_vpc_tcp_ports" {
  type    = list(number)
  default = [22, 443, 5432]
}

# NACL
variable "enable_default_nacl" {
  type    = bool
  default = false
}
variable "default_nacl_ingress" {
  type    = list(any)
  default = []
}
variable "default_nacl_egress" {
  type    = list(any)
  default = []
}

# PHZ/Resolver
variable "enable_phz" {
  type    = bool
  default = false
}
variable "dns_private_zone" {
  type    = string
  default = ""
}
variable "aws_dns_resolution" {
  type    = string
  default = ""
}
variable "on_prem_domain_resolver_rule_id" {
  type    = string
  default = ""
}
variable "on_prem_legacy_cloud_domain_resolver_rule_id" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Flow Logs
variable "enable_flow_logs" {
  type    = bool
  default = true
}

variable "flow_logs_bucket_name" {
  type        = string
  description = "Nome do bucket S3 que receberá os VPC Flow Logs"
  default     = "meu-bucket-vpc-flow-logs" # ajusta pro teu bucket real
}

variable "flow_logs_prefix" {
  type    = string
  default = ""
}

variable "flow_logs_file_format" {
  type    = string
  default = "parquet" # "plain-text" ou "parquet"
}

variable "flow_logs_per_hour_partition" {
  type    = bool
  default = true
}

variable "flow_logs_hive_compatible" {
  type    = bool
  default = true
}

variable "flow_logs_max_aggregation_interval" {
  type    = number
  default = 60 # segundos (60 ou 600)
}

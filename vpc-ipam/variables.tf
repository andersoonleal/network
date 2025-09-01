variable "environment_name" {
  description = "VPC-Delivery"
  type        = string
  default     = "Dev"
  validation {
    condition     = contains(["Prod", "Homolog", "Lab", "Dev"], var.environment_name)
    error_message = "Use Prod, Homolog, Lab ou Dev"
  }
}

variable "ipam_pool_id" {
  description = "ID da IPAM Pool (compartilhada com esta conta via RAM)"
  type        = string
}

variable "vpc_netmask_length" {
  description = "Tamanho do bloco da VPC a ser alocado pelo IPAM (ex.: 22 => /22)"
  type        = number
  default     = 22
}

variable "az_count" {
  description = "Quantidade de AZs a usar"
  type        = number
  default     = 3
}

variable "subnet_newbits" {
  description = "Bits para derivar subnets a partir do CIDR da VPC (ex.: 2 => /24 a partir de /22)"
  type        = number
  default     = 2
}

# TGW (opcional)
variable "enable_tgw" {
  type    = bool
  default = false
}

variable "transit_gateway_id" {
  type    = string
  default = ""
}

# SG intra-VPC (opcional)
variable "enable_intra_vpc_sg" {
  type    = bool
  default = true
}

variable "intra_vpc_tcp_ports" {
  description = "Portas TCP liberadas dentro do bloco da VPC"
  type        = list(number)
  default     = [443, 2049, 5432, 1768, 1414, 1364, 1363, 22, 8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089, 9990, 9080, 9081, 9082, 444]
}

# NACL default (opcional)
variable "enable_default_nacl" {
  type    = bool
  default = false
}

variable "default_nacl_ingress" {
  type = list(object({
    action          = string
    cidr_block      = string
    from_port       = number
    to_port         = number
    protocol        = string
    rule_no         = number
    icmp_code       = optional(number)
    icmp_type       = optional(number)
    ipv6_cidr_block = optional(string)
  }))
  default = []
}

variable "default_nacl_egress" {
  type = list(object({
    action          = string
    cidr_block      = string
    from_port       = number
    to_port         = number
    protocol        = string
    rule_no         = number
    icmp_code       = optional(number)
    icmp_type       = optional(number)
    ipv6_cidr_block = optional(string)
  }))
  default = []
}

# PHZ/Resolver (opcional)
variable "enable_phz" {
  type    = bool
  default = false
}

variable "dns_private_zone" {
  type    = string
  default = ""
}

variable "child_domain_resolver_rule_id" {
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
  description = "Tags padrão"
  type        = map(string)
  default     = {}
}

# Flow Logs (S3)
variable "enable_flow_logs" {
  type    = bool
  default = true
}

variable "flow_logs_bucket_name" {
  type        = string
  description = "Nome do bucket S3 que receberá os VPC Flow Logs"
}

# Opcional: se vazio, calculo automático AWSLogs/<account_id>/vpcflowlogs/<region>
variable "flow_logs_prefix" {
  type    = string
  default = ""
  validation {
    condition     = !can(regex("^AWSLogs(/|$)", var.flow_logs_prefix))
    error_message = "Não use prefixo começando com 'AWSLogs/'. Deixe vazio para o padrão da AWS ou use outro caminho."
  }
}

variable "flow_logs_file_format" {
  type    = string
  default = "parquet" # "plain-text" ou "parquet"
  validation {
    condition     = contains(["plain-text", "parquet"], var.flow_logs_file_format)
    error_message = "flow_logs_file_format deve ser plain-text ou parquet."
  }
}

variable "flow_logs_per_hour_partition" {
  type    = bool
  default = true
}

variable "flow_logs_hive_compatible" {
  type    = bool
  default = true
}

# 60 ou 600 segundos
variable "flow_logs_max_aggregation_interval" {
  type    = number
  default = 60
}

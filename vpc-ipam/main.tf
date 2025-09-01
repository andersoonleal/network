# terraform {
#   required_version = ">= 1.5.0"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 5.40"
#     }
#   }
# }

# # AZs
# data "aws_availability_zones" "this" {
#   state = "available"
# }

# locals {
#   azs = slice(data.aws_availability_zones.this.names, 0, var.az_count)

#   # Mapa de subnets privadas derivadas do bloco da VPC (determinístico)
#   private_subnets = {
#     for idx, az in local.azs :
#     format("private-%02d", idx + 1) => {
#       az     = az
#       newbits = var.subnet_newbits
#       netnum  = idx
#     }
#   }
# }

# # VPC pede o bloco direto ao IPAM (sem preview/alloc separado)
# resource "aws_vpc" "this" {
#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   ipv4_ipam_pool_id   = var.ipam_pool_id
#   ipv4_netmask_length = var.vpc_netmask_length

#   tags = merge(var.tags, {
#     Name = "${var.environment_name}-vpc"
#   })
# }

# # Subnets privadas
# resource "aws_subnet" "private" {
#   for_each                = local.private_subnets
#   vpc_id                  = aws_vpc.this.id
#   availability_zone       = each.value.az
#   map_public_ip_on_launch = false
#   cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, each.value.newbits, each.value.netnum)

#   tags = merge(var.tags, {
#     Name    = "${var.environment_name}-${each.key}-${each.value.az}"
#     Network = "Private"
#     Tier    = "private"
#   })
# }

# # Route table privada + associações
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.this.id
#   tags   = merge(var.tags, { Name = "${var.environment_name}-rt" })
# }

# resource "aws_route_table_association" "private" {
#   for_each       = aws_subnet.private
#   subnet_id      = each.value.id
#   route_table_id = aws_route_table.private.id
# }

# # Rota padrão para TGW (opcional)
# resource "aws_ec2_transit_gateway_vpc_attachment" "tgw" {
#   count              = var.enable_tgw ? 1 : 0
#   vpc_id             = aws_vpc.this.id
#   subnet_ids         = [for s in aws_subnet.private : s.id]
#   transit_gateway_id = var.transit_gateway_id

#   tags = merge(var.tags, {
#     Name = "${var.environment_name}-tgw-attachment"
#   })
# }

# resource "aws_route" "default_to_tgw" {
#   count                   = var.enable_tgw ? 1 : 0
#   route_table_id          = aws_route_table.private.id
#   destination_cidr_block  = "0.0.0.0/0"
#   transit_gateway_id      = var.transit_gateway_id
#   depends_on              = [aws_ec2_transit_gateway_vpc_attachment.tgw]
# }

# # SG intra-VPC (opcional)
# resource "aws_security_group" "acesso_intra_vpc_v2" {
#   count       = var.enable_intra_vpc_sg ? 1 : 0
#   name        = "acesso intra-vpc-v2"
#   description = "Acessos internos dentro do bloco da VPC"
#   vpc_id      = aws_vpc.this.id

#   dynamic "ingress" {
#     for_each = toset(var.intra_vpc_tcp_ports)
#     content {
#       from_port   = ingress.value
#       to_port     = ingress.value
#       protocol    = "tcp"
#       cidr_blocks = [aws_vpc.this.cidr_block]
#     }
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [aws_vpc.this.cidr_block]
#   }

#   tags = merge(var.tags, { Name = "acesso intra-vpc-v2" })

# }

# # NACL default custom (opcional) — cuidado com drift se AWS Config gerencia
# resource "aws_default_network_acl" "custom" {
#   count                   = var.enable_default_nacl ? 1 : 0
#   default_network_acl_id  = aws_vpc.this.default_network_acl_id
#   subnet_ids              = [for s in aws_subnet.private : s.id]

#   dynamic "egress" {
#     for_each = var.default_nacl_egress
#     content {
#       action          = egress.value.action
#       cidr_block      = egress.value.cidr_block
#       from_port       = egress.value.from_port
#       to_port         = egress.value.to_port
#       protocol        = egress.value.protocol
#       rule_no         = egress.value.rule_no
#       icmp_code       = try(egress.value.icmp_code, 0)
#       icmp_type       = try(egress.value.icmp_type, 0)
#       ipv6_cidr_block = try(egress.value.ipv6_cidr_block, null)
#     }
#   }

#   dynamic "ingress" {
#     for_each = var.default_nacl_ingress
#     content {
#       action          = ingress.value.action
#       cidr_block      = ingress.value.cidr_block
#       from_port       = ingress.value.from_port
#       to_port         = ingress.value.to_port
#       protocol        = ingress.value.protocol
#       rule_no         = ingress.value.rule_no
#       icmp_code       = try(ingress.value.icmp_code, 0)
#       icmp_type       = try(ingress.value.icmp_type, 0)
#       ipv6_cidr_block = try(ingress.value.ipv6_cidr_block, null)
#     }
#   }

#   tags = merge(var.tags, { Name = "${var.environment_name}-default-nacl" })
# }

# # Private Hosted Zone + Resolver Rules (opcional)
# resource "aws_route53_zone" "phz" {
#   count = var.enable_phz ? 1 : 0
#   name  = "${var.dns_private_zone}.cip-cloud.local"

#   vpc { vpc_id = aws_vpc.this.id }

#   tags = merge(var.tags, { Name = "PrivateHostedZone" })
# }

# resource "aws_route53_resolver_rule_association" "child" {
#   count            = var.enable_phz && var.child_domain_resolver_rule_id != "" ? 1 : 0
#   name             = "RuleAssociationforChildDomains"
#   resolver_rule_id = var.child_domain_resolver_rule_id
#   vpc_id           = aws_vpc.this.id
# }

# resource "aws_route53_resolver_rule_association" "aws_dns" {
#   count            = var.enable_phz && var.aws_dns_resolution != "" ? 1 : 0
#   name             = "RuleAssociationforAWS"
#   resolver_rule_id = var.aws_dns_resolution
#   vpc_id           = aws_vpc.this.id
# }

# resource "aws_route53_resolver_rule_association" "onprem" {
#   count            = var.enable_phz && var.on_prem_domain_resolver_rule_id != "" ? 1 : 0
#   name             = "RuleAssociationOnPremiseDomains"
#   resolver_rule_id = var.on_prem_domain_resolver_rule_id
#   vpc_id           = aws_vpc.this.id
# }

# resource "aws_route53_resolver_rule_association" "onprem_legacy" {
#   count            = var.enable_phz && var.on_prem_legacy_cloud_domain_resolver_rule_id != "" ? 1 : 0
#   name             = "RuleAssociationOnPremiseLegacyCloudDomains"
#   resolver_rule_id = var.on_prem_legacy_cloud_domain_resolver_rule_id
#   vpc_id           = aws_vpc.this.id
# }

# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# locals {
#   flow_logs_prefix_effective = (
#     var.flow_logs_prefix != "" ?
#     var.flow_logs_prefix :
#     "AWSLogs/${data.aws_caller_identity.current.account_id}/vpcflowlogs/${data.aws_region.current.id}"
#   )
# }

# # Usa exatamente o prefixo informado (ou vazio)
# locals {
#   flow_logs_prefix_effective = trim(var.flow_logs_prefix)
# }

# # Monta o ARN final do destino S3 sem "AWSLogs/..."
# # - se prefixo vazio: arn:aws:s3:::<bucket>
# # - se prefixo não-vazio: arn:aws:s3:::<bucket>/<prefix>
# locals {
#   flow_logs_destination_arn = local.flow_logs_prefix_effective != "" ?
#     format("arn:aws:s3:::%s/%s", var.flow_logs_bucket_name, local.flow_logs_prefix_effective) :
#     format("arn:aws:s3:::%s",      var.flow_logs_bucket_name)
# }


terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }
  }
}

# AZs
data "aws_availability_zones" "this" {
  state = "available"
}

# Identidade/Região (usados em tags/diagnóstico, se quiser)
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------
# Locals de VPC/Subnets
# ---------------------------
locals {
  azs = slice(data.aws_availability_zones.this.names, 0, var.az_count)

  # Mapa determinístico de subnets privadas
  private_subnets = {
    for idx, az in local.azs :
    format("private-%02d", idx + 1) => {
      az     = az
      newbits = var.subnet_newbits
      netnum  = idx
    }
  }
}

# VPC pede o bloco direto ao IPAM (sem preview/alloc separado)
resource "aws_vpc" "this" {
  enable_dns_hostnames = true
  enable_dns_support   = true

  ipv4_ipam_pool_id   = var.ipam_pool_id
  ipv4_netmask_length = var.vpc_netmask_length

  tags = merge(var.tags, {
    Name = "${var.environment_name}-VPC"
  })
}

# Subnets privadas
resource "aws_subnet" "private" {
  for_each                = local.private_subnets
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, each.value.newbits, each.value.netnum)

  tags = merge(var.tags, {
    Name    = "${var.environment_name}-${each.key}-${each.value.az}"
    Network = "Private"
    Tier    = "private"
  })
}

# Route table privada + associações
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.environment_name}-rt" })
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Rota padrão para TGW (opcional)
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw" {
  count              = var.enable_tgw ? 1 : 0
  vpc_id             = aws_vpc.this.id
  subnet_ids         = [for s in aws_subnet.private : s.id]
  transit_gateway_id = var.transit_gateway_id

  tags = merge(var.tags, {
    Name = "${var.environment_name}-tgw-attachment"
  })
}

resource "aws_route" "default_to_tgw" {
  count                   = var.enable_tgw ? 1 : 0
  route_table_id          = aws_route_table.private.id
  destination_cidr_block  = "0.0.0.0/0"
  transit_gateway_id      = var.transit_gateway_id
  depends_on              = [aws_ec2_transit_gateway_vpc_attachment.tgw]
}

# SG intra-VPC (opcional)
resource "aws_security_group" "acesso_intra_vpc_v2" {
  count       = var.enable_intra_vpc_sg ? 1 : 0
  name        = "acesso intra-vpc-v2"
  description = "Acessos internos dentro do bloco da VPC"
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = toset(var.intra_vpc_tcp_ports)
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.this.cidr_block]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  tags = merge(var.tags, { Name = "Acesso intra-vpc-v2" })
}

# NACL default custom (opcional) — cuidado com drift se AWS Config gerencia
resource "aws_default_network_acl" "custom" {
  count                   = var.enable_default_nacl ? 1 : 0
  default_network_acl_id  = aws_vpc.this.default_network_acl_id
  subnet_ids              = [for s in aws_subnet.private : s.id]

  dynamic "egress" {
    for_each = var.default_nacl_egress
    content {
      action          = egress.value.action
      cidr_block      = egress.value.cidr_block
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      rule_no         = egress.value.rule_no
      icmp_code       = try(egress.value.icmp_code, 0)
      icmp_type       = try(egress.value.icmp_type, 0)
      ipv6_cidr_block = try(egress.value.ipv6_cidr_block, null)
    }
  }

  dynamic "ingress" {
    for_each = var.default_nacl_ingress
    content {
      action          = ingress.value.action
      cidr_block      = ingress.value.cidr_block
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      rule_no         = ingress.value.rule_no
      icmp_code       = try(ingress.value.icmp_code, 0)
      icmp_type       = try(ingress.value.icmp_type, 0)
      ipv6_cidr_block = try(ingress.value.ipv6_cidr_block, null)
    }
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-default-nacl" })
}

# Private Hosted Zone + Resolver Rules (opcional)
resource "aws_route53_zone" "phz" {
  count = var.enable_phz ? 1 : 0
  name  = "${var.dns_private_zone}.cip-cloud.local"

  vpc { vpc_id = aws_vpc.this.id }

  tags = merge(var.tags, { Name = "PrivateHostedZone" })
}

resource "aws_route53_resolver_rule_association" "child" {
  count            = var.enable_phz && var.child_domain_resolver_rule_id != "" ? 1 : 0
  name             = "RuleAssociationforChildDomains"
  resolver_rule_id = var.child_domain_resolver_rule_id
  vpc_id           = aws_vpc.this.id
}

resource "aws_route53_resolver_rule_association" "aws_dns" {
  count            = var.enable_phz && var.aws_dns_resolution != "" ? 1 : 0
  name             = "RuleAssociationforAWS"
  resolver_rule_id = var.aws_dns_resolution
  vpc_id           = aws_vpc.this.id
}

resource "aws_route53_resolver_rule_association" "onprem" {
  count            = var.enable_phz && var.on_prem_domain_resolver_rule_id != "" ? 1 : 0
  name             = "RuleAssociationOnPremiseDomains"
  resolver_rule_id = var.on_prem_domain_resolver_rule_id
  vpc_id           = aws_vpc.this.id
}

resource "aws_route53_resolver_rule_association" "onprem_legacy" {
  count            = var.enable_phz && var.on_prem_legacy_cloud_domain_resolver_rule_id != "" ? 1 : 0
  name             = "RuleAssociationOnPremiseLegacyCloudDomains"
  resolver_rule_id = var.on_prem_legacy_cloud_domain_resolver_rule_id
  vpc_id           = aws_vpc.this.id
}

# ---------------------------
# Flow Logs (S3) - locals e recurso
# ---------------------------

locals {
  # usa exatamente o prefixo informado (ou vazio)
  flow_logs_prefix_effective = trimspace(var.flow_logs_prefix)

  # monta o ARN do destino S3 sem usar "AWSLogs/...":
  # - sem prefixo => arn:aws:s3:::<bucket>
  # - com prefixo => arn:aws:s3:::<bucket>/<prefix>
  flow_logs_destination_arn = format(
    "arn:aws:s3:::%s%s",
    var.flow_logs_bucket_name,
    local.flow_logs_prefix_effective == "" ? "" : "/${local.flow_logs_prefix_effective}"
  )
}

resource "aws_flow_log" "this" {
  count        = var.enable_flow_logs ? 1 : 0
  vpc_id       = aws_vpc.this.id
  traffic_type = "ALL"

  log_destination_type     = "s3"
  log_destination          = local.flow_logs_destination_arn
  max_aggregation_interval = var.flow_logs_max_aggregation_interval

  destination_options {
    file_format                = var.flow_logs_file_format
    hive_compatible_partitions = var.flow_logs_hive_compatible
    per_hour_partition         = var.flow_logs_per_hour_partition
  }

  tags = merge(var.tags, {
    Name = "${var.environment_name}-vpc-flow-logs"
  })
}

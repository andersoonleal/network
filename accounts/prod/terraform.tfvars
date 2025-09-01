region           = "us-east-1"
environment_name = "Prod"

# SÓ ISSO AQUI JÁ FAZ A MÁGICA (além do /22 default)
ipam_pool_id       = "ipam-pool-02237e547c5e37021"
vpc_netmask_length = 22 # /22 (ajuste se quiser)

az_count       = 3
subnet_newbits = 2 # /24 a partir de /22

# Opcional — TGW
enable_tgw         = true
transit_gateway_id = "tgw-0326eaa96ab373740"

# Opcional — SG intra-VPC
enable_intra_vpc_sg = true
intra_vpc_tcp_ports = [443, 2049, 5432, 1768, 1414, 1364, 1363, 22, 8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089, 9990, 9080, 9082, 9081, 444]

# Opcional — NACL default
enable_default_nacl = false

# Opcional — PHZ/Resolver
enable_phz       = false
dns_private_zone = "dev"

enable_flow_logs      = true
flow_logs_bucket_name = "vpcflowlogs-local-600627337561-us-east-1" # seu bucket
# flow_logs_prefix              = ""      # opcional; deixei auto
flow_logs_file_format              = "parquet"
flow_logs_per_hour_partition       = true
flow_logs_hive_compatible          = true
flow_logs_max_aggregation_interval = 60

# # Flow Logs (S3)
# variable "enable_flow_logs" {
#   type    = bool
#   default = true
# }

# variable "flow_logs_bucket_name" {
#   type        = string
#   description = "Nome do bucket S3 que receberá os VPC Flow Logs"
# }

# # Se vazio, calculo automático: AWSLogs/<account_id>/vpcflowlogs/<region>
# variable "flow_logs_prefix" {
#   type    = string
#   default = ""
# }

# variable "flow_logs_file_format" {
#   type    = string
#   default = "parquet" # "plain-text" ou "parquet"
#   validation {
#     condition     = contains(["plain-text", "parquet"], var.flow_logs_file_format)
#     error_message = "flow_logs_file_format deve ser plain-text ou parquet."
#   }
# }

# variable "flow_logs_per_hour_partition" {
#   type    = bool
#   default = true
# }

# variable "flow_logs_hive_compatible" {
#   type    = bool
#   default = true
# }

# variable "flow_logs_max_aggregation_interval" {
#   type    = number
#   default = 60 # segundos (60 ou 600)
# }

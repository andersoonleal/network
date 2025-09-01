output "vpc_id"            { value = aws_vpc.this.id }
output "vpc_cidr"          { value = aws_vpc.this.cidr_block }
output "private_subnet_ids"{ value = [for s in aws_subnet.private : s.id] }
output "private_subnets"   { value = { for k, s in aws_subnet.private : k => s.cidr_block } }

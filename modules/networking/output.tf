output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "internet_gw" {
  value = aws_internet_gateway.gw.id
}

output "eip_ip" {
  value = aws_eip.nat_eip.public_ip
}

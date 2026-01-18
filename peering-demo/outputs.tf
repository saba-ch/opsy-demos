output "vpc_a_id" {
  description = "VPC A ID"
  value       = aws_vpc.a.id
}

output "vpc_b_id" {
  description = "VPC B ID"
  value       = aws_vpc.b.id
}

output "peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.peer.id
}

output "server_private_ip" {
  description = "Server private IP"
  value       = aws_instance.server.private_ip
}

output "client_1_instance_id" {
  description = "Client 1 instance ID (for SSM)"
  value       = aws_instance.client_1.id
}

output "client_2_instance_id" {
  description = "Client 2 instance ID (for SSM)"
  value       = aws_instance.client_2.id
}

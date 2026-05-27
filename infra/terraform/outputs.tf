output "master_node_public_ip" {
  description = "Public IP of the Master Node"
  value       = module.ec2.master_node_public_ip
}

output "worker_nodes_private_ips" {
  description = "Private IPs of the Worker Nodes"
  value       = module.ec2.worker_nodes_private_ips
}

output "private_key_pem" {
  description = "Private Key to SSH into instances"
  value       = tls_private_key.my_key.private_key_pem
  sensitive   = true
}

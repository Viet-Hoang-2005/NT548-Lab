output "master_node_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_nodes_private_ips" {
  value = aws_instance.worker[*].private_ip
}

output "worker_instance_ids" {
  value = aws_instance.worker[*].id
}

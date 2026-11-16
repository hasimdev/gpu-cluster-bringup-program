output "node_public_ips" {
  description = "Public IPs for SSH. Node 0 hosts the Kubernetes control plane."
  value       = aws_instance.gpu_node[*].public_ip
}

output "node_private_ips" {
  description = "Private IPs used for node-to-node and NCCL traffic."
  value       = aws_instance.gpu_node[*].private_ip
}

output "instance_ids" {
  value = aws_instance.gpu_node[*].id
}

output "cluster_id" {
  value = aws_eks_cluster.gitops_learn.id
}

output "node_group_id" {
  value = aws_eks_node_group.gitops_learn.id
}

output "vpc_id" {
  value = aws_vpc.gitops_learn_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.gitops_learn_subnet[*].id
}

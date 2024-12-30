provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_vpc" "gitops_learn_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "GitOps-Learn-VPC"
  }
}

resource "aws_subnet" "gitops_learn_subnet" {
  count = 2
  vpc_id                  = aws_vpc.gitops_learn_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.gitops_learn_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-southeast-2a", "ap-southeast-2b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "GitOps-Learn-Subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "gitops_learn_igw" {
  vpc_id = aws_vpc.gitops_learn_vpc.id

  tags = {
    Name = "GitOps-Learn-IGW"
  }
}

resource "aws_route_table" "gitops_learn_route_table" {
  vpc_id = aws_vpc.gitops_learn_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gitops_learn_igw.id
  }

  tags = {
    Name = "GitOps-Learn-Route-Table"
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.gitops_learn_subnet[count.index].id
  route_table_id = aws_route_table.gitops_learn_route_table.id
}

resource "aws_security_group" "gitops_learn_cluster_sg" {
  vpc_id = aws_vpc.gitops_learn_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "GitOps-Learn-Cluster-SG"
  }
}

resource "aws_security_group" "gitops_learn_node_sg" {
  vpc_id = aws_vpc.gitops_learn_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "GitOps-Learn-Node-SG"
  }
}

resource "aws_eks_cluster" "gitops_learn" {
  name     = "GitOps-Learn-Cluster"
  role_arn = aws_iam_role.gitops_learn_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.gitops_learn_subnet[*].id
    security_group_ids = [aws_security_group.gitops_learn_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "gitops_learn" {
  cluster_name    = aws_eks_cluster.gitops_learn.name
  node_group_name = "GitOps-Learn-Node-Group"
  node_role_arn   = aws_iam_role.gitops_learn_node_group_role.arn
  subnet_ids      = aws_subnet.gitops_learn_subnet[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [aws_security_group.gitops_learn_node_sg.id]
  }
}

resource "aws_iam_role" "gitops_learn_cluster_role" {
  name = "GitOps-Learn-Cluster-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "gitops_learn_cluster_role_policy" {
  role       = aws_iam_role.gitops_learn_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "gitops_learn_node_group_role" {
  name = "GitOps-Learn-Node-Group-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "gitops_learn_node_group_role_policy" {
  role       = aws_iam_role.gitops_learn_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "gitops_learn_node_group_cni_policy" {
  role       = aws_iam_role.gitops_learn_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "gitops_learn_node_group_registry_policy" {
  role       = aws_iam_role.gitops_learn_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

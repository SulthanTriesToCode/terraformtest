#
# Providers etc
#
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

#
# Shared resources e.g. AMI, ssh keypair
#
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# lb

resource "aws_key_pair" "admin" {
  key_name   = "admin-keyfor-a2"
  public_key = file(var.path_to_ssh_public_key)
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Tier"
    values = ["public"]
  }
}

# data "aws_subnets" "private" {
#   filter {
#     name   = "tag:Tier"
#     values = ["private"]
#   }
# }

data "aws_internet_gateway" "main" {
  filter {
    name = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}



# Public Subnet in us-east-1a
resource "aws_subnet" "public1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.96.0/20"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet-1"
    Tier = "public"
  }
}

# Public Subnet in us-east-1f
resource "aws_subnet" "public2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.112.0/20"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1f"
  tags = {
    Name = "public-subnet-2"
    Tier = "public"
  }
}


# Private Subnet in us-east-1f
resource "aws_subnet" "private" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.192.0/20"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1f"
  tags = {
    Name = "private-subnet"
    Tier = "private"
  }
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id            = data.aws_vpc.default.id
  route {
    cidr_block        = "0.0.0.0/0"
    gateway_id        = data.aws_internet_gateway.main.id
  }
  tags = {
    Name = "public-rt"
  }
}

# Associate route table with public subnet in us-east-1a
resource "aws_route_table_association" "public1" {
  subnet_id         = aws_subnet.public1.id
  route_table_id    = aws_route_table.public.id
}

# Associate route table with public subnet in us-east-1f
resource "aws_route_table_association" "public2" {
  subnet_id         = aws_subnet.public2.id
  route_table_id    = aws_route_table.public.id
}

# NAT Gateway for private subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.private.id
  tags = {
    Name = "main-nat"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "main" {
  vpc = true
  tags = {
    Name = "main-eip"
  }
}

# Route Table for private subnet
resource "aws_route_table" "private" {
  vpc_id            = data.aws_vpc.default.id
  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id    = aws_nat_gateway.main.id
  }
  tags = {
    Name = "private-rt"
  }
}

# Associate route table with private subnet
resource "aws_route_table_association" "private" {
  subnet_id         = aws_subnet.private.id
  route_table_id    = aws_route_table.private.id
}

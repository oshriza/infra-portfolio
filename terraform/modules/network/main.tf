data "aws_availability_zones" "available" {}

locals {
    vpc_cidr = "10.0.0.0/16"
    azs      = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "oshri_vpc" {
  cidr_block = local.vpc_cidr

  tags = {
    Name = "${var.env_prefix}"
    Created_by = "Terraform"
  }
}

resource "aws_internet_gateway" "oshri_igw" {
  vpc_id = aws_vpc.oshri_vpc.id

  tags = {
    Name = "${var.env_prefix}"
    Created_by = "Terraform"
  }
}

resource "aws_subnet" "private" {
  count = var.subnet_count
  vpc_id                  = aws_vpc.oshri_vpc.id
  availability_zone       = local.azs[count.index]
  # availability_zone       = var.aws_availability_zone[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  tags = {
    "Name"                       = "${var.env_prefix}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/oshri_cluster" = "shared"
    Created_by = "Terraform"
  }
}

resource "aws_subnet" "public" {
  count = var.subnet_count
  vpc_id                  = aws_vpc.oshri_vpc.id
  availability_zone       = local.azs[count.index]
  # availability_zone       = var.aws_availability_zone[count.index]
  cidr_block              = "10.0.${count.index + 2}.0/24"
  map_public_ip_on_launch = true
  tags = {
    "Name"                       = "${var.env_prefix}-public-${count.index + 1}"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/oshri_cluster" = "shared"
    Created_by = "Terraform"
  }
}

resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "${var.env_prefix}-nat"
    Created_by = "Terraform"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  connectivity_type = "public"
  # count = 2
  # subnet_id = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.env_prefix}"
    Created_by = "Terraform"
  }

  depends_on = [aws_internet_gateway.oshri_igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.oshri_vpc.id
  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      nat_gateway_id             = aws_nat_gateway.nat.id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      gateway_id                 = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "${var.env_prefix}-private"
    Created_by = "Terraform"
  }
  depends_on = [aws_nat_gateway.nat]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.oshri_vpc.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.oshri_igw.id
      nat_gateway_id             = ""
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "${var.env_prefix}-public"
    Created_by = "Terraform"
  }
  depends_on = [aws_internet_gateway.oshri_igw]
}

resource "aws_route_table_association" "private" {
  count = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  count = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
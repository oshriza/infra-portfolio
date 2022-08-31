data "aws_availability_zones" "available" {}

locals {
    azs      = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.env_prefix}"
    Created_by = "Terraform"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.env_prefix}"
    Created_by = "Terraform"
  }
}
resource "aws_subnet" "private" {
  count = length(local.azs)
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, (32 - var.vpc_prefix) / 2, count.index)
  tags = {
    "Name"                       = "${var.env_prefix}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.env_prefix}_cluster" = "shared"
    Created_by = "Terraform"
  }
}

resource "aws_subnet" "public" {
  count = length(local.azs)
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, (32 - var.vpc_prefix) / 2, count.index + length(aws_subnet.private.*))
  map_public_ip_on_launch = true
  tags = {
    "Name"                       = "${var.env_prefix}-public-${count.index + 1}"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/${var.env_prefix}_cluster" = "shared"
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
  tags = {
    Name = "${var.env_prefix}"
    Created_by = "Terraform"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
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
  vpc_id = aws_vpc.this.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.this.id
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
  depends_on = [aws_internet_gateway.this]
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
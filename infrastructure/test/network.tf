##################################################
##          VPC
###################################################


# Create the VPC
# the 2 DNS configs are required if worker node to cluster communication should be performed private within the VPC
 resource "aws_vpc" "vpc" {
   cidr_block = "10.0.0.0/16"
   enable_dns_hostnames = true
   enable_dns_support = true
   tags = {
     "Name"                                        = "${local.cluster-name}_vpc"
     "kubernetes.io/cluster/${local.cluster-name}" = "shared"
   }
 }

##################################################
##          Subnets
###################################################

 # This provides the availability zones of the current zone (e.g. eu-central-1a and eu-central-1b)
 data "aws_availability_zones" "available" {
 }

# Create <count> subnets within the available regions
resource "aws_subnet" "gateway" {
  count = local.subnet_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.1${count.index}.0/24"
  vpc_id            = aws_vpc.vpc.id
  tags = {
     "Name" = "${local.cluster-name}_gateway-subnet"
     "kubernetes.io/cluster/${local.cluster-name}" = "shared"
     "kubernetes.io/role/elb" = "1"
  }
}
resource "aws_subnet" "application" {
  count = local.subnet_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.2${count.index}.0/24"
  vpc_id            = aws_vpc.vpc.id
  tags = {
     "Name" = "${local.cluster-name}_application-subnet"
     "kubernetes.io/cluster/${local.cluster-name}" = "shared"
     "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "database" {
  count = local.subnet_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.3${count.index}.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
     "Name" = "${local.cluster-name}_database-subnet"
  }
}


##################################################
##          Gateways
###################################################

# The internet gateway for access to VPC
 resource "aws_internet_gateway" "internet-gateway" {
   vpc_id = aws_vpc.vpc.id

   tags = {
     Name = "${local.cluster-name}_internet-gateway"
   }
 }

resource "aws_eip" "eip-nat-gateway" {
  count = local.subnet_count
  vpc   = true

  tags = {
     Name = "${local.cluster-name}_eip"
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  count = local.subnet_count
  allocation_id = aws_eip.eip-nat-gateway.*.id[count.index]
  subnet_id = aws_subnet.gateway.*.id[count.index]

  tags = {
    Name = "${local.cluster-name}_nat_gateway"
  }
  depends_on = [aws_internet_gateway.internet-gateway]
}

##################################################
##          Routing tables
###################################################


# Routing tables for the subnets
resource "aws_route_table" "application" {
  count = local.subnet_count
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.*.id[count.index]
  }
  tags = {
    Name = "${local.cluster-name}_application-route-table"
  }
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.cluster-name}_database-route-table"
  }
}
resource "aws_route_table" "gateway" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "${local.cluster-name}_gateway-route-table"
  }
}

# Routing for the subnets
resource "aws_route_table_association" "application" {
  count = local.subnet_count

  subnet_id      = aws_subnet.application.*.id[count.index]
  route_table_id = aws_route_table.application.*.id[count.index]
}

resource "aws_route_table_association" "database" {
  count = local.subnet_count

  subnet_id      = aws_subnet.database.*.id[count.index]
  route_table_id = aws_route_table.database.id
}

resource "aws_route_table_association" "gateway" {
  count = local.subnet_count

  subnet_id      = aws_subnet.gateway.*.id[count.index]
  route_table_id = aws_route_table.gateway.id
}
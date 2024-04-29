# Optional Required Provider Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "project-1-vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.vpc-name
  }
}

# Create Route Table for private subnet
resource "aws_route_table" "project-1-RT-1" {
  vpc_id = aws_vpc.project-1-vpc.id
  tags = {
    Name = var.route-table-name-private
  }
}

resource "aws_route" "private_subnet_route_to_nat" {
  route_table_id         = aws_route_table.project-1-RT-1.id
  destination_cidr_block = "0.0.0.0/0" # Route all traffic
  nat_gateway_id         = aws_nat_gateway.project-1-NAT-gateway.id
}

# Create Route Table for public subnet
resource "aws_route_table" "project-1-RT-2" {
  vpc_id = aws_vpc.project-1-vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Route for all traffic
    gateway_id = aws_internet_gateway.project-1-igw.id
  }

  tags = {
    Name = var.route-table-name
  }
}

# Create a EIP for NAT gateway
resource "aws_eip" "eip_NAT_gatway" {
  domain = "vpc"
}


# Create a NAT Gateway
resource "aws_nat_gateway" "project-1-NAT-gateway" {
  allocation_id = aws_eip.eip_NAT_gatway.id
  subnet_id     = aws_subnet.project-1-subnet-1.id

  tags = {
    Name = var.NAT-gatway-name
  }
  depends_on = [aws_internet_gateway.project-1-igw]
}

# Create a IGW
resource "aws_internet_gateway" "project-1-igw" {
  vpc_id = aws_vpc.project-1-vpc.id

  tags = {
    Name = var.internet-gateway-name

  }

}

# Create a RTA for public subnet-1
resource "aws_route_table_association" "project-1-RTA-1" {
  subnet_id      = aws_subnet.project-1-subnet-1.id
  route_table_id = aws_route_table.project-1-RT-2.id
}

# Create a RTA for public subnet-2
resource "aws_route_table_association" "project-1-RTA-2" {
  subnet_id      = aws_subnet.project-1-subnet-2.id
  route_table_id = aws_route_table.project-1-RT-2.id
}

# Create a RTA for private subnet-1
resource "aws_route_table_association" "project-1-RTA-3" {
  subnet_id      = aws_subnet.project-1-subnet-3.id
  route_table_id = aws_route_table.project-1-RT-1.id
}

# Create a RTA for private subnet-2
resource "aws_route_table_association" "project-1-RTA-4" {
  subnet_id      = aws_subnet.project-1-subnet-4.id
  route_table_id = aws_route_table.project-1-RT-1.id
}


# Create a Private Subnet-1
resource "aws_subnet" "project-1-subnet-3" {
  vpc_id                  = aws_vpc.project-1-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.az-1
  map_public_ip_on_launch = false
}

# Create a Private Subnet-2
resource "aws_subnet" "project-1-subnet-4" {
  vpc_id                  = aws_vpc.project-1-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = var.az-2
  map_public_ip_on_launch = false
}


# Create a Public Subnet-1
resource "aws_subnet" "project-1-subnet-1" {
  vpc_id                  = aws_vpc.project-1-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az-1
  map_public_ip_on_launch = true
}

# Create a Public Subnet-2
resource "aws_subnet" "project-1-subnet-2" {
  vpc_id                  = aws_vpc.project-1-vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = var.az-2
  map_public_ip_on_launch = true
}

# Create a Security Group
resource "aws_security_group" "project-1-SG-1" {
  name        = "project-1-SG-public"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.project-1-vpc.id

  tags = {
    Name = var.security-group-name
  }
}

# Inbound Traffic rule for Security Group (HTTP)
resource "aws_vpc_security_group_ingress_rule" "SG-1-HTTP" {
  security_group_id = aws_security_group.project-1-SG-1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


# Inbound Traffic rule for Security Group (SSH)
resource "aws_vpc_security_group_ingress_rule" "SG-1-SSH" {
  security_group_id = aws_security_group.project-1-SG-1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


# Outbound Traffic rule for Security Group
resource "aws_vpc_security_group_egress_rule" "SG-1-All" {
  security_group_id = aws_security_group.project-1-SG-1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Create a security group for the private subnet
resource "aws_security_group" "project-1-SG-2" {
  name        = "project-1-SG-private"
  description = "Security group for private subnet"

  vpc_id = aws_vpc.project-1-vpc.id

  # Define inbound rules (ingress)

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # http traffic from VPC
  }


  # Define outbound rules (egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to any destination
  }

  tags = {
    Name = var.security-group-name-private
  }

}

# Create an EC2 instance-1
resource "aws_instance" "project-1-instance-1" {
  ami           = "ami-080e1f13689e07408"
  instance_type = var.instance_type
  subnet_id     = aws_subnet.project-1-subnet-3.id
  key_name      = var.key_name
  tags = {
    Name = var.instance-1-name
  }
  security_groups = [aws_security_group.project-1-SG-2.id]
  user_data       = base64encode(file("Data1.sh"))
}

# Create an EC2 instance-2
resource "aws_instance" "project-1-instance-2" {
  ami           = "ami-080e1f13689e07408"
  instance_type = var.instance_type
  subnet_id     = aws_subnet.project-1-subnet-4.id
  key_name      = var.key_name
  tags = {
    Name = var.instance-2-name
  }
  security_groups = [aws_security_group.project-1-SG-2.id]
  user_data       = base64encode(file("Data2.sh"))
}

# Create a S3 bucket
resource "aws_s3_bucket" "project-1-bucket" {
  bucket = "project-1-bucket-prac-27042024"
  tags = {
    name = var.s3-bucket-name
  }
}

# Create a load balancer
resource "aws_lb" "project-1-loadbalancer" {
  name               = var.load-balance-name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.project-1-SG-1.id]
  subnets            = [aws_subnet.project-1-subnet-1.id, aws_subnet.project-1-subnet-2.id]

}

# Create a LB target group
resource "aws_lb_target_group" "project-1-targetgroup" {
  name     = var.target-group-name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project-1-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# Create a TG attachement with web server 1
resource "aws_lb_target_group_attachment" "project-1-attach1" {
  target_group_arn = aws_lb_target_group.project-1-targetgroup.arn
  target_id        = aws_instance.project-1-instance-1.id
  port             = 80
}

# Create a TG attachement with web server 2
resource "aws_lb_target_group_attachment" "project-1-attach2" {
  target_group_arn = aws_lb_target_group.project-1-targetgroup.arn
  target_id        = aws_instance.project-1-instance-2.id
  port             = 80
}

# Create a Load balance listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.project-1-loadbalancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.project-1-targetgroup.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.project-1-loadbalancer.dns_name
}
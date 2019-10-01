

provider "aws" {
  region = "eu-west-1"
}

##################################################################
# VPC
##################################################################

module "vpc"{
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"

  name = "gitops-example-vpc"

  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  
  tags = {
    Owner       = "rochford"
    Environment = "dev"
    Pipeline = "jenky"
  }

  vpc_tags = {
    Name = "vpc-gitops-demo"
  }
}

##################################################################
# EC2
##################################################################

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "example-sg"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

module "ec2" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  instance_count = 1

  name          = "gitops-demo-compute"
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t1.micro"
  subnet_ids             = ["${module.vpc.public_subnets[0]}"]
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  associate_public_ip_address = true
  
  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 10
    },
  ]

  tags = {
    Owner       = "rochford"
    Environment = "dev"
    Pipeline = "jenky"
  }
}



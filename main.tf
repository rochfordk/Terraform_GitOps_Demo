

provider "aws" {
  region = "eu-west-1"
}

//data "aws_security_group" "default" {
//  name   = "default"
//  vpc_id = module.vpc.vpc_id
//}

##################################################################
# VPC
##################################################################

module "vpc"{
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"

  name = "gitops-example-vpc"

  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_ipv6 = true

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "overridden-name-public"
  }

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

//data "aws_vpc" "default" {
//  default = true
//}

//data "aws_subnet_ids" "all" {
//  vpc_id = data.aws_vpc.default.id
//}

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

//resource "aws_eip" "this" {
//  vpc      = true
//  instance = module.ec2.id[0]
//}

//resource "aws_placement_group" "web" {
//  name     = "hunky-dory-pg"
//  strategy = "cluster"
//}

//resource "aws_kms_key" "this" {
//}

module "ec2" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  instance_count = 1

  name          = "example-normal"
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t1.micro"
  subnet_id     = tolist(data.aws_subnet_ids.all.ids)[0]
  //  private_ips                 = ["172.31.32.5", "172.31.46.20"]
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  associate_public_ip_address = true
  //placement_group             = aws_placement_group.web.id

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 10
    },
  ]

  //ebs_block_device = [
  //  {
  //    device_name = "/dev/sdf"
  //    volume_type = "gp2"
  //    volume_size = 5
  //    encrypted   = true
  //    kms_key_id  = aws_kms_key.this.arn
  //  }
  //]

  tags = {
    Owner       = "rochford"
    Environment = "dev"
    Pipeline = "jenky"
  }
}



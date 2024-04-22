# Define variables
variable "aws_region" {
  description = "The AWS region where the infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The environment (e.g., production, staging) for the infrastructure."
  type        = string
  default     = "production"
}

variable "instance_count" {
  description = "The number of EC2 instances to launch."
  type        = number
  default     = 2
}

# Module to create VPC with custom options
module "vpc" {
  source = "./modules/vpc"
  
  aws_region = var.aws_region
  vpc_cidr_block = "10.0.0.0/16"
}

# Module to create public and private subnets
module "subnets" {
  source = "./modules/subnets"
  
  vpc_id = module.vpc.vpc_id
  aws_region = var.aws_region
  public_subnet_cidr = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

# Module to create internet gateway and attach it to VPC
module "internet_gateway" {
  source = "./modules/internet_gateway"
  
  vpc_id = module.vpc.vpc_id
}

# Module to create route tables and associate them with subnets
module "route_tables" {
  source = "./modules/route_tables"
  
  vpc_id = module.vpc.vpc_id
  public_subnets = module.subnets.public_subnets
  internet_gateway_id = module.internet_gateway.internet_gateway_id
}

# Module to create security group for EC2 instances
module "security_group" {
  source = "./modules/security_group"
  
  vpc_id = module.vpc.vpc_id
}

# Module to create EC2 instances in auto-scaling group
module "autoscaling_group" {
  source = "./modules/autoscaling_group"
  
  launch_template_id = module.launch_template.launch_template_id
  vpc_zone_identifier = module.subnets.private_subnets
  security_group_ids = [module.security_group.security_group_id]
  instance_count = var.instance_count
}

# Module to create launch template for EC2 instances
module "launch_template" {
  source = "./modules/launch_template"
  
  ami_id = "ami-12345678"
  instance_type = "t2.micro"
  security_group_ids = [module.security_group.security_group_id]
}

# Module to create Elastic Load Balancer (ELB)
module "elb" {
  source = "./modules/elb"
  
  aws_region = var.aws_region
  availability_zones = module.subnets.availability_zones
  security_groups = [module.security_group.security_group_id]
}

# Module to define CI/CD pipeline using AWS CodePipeline
module "codepipeline" {
  source = "./modules/codepipeline"
  
  aws_region = var.aws_region
  code_deploy_role_arn = module.code_deploy_role.code_deploy_role_arn
}

# Module to define deployment group using AWS CodeDeploy
module "codedeploy_deployment_group" {
  source = "./modules/codedeploy_deployment_group"
  
  app_name = "web-app"
  deployment_group_name = "web-deployment-group"
  service_role_arn = module.code_deploy_role.code_deploy_role_arn
}

# Module to create S3 bucket for storing application artifacts
module "s3_bucket" {
  source = "./modules/s3_bucket"
  
  bucket_name = "web-artifacts-${var.environment}-${var.aws_region}"
}

# Module to define IAM roles and policies for CodePipeline and CodeDeploy
module "iam_roles_policies" {
  source = "./modules/iam_roles_policies"
  
  aws_region = var.aws_region
  code_pipeline_role_name = "codepipeline-${var.environment}"
  code_deploy_role_name = "codedeploy-${var.environment}"
}

# Module to define CloudWatch alarms for monitoring
module "cloudwatch_alarms" {
  source = "./modules/cloudwatch_alarms"
  
  aws_region = var.aws_region
  autoscaling_group_name = module.autoscaling_group.autoscaling_group_name
}

# Module to define Lambda functions for custom automation tasks
module "lambda_functions" {
  source = "./modules/lambda_functions"
  
  aws_region = var.aws_region
}

# Module to define notifications using SNS for alerts and notifications
module "sns_notifications" {
  source = "./modules/sns_notifications"
  
  aws_region = var.aws_region
}

# Data source to fetch available availability zones in the specified region
data "aws_availability_zones" "available" {
  state = "available"
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State ファイルをS3に保存する場合は以下をコメント解除
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "dev/terraform.tfstate"
  #   region         = "ap-northeast-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# ネットワークモジュール
module "network" {
  source = "../../modules/network"

  environment          = var.environment
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidr   = var.public_subnet_cidr
  availability_zone    = var.availability_zone
  container_port       = var.container_port
}

# IAMモジュール
module "iam" {
  source = "../../modules/iam"

  environment         = var.environment
  artifact_bucket_arn = module.codepipeline.artifact_bucket_arn
}

# ECSモジュール
module "ecs" {
  source = "../../modules/ecs"

  environment                   = var.environment
  aws_region                    = var.aws_region
  container_port                = var.container_port
  task_cpu                       = var.task_cpu
  task_memory                    = var.task_memory
  ecr_repository_uri            = aws_ecr_repository.main.repository_url
  ecs_task_execution_role_arn   = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn             = module.iam.ecs_task_role_arn
  public_subnet_id              = module.network.public_subnet_id
  ecs_security_group_id         = module.network.ecs_security_group_id
}

# CodePipelineモジュール
module "codepipeline" {
  source = "../../modules/codepipeline"

  environment                    = var.environment
  codepipeline_role_arn          = module.iam.codepipeline_role_arn
  codebuild_role_arn             = module.iam.codebuild_role_arn
  
  # Build Pipeline
  app_repository_name            = var.app_repository_name != "" ? var.app_repository_name : var.repository_name
  app_repository_branch          = var.app_repository_branch
  codebuild_compute_type         = var.codebuild_compute_type
  codebuild_image                = var.codebuild_image
  buildspec_content              = var.buildspec_content
  
  # Deploy Pipeline
  ecs_cluster_name               = module.ecs.ecs_cluster_name
  ecs_service_name               = module.ecs.ecs_service_name
  ecs_task_execution_role_arn    = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn              = module.iam.ecs_task_role_arn
}

# ECR Repository (メインのモジュール外)
resource "aws_ecr_repository" "main" {
  name                 = "${var.environment}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.environment}-ecr"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

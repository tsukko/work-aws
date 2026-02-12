variable "environment" {
  description = "Environment name"
  type        = string
}

# Build Pipeline variables
variable "app_repository_owner" {
  description = "GitHub repository owner (e.g., tsukko)"
  type        = string
}

variable "app_repository_name" {
  description = "GitHub repository name (e.g., work-ecs-app)"
  type        = string
}

variable "app_repository_branch" {
  description = "Application repository branch"
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "CodeStar Connections ARN for GitHub (created in AWS Console)"
  type        = string
}

variable "codebuild_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_image" {
  description = "CodeBuild image"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "buildspec_content" {
  description = "Buildspec content"
  type        = string
  default     = ""
}

# Deploy Pipeline variables
variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

# IAM roles
variable "codepipeline_role_arn" {
  description = "CodePipeline role ARN"
  type        = string
}

variable "codebuild_role_arn" {
  description = "CodeBuild role ARN"
  type        = string
}

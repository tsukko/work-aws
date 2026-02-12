variable "environment" {
  description = "Environment name"
  type        = string
}

variable "codepipeline_role_arn" {
  description = "CodePipeline role ARN"
  type        = string
}

variable "codebuild_role_arn" {
  description = "CodeBuild role ARN"
  type        = string
}

variable "repository_name" {
  description = "CodeCommit repository name"
  type        = string
}

variable "repository_branch" {
  description = "CodeCommit repository branch"
  type        = string
  default     = "main"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
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
}

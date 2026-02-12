output "ecr_repository_uri" {
  description = "ECR repository URI"
  value       = aws_ecr_repository.main.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.ecs_service_name
}

output "build_pipeline_arn" {
  description = "Build Pipeline ARN"
  value       = module.codepipeline.build_pipeline_arn
}

output "deploy_pipeline_arn" {
  description = "Deploy Pipeline ARN"
  value       = module.codepipeline.deploy_pipeline_arn
}

output "build_artifacts_bucket" {
  description = "Build artifacts bucket"
  value       = module.codepipeline.build_artifacts_bucket
}

output "deploy_artifacts_bucket" {
  description = "Deploy artifacts bucket"
  value       = module.codepipeline.deploy_artifacts_bucket
}

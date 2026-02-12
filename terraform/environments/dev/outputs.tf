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

output "codepipeline_arn" {
  description = "CodePipeline ARN"
  value       = module.codepipeline.codepipeline_arn
}

output "artifact_bucket" {
  description = "CodePipeline artifact bucket"
  value       = module.codepipeline.artifact_bucket_name
}

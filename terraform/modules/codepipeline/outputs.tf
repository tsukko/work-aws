output "build_pipeline_arn" {
  description = "Build Pipeline ARN"
  value       = aws_codepipeline.build_pipeline.arn
}

output "deploy_pipeline_arn" {
  description = "Deploy Pipeline ARN"
  value       = aws_codepipeline.deploy_pipeline.arn
}

output "build_artifacts_bucket" {
  description = "Build artifacts bucket name"
  value       = aws_s3_bucket.build_artifacts.id
}

output "deploy_artifacts_bucket" {
  description = "Deploy artifacts bucket name"
  value       = aws_s3_bucket.deploy_artifacts.id
}

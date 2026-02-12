output "codepipeline_arn" {
  description = "CodePipeline ARN"
  value       = aws_codepipeline.main.arn
}

output "artifact_bucket_name" {
  description = "Artifact bucket name"
  value       = aws_s3_bucket.artifacts.id
}

output "artifact_bucket_arn" {
  description = "Artifact bucket ARN"
  value       = aws_s3_bucket.artifacts.arn
}

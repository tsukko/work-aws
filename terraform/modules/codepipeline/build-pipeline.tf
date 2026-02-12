# Build Pipeline Module
# アプリリポジトリをビルド → ECRにプッシュ

resource "aws_codebuild_project" "build" {
  name          = "${var.environment}-build"
  service_role  = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = var.buildspec_content
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "${var.environment}-build"
      status      = "ENABLED"
    }
  }

  tags = {
    Name        = "${var.environment}-build"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.environment}-build"
  retention_in_days = 0

  tags = {
    Name        = "${var.environment}-codebuild-logs"
    Environment = var.environment
  }
}

# S3 Artifact Bucket for Build Pipeline
resource "aws_s3_bucket" "build_artifacts" {
  bucket = "${var.environment}-build-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.environment}-build-artifacts"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "build_artifacts" {
  bucket = aws_s3_bucket.build_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "build_artifacts" {
  bucket = aws_s3_bucket.build_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Build Pipeline: AppRepo → Build → ECR Push
resource "aws_codepipeline" "build_pipeline" {
  name     = "${var.environment}-build-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = aws_s3_bucket.build_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        FullRepositoryId      = "${var.app_repository_owner}/${var.app_repository_name}"
        BranchName            = var.app_repository_branch
        ConnectionArn         = var.codestar_connection_arn
        PollForSourceChanges  = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  tags = {
    Name        = "${var.environment}-build-pipeline"
    Environment = var.environment
  }
}

data "aws_caller_identity" "current" {}

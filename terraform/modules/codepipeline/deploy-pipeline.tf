# Deploy Pipeline Module
# ECR Image → Manual Approval → ECS Deploy

# S3 Artifact Bucket for Deploy Pipeline
resource "aws_s3_bucket" "deploy_artifacts" {
  bucket = "${var.environment}-deploy-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.environment}-deploy-artifacts"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Deploy Pipeline: AppRepo → Manual Approval → ECS Deploy
resource "aws_codepipeline" "deploy_pipeline" {
  name     = "${var.environment}-deploy-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = aws_s3_bucket.deploy_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceTaskDef"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["taskdef_output"]

      configuration = {
        FullRepositoryId      = "${var.app_repository_owner}/${var.app_repository_name}"
        BranchName            = var.app_repository_branch
        ConnectionArn         = var.codestar_connection_arn
        PollForSourceChanges  = "false"
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "ManualApprovalForDeploy"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Please review the task definition and approve to deploy to ECS ${var.ecs_cluster_name}/${var.ecs_service_name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["taskdef_output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "taskdef.json"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-deploy-pipeline"
    Environment = var.environment
  }
}

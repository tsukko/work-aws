# Dev環境の変数値を指定してください
aws_region = "ap-northeast-1"
environment = "dev"
project_name = "my-app"

# GitHub CodeStar リポジトリ情報（実際の値に置き換える）
app_repository_owner = "tsukko"                    # GitHub owner/username
app_repository_name  = "work-ecs-app"              # GitHub repository name
app_repository_branch = "main"                     # Branch name
codestar_connection_arn = "arn:aws:codeconnections:ap-northeast-1:070911817068:connection/e9c3ceaa-c264-4f27-b1e9-dc58e86ac075"

# ネットワーク設定
vpc_cidr_block       = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"
availability_zone    = "ap-northeast-1a"
container_port       = 8080

# ECS設定
task_cpu    = "256"
task_memory = "512"

# CodeBuild設定
codebuild_compute_type = "BUILD_GENERAL1_SMALL"
codebuild_image        = "aws/codebuild/standard:7.0"

# AWS Terraform Infrastructure with CodePipeline ECS Deploy - テスト環境簡素化版

このプロジェクトは、Terraformを使用してAWSにテスト環境を構築し、CodePipelineでECSへの自動デプロイを実現するコード例です。

**コスト削減版**: 月間コスト **$15-20/月** に最適化（削減前: $65-75/月）

## アーキテクチャ概要

```
CodeCommit Repository
         ↓
   CodePipeline（手動実行）
      ↙  ↓  ↖
  Build  ✓  Deploy
  (CodeBuild → ECR)  (ECS Service on Public Subnet)
```

**特徴:**
- ✅ 単一AZ構成（コスト削減）
- ✅ ECS タスク数固定（Auto Scaling 無し）
- ✅ パブリックサブネットのみ（NAT Gateway 不要）
- ❌ ALB 削除（テスト環境なので外部アクセス不要）
- ❌ EventBridge 削除（手動実行に変更）

## ファイル構成

```
terraform/
├── modules/
│   ├── network/          # VPC、ALB、セキュリティグループ
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs/              # ECS クラスター、タスク定義、サービス
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/              # IAMロール・ポリシー
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── codepipeline/     # CodePipeline、CodeBuild
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   └── dev/              # 開発環境設定
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── dev.tfvars
│       └── buildspec.yml
├── Dockerfile.example
├── app.py.example
└── requirements.txt.example
```

## 前提条件

- AWS アカウント
- Terraform >= 1.0
- AWS CLI >= 2.0
- Docker (ローカルテスト用)
- CodeCommit リポジトリ

## セットアップ手順

### 1. CodeCommit リポジトリの準備

```bash
# CodeCommitにリポジトリを作成
aws codecommit create-repository \
  --repository-name my-app-repo \
  --description "My application repository"
```

### 2. Terraform 変数の設定

`terraform/environments/dev/dev.tfvars` を編集して、以下の値を更新します：

```hcl
# AWS アカウントID、リージョン
aws_region = "ap-northeast-1"

# CodeCommit リポジトリ情報
repository_name = "my-app-repo"
repository_arn  = "arn:aws:codecommit:ap-northeast-1:YOUR_ACCOUNT_ID:my-app-repo"

# 必要に応じてリソース名をカスタマイズ
project_name = "my-app"
```

### 3. アプリケーションリポジトリの準備

CodeCommit リポジトリにアプリケーションコードをプッシュします。必要なファイル：

```
my-app-repo/
├── Dockerfile         # 提供の Dockerfile.example を参考に
├── app.py             # 提供の app.py.example を参考に
├── requirements.txt   # 提供の requirements.txt.example を参考に
└── buildspec.yml      # 提供の buildspec.yml を参考に（ただし env.variables を更新）
```

### 4. Terraform の初期化とデプロイ

```bash
cd terraform/environments/dev

# Terraform 初期化
terraform init

# 計画を確認
terraform plan -var-file="dev.tfvars"

# インフラをデプロイ
terraform apply -var-file="dev.tfvars"
```

## デプロイメントフロー

1. **ソースステージ**: CodeCommit へのプッシュを検出
2. **ビルドステージ**: CodeBuild が以下を実行
   - アプリケーションの Docker イメージを構築
   - ECR にイメージをプッシュ
   - `imagedefinitions.json` を生成
3. **デプロイステージ**: ECS がタスク定義を更新し、新しいイメージでデプロイ

## 確認事項

### ECS タスク起動確認

```bash
# ECS クラスターとサービスを確認
aws ecs describe-services \
  --cluster dev-cluster \
  --services dev-service

# タスクが起動しているか確認
aws ecs list-tasks \
  --cluster dev-cluster
```

### ログの確認

```bash
# ECS タスクログ（CloudWatch Logs）
aws logs tail /ecs/dev-app --follow

# CodeBuild ビルドログ
aws logs tail /aws/codebuild/dev-build --follow
```

### パイプライン手動実行

EventBridge を削除したため、パイプラインは手動実行です：

```bash
# CodePipeline 手動実行
aws codepipeline start-pipeline-execution \
  --name dev-pipeline

# パイプライン状態確認
aws codepipeline get-pipeline-state \
  --name dev-pipeline
```

## 設定カスタマイズ

### リソースサイズの変更

`dev.tfvars` で以下を調整：

```hcl
# Fargate タスク仕様
task_cpu    = "256"      # 最小スペック
task_memory = "512"      # 最小スペック

# タスク数は固定（Auto Scaling なし）
# デプロイ確認のみが目的ならば sufficient
```

## ネットワーク設定

```hcl
vpc_cidr_block       = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"      # パブリックのみ
availability_zone    = "ap-northeast-1a"  # 単一AZ
container_port       = 8080
```

## State ファイルのS3管理（推奨）

本番環境では、Terraform State をリモート管理します：

```hcl
# main.tf のコメント部分をアンコメント
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### S3 バケットの準備

```bash
# State 用バケット作成
aws s3api create-bucket \
  --bucket my-terraform-state-bucket \
  --region ap-northeast-1

# バージョニング有効化
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# パブリックアクセスをブロック
aws s3api put-public-access-block \
  --bucket my-terraform-state-bucket \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# DynamoDB テーブル作成（State Lock）
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## トラブルシューティング

### CodePipeline がデプロイに失敗する場合

1. CodeBuild ログを確認
   ```bash
   aws logs tail /aws/codebuild/dev-build --follow
   ```

2. IAM 権限を確認
   - CodeBuild ロール: ECR プッシュ権限
   - CodePipeline ロール: ECS 更新権限

3. buildspec.yml の AWS_ACCOUNT_ID を確認

### ECS タスクが起動しない場合

1. CloudWatch Logs を確認
   ```bash
   aws logs tail /ecs/dev-app --follow
   ```

2. セキュリティグループの設定を確認
   - ECS セキュリティグループはインバウンド 8080 ポートを許可

3. タスク定義のコンテナイメージ URI を確認

### ECR イメージが見つからない場合

```bash
# ECR リポジトリのイメージを確認
aws ecr describe-images --repository-name dev-app
```

## クリーンアップ

インフラを削除する場合：

```bash
cd terraform/environments/dev
terraform destroy -var-file="dev.tfvars"
```

## セキュリティ考慮事項

- **ネットワーク**: ECS タスクはパブリックサブネットで実行（テスト環境用）
- **Log**: CloudWatch Logs 保持期間 0日（削除手動）
- **ECR**: 10イメージ以上は古いものから自動削除
- **S3**: Artifact バケットはパブリックアクセスをブロック

⚠️ **本番環境での使用は想定していません**

## 参考資料

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/best_practices.html)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [コスト分析](COST_ANALYSIS.md)
- [簡素化版の変更点](SIMPLIFICATION_SUMMARY.md)

## ライセンス

MIT License

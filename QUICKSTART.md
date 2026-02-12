# Terraform実行ガイド - クイックスタート（テスト環境簡素化版）

## 📊 月間予想コスト

**約 $15-20/月**（削減前: $65-75/月）

詳細は [COST_ANALYSIS.md](COST_ANALYSIS.md) を参照

## 1. 前提条件の確認

```bash
# AWS CLI が設定されているか確認
aws sts get-caller-identity

# Terraform がインストールされているか確認
terraform version
```

## 2. CodeCommit リポジトリの作成

```bash
# リポジトリ作成
aws codecommit create-repository \
  --repository-name my-app-repo \
  --region ap-northeast-1
```

**注:** 簡素化版では EventBridge を削除したため、パイプラインは手動実行です

## 3. 環境変数の設定

`terraform/environments/dev/dev.tfvars` を編集：

```bash
# dev.tfvars を編集
# - repository_name を実際の値に置き換え
# - buildspec.yml の AWS_ACCOUNT_ID も同様に置き換え
```

## 4. Terraform の実行

```bash
cd terraform/environments/dev

# 初期化
terraform init

# 検証
terraform validate

# 計画確認
terraform plan -var-file="dev.tfvars" -out=tfplan

# 実行
terraform apply tfplan
```

## 5. デプロイメントテスト

```bash
# CodePipeline を手動実行（EventBridge 削除済み）
aws codepipeline start-pipeline-execution \
  --name dev-pipeline

# パイプライン状態確認
aws codepipeline get-pipeline-state --name dev-pipeline
```

## 6. CodeCommit へのアプリケーション푸시

```bash
# リポジトリをクローン
git clone codecommit://my-app-repo ./my-app

cd my-app

# ファイルをコピー
cp ../Dockerfile.example ./Dockerfile
cp ../app.py.example ./app.py
cp ../requirements.txt.example ./requirements.txt
cp ../environments/dev/buildspec.yml ./buildspec.yml

# buildspec.yml の AWS_ACCOUNT_ID を更新
# buildspec.yml の IMAGE_REPO_NAME を更新（dev-app）

# コミット＆プッシュ
git add .
git commit -m "Initial commit"
git push origin main
```

## 7. Pipeline の実行確認

```bash
# CodePipeline 手動実行
aws codepipeline start-pipeline-execution --name dev-pipeline

# パイプラインの状態確認
aws codepipeline get-pipeline-state --name dev-pipeline

# CodeBuild のログ確認
aws logs tail /aws/codebuild/dev-build --follow
```

**注意:** EventBridge を削除したため、CodeCommit へのプッシュでは自動トリガーされません。
パイプラインを実行するときは上記のコマンドを使用してください。

## トラブルシューティングコマンド

```bash
# ECS サービス状態確認
aws ecs describe-services \
  --cluster dev-cluster \
  --services dev-service

# ECS タスクログ確認
aws logs tail /ecs/dev-app --follow

# ECR イメージ確認
aws ecr describe-images --repository-name dev-app

# CodePipeline 失敗理由確認
aws codepipeline get-pipeline-state --name dev-pipeline | jq '.stageStates[] | select(.latestExecution.status=="Failed")'
```

## クリーンアップ

```bash
cd terraform/environments/dev

# リソース削除の確認
terraform plan -destroy -var-file="dev.tfvars"

# リソース削除実行
terraform destroy -var-file="dev.tfvars"
```

## よくある質問

**Q: IAM 権限が不足している場合**
```bash
# 必要な権限
- EC2 (VPC, Subnet, SecurityGroup)
- ECS (Cluster, Service, TaskDefinition)
- ECR (Repository)
- IAM (Role, Policy)
- CodePipeline, CodeBuild
- CloudWatch, S3
- ALB
```

## よくある質問

**Q: IAM 権限が不足している場合**
```bash
# 簡素化版に必要な権限
- EC2 (VPC, Subnet, SecurityGroup - NAT Gateway なし)
- ECS (Cluster, Service, TaskDefinition)
- ECR (Repository)
- IAM (Role, Policy)
- CodePipeline, CodeBuild
- CloudWatch (Logs - Retention 0日)
- S3
# ALB, NAT Gateway 関連の権限は不要
```

**Q: パイプラインが自動実行されない**
```bash
# EventBridge を削除したため、手動実行が必須です
aws codepipeline start-pipeline-execution --name dev-pipeline
```

**Q: 更に低コストにしたい**
```bash
# 開発終了後は destroy で完全削除
terraform destroy -var-file="dev.tfvars"

# 削除後: 0円
```

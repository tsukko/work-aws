# AWS Terraform Project チェックリスト

## デプロイ前の確認

- [ ] AWS アカウント ID を確認
- [ ] 使用するリージョンを決定 (デフォルト: ap-northeast-1)
- [ ] CodeCommit リポジトリを作成
- [ ] IAM ユーザー/ロールが必要な権限を持っているか確認

## Terraform 実行前

- [ ] `terraform/environments/dev/dev.tfvars` を編集
  - [ ] repository_name を修正
  - [ ] repository_arn を修正
  - [ ] project_name をカスタマイズ（必要な場合）
- [ ] `terraform/environments/dev/buildspec.yml` を確認
  - [ ] AWS_ACCOUNT_ID を修正
  - [ ] IMAGE_REPO_NAME を修正
  - [ ] CONTAINER_NAME を確認
- [ ] AWS CLI 認証情報が設定されているか確認

## Terraform 実行

```bash
cd terraform/environments/dev
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

## アプリケーションデプロイメント準備

- [ ] CodeCommit リポジトリにアプリケーションコードを準備
- [ ] 以下のファイルを配置:
  - [ ] Dockerfile
  - [ ] app.py (またはメインアプリケーション)
  - [ ] requirements.txt (または package.json など)
  - [ ] buildspec.yml
- [ ] buildspec.yml が環境変数を正しく参照しているか確認

## デプロイメント実行

- [ ] CodeCommit の main ブランチにプッシュ
- [ ] AWS Console で CodePipeline の実行を確認
  - [ ] Source ステージが成功
  - [ ] Build ステージが成功
  - [ ] Deploy ステージが成功
- [ ] ECS タスクが起動しているか確認
- [ ] ALB 経由でアプリケーションにアクセス可能か確認

## 本番環境への推奨事項

- [ ] Terraform State をS3にリモート保存
  - [ ] terraform backend を設定
  - [ ] DynamoDB テーブルで State Lock を有効化
- [ ] CloudFormation/Terraform で環境を複製
  - [ ] prod.tfvars を作成
  - [ ] 本番環境用の値を設定
- [ ] CloudWatch アラームを設定
- [ ] CloudTrail を有効化
- [ ] IAM ポリシーの最小権限化
- [ ] Secret Manager でシークレット管理
- [ ] VPC Flow Logs を有効化
- [ ] WAF を ALB に追加（必要な場合）

## モニタリング設定

- [ ] CloudWatch Dashboard を作成
- [ ] アラーム設定:
  - [ ] ECS タスク数の異常
  - [ ] CPU/メモリ使用率
  - [ ] ALB ターゲットの障害
- [ ] ログ集約ツール統合（例: ELK, Datadog）

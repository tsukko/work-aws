# デュアルパイプライン設計 - アプリ＆インフラ分離版

テスト環境を2つの独立したパイプラインに分割しました。これにより、**アプリ開発者**と**インフラ開発者**が独立して管理できます。

## 📊 新しいアーキテクチャ

```
【アプリケーション開発者】          【インフラストラクチャー開発者】
┌─────────────────────────┐      ┌──────────────────────────┐
│  work-ecs-app (GitHub)  │      │  work-aws (Terraform)    │
├─────────────────────────┤      ├──────────────────────────┤
│ - Dockerfile            │      │ - Build Pipeline Infra   │
│ - app.py                │      │ - Deploy Pipeline Infra  │
│ - requirements.txt      │      │ - ECS Cluster設定        │
│ - buildspec.yml         │      │ - IAM/Network設定        │
│ - taskdef.json          │      └──────────────────────────┘
└─────────────────────────┘
         ↓ (Git Push)                      ↓ (terraform apply)
    ┌──────────────────────────────────────────────────────────┐
    │       Build Pipeline（インフラ側で管理）                  │
    │                                                            │
    │  AppRepo Push                                              │
    │      ↓                                                     │
    │  Source: work-ecs-app リポジトリをチェックアウト           │
    │      ↓                                                     │
    │  Build: CodeBuild で Docker ビルド                       │
    │      ↓                                                     │
    │  ECR Push: イメージを ECR にプッシュ                      │
    │      ↓                                                     │
    │  ✅ Build Complete                                        │
    └──────────────────────────────────────────────────────────┘
                             ↓
    ┌──────────────────────────────────────────────────────────┐
    │      Deploy Pipeline（手動実行、インフラ側で管理）         │
    │                                                            │
    │  AWSコンソール: 手動実行                                   │
    │      ↓                                                     │
    │  Source: Lambda が work-ecs-app から taskdef.json 取得   │
    │      ↓                                                     │
    │  Approval: 手動で承認                                     │
    │      ↓                                                     │
    │  Deploy: ECS サービス更新                                 │
    │      ↓                                                     │
    │  ✅ Deployment Complete                                   │
    └──────────────────────────────────────────────────────────┘
```

## 🔄 デプロイフロー

### 1️⃣ ビルドフロー（自動）

**開発者のアクション:**
```bash
cd work-ecs-app
# コードを修正
git commit -m "Update application"
git push origin main
```

**自動実行:**
- Build Pipeline が自動トリガー
- Dockerfile を使用してビルド
- ECR にイメージをプッシュ

**結果:**
```
ECR: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/dev-app:abc1234
```

### 2️⃣ デプロイフロー（手動承認）

**インフラ担当者のアクション:**
1. AWS Console → CodePipeline → `dev-deploy-pipeline`
2. 「実行」をクリック
3. ビルド完了を確認
4. Deploy Pipeline の「Approval」ステージで「承認」をクリック
5. ECS 自動デプロイ

## 📁 ファイル構成

### アプリケーション側（`work-ecs-app/`）

```
work-ecs-app/
├── Dockerfile              # コンテナイメージ定義
├── app.py                  # アプリケーション
├── requirements.txt        # Python パッケージ
├── buildspec.yml           # ビルド手順（CodeBuild用）
├── taskdef.json            # ECS タスク定義テンプレート
└── README.md               # アプリ側のドキュメント
```

### インフラ側（`work-aws/terraform/`）

```
work-aws/
├── modules/
│   ├── network/            # VPC, Security Groups
│   ├── ecs/                # ECS Cluster, Service（タスク定義は参照のみ）
│   ├── iam/                # IAM Roles/Policies
│   └── codepipeline/
│       ├── main.tf         # モジュール説明
│       ├── build-pipeline.tf       # ビルドパイプライン
│       ├── deploy-pipeline.tf      # デプロイパイプライン
│       ├── lambda_fetch_taskdef.py # taskdef取得用 Lambda
│       └── variables.tf, outputs.tf
├── environments/dev/       # 開発環境設定
└── modules/iam/           # CodePipeline/CodeBuild 用 IAM
```

## 🛠️ 重要なファイルと役割

| ファイル | 管理者 | 役割 |
|---|---|---|
| `work-ecs-app/Dockerfile` | アプリ開発者 | コンテナイメージ定義 |
| `work-ecs-app/app.py` | アプリ開発者 | アプリケーション |
| `work-ecs-app/buildspec.yml` | アプリ開発者 | ビルド手順 |
| `work-ecs-app/taskdef.json` | アプリ開発者 | ECS タスク定義 |
| `work-aws/terraform/modules/codepipeline/build-pipeline.tf` | インフラ開発者 | ビルドパイプライン管理 |
| `work-aws/terraform/modules/codepipeline/deploy-pipeline.tf` | インフラ開発者 | デプロイパイプライン管理 |

## 💡 メリット

### アプリ開発者側
- ✅ ECS 設定を自由に変更可能（taskdef.json）
- ✅ ビルド方法をカスタマイズ可能（buildspec.yml）
- ✅ アプリとビルド設定を同じリポジトリで管理
- ✅ インフラの詳細な知識不要

### インフラ開発者側
- ✅ パイプライン構成を完全に管理
- ✅ セキュリティポリシー・承認フロー統一
- ✅ 監査・ロギングの一括管理
- ✅ アプリコード変更の影響を排除

## ⚠️ 注意点

### 1. taskdef.json は テンプレート
- アプリ側の `taskdef.json` はテンプレート
- デプロイ時に、インフラ側の IAM ARN を埋め込まれる
- プレースホルダー: `PLACEHOLDER_EXECUTION_ROLE_ARN`, `PLACEHOLDER_TASK_ROLE_ARN`

### 2. buildspec.yml の環境変数
- アプリ側で `AWS_ACCOUNT_ID`, `IMAGE_REPO_NAME` を設定
- インフラ側と統一する必要がある

### 3. イメージタグ規則
- 設定: `git commit hash` をタグに使用
- 例: `dev-app:abc1234` (コミットハッシュ)

## 🚀 実行方法

### 初期セットアップ

```bash
# 1. インフラをデプロイ
cd work-aws/terraform/environments/dev
terraform apply -var-file="dev.tfvars"

# 2. アプリリポジトリを Git にプッシュ
cd work-ecs-app
git push origin main
```

### ビルド＆デプロイ

**Build Pipeline:**
```bash
# 自動トリガー（アプリコード Push 時）
# または手動実行
aws codepipeline start-pipeline-execution \
  --name dev-build-pipeline
```

**Deploy Pipeline:**
```bash
# AWSコンソールで手動実行
# または CLI で手動実行
aws codepipeline start-pipeline-execution \
  --name dev-deploy-pipeline
```

## 📝 トラブルシューティング

### Build Pipeline が失敗する

```bash
# CodeBuild ログ確認
aws logs tail /aws/codebuild/dev-build --follow

# よくある原因:
# - buildspec.yml の AWS_ACCOUNT_ID が未設定
# - Dockerfile が見つからない
```

### Deploy Pipeline が失敗する

```bash
# Lambda ログ確認
aws logs tail /aws/lambda/dev-fetch-taskdef --follow

# よくある原因:
# - taskdef.json が見つからない
# - IAM ARN がインフラ側と一致していない
```

## 🔐 セキュリティ考慮事項

- ✅ アプリ開発者はインフラの詳細にアクセス不可
- ✅ デプロイには手動承認が必須
- ✅ CloudWatch Logs で全操作が記録される
- ⚠️ テスト環境のため、本番用ではセキュリティレビューが必要

---

詳細は各リポジトリの README を参照してください。

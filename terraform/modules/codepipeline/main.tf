# CodePipeline Module
# This module is split into two pipelines:
# 1. build-pipeline.tf: App Repository → Build → ECR Push
# 2. deploy-pipeline.tf: Manual Approval → ECS Deploy

# ローカル開発環境ガイド

AWS にデプロイする前に、ローカル環境で動作確認できます。

## 概要

```
┌─────────────────────────────────────────────────────┐
│              ローカル開発環境                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────┐     ┌─────────────┐               │
│  │  LocalStack │     │  Minecraft  │               │
│  │  (AWS Mock) │     │   Server    │               │
│  │             │     │  (Docker)   │               │
│  │  - S3       │     │             │               │
│  │  - IAM      │     │             │               │
│  └─────────────┘     └─────────────┘               │
│        ↑                   ↑                        │
│        └───────┬───────────┘                        │
│                │                                    │
│         docker-compose                              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**メリット:**
- AWS 料金がかからない
- 本番デプロイ前にテストできる
- 開発サイクルが速い

## セットアップ

### 1. Docker Desktop を起動

Docker Desktop が動作していることを確認。

### 2. LocalStack を起動

```bash
cd localstack
docker-compose up -d
```

### 3. 起動確認

```bash
# LocalStack のステータス確認
curl http://localhost:4566/_localstack/health

# S3 バケット一覧（最初は空）
aws --endpoint-url=http://localhost:4566 s3 ls
```

## ローカルで Minecraft サーバーを起動

### 起動

```bash
cd localstack
ddocker-compose --profile minecraft up -d
```

### 接続

Minecraft クライアントから `localhost:25565` で接続。

## OpenTofu をローカルでテスト

### local.tfvars の設定

```bash
cd tofu
cat environments/local.tfvars
```

```hcl
# ローカル開発用
environment = "local"
localstack_endpoint = "http://localhost:4566"
# ... その他の設定
```

### LocalStack に対して plan/apply

```bash
cd tofu
tofu init
tofu plan -var-file=environments/local.tfvars
tofu apply -var-file=environments/local.tfvars
```

**注意:** LocalStack では EC2 の完全なエミュレーションはできないため、S3 / IAM / Lambda 等の一部サービスのみテスト可能。

## よく使うコマンド

```bash
# LocalStack 起動
cd localstack && docker-compose up -d

# LocalStack 停止
cd localstack && docker-compose down

# Minecraft ログ確認
docker-compose logs -f minecraft

# Minecraft コンソールに接続
docker exec -it localstack-minecraft-1 rcon-cli

# LocalStack の S3 操作
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3 mb s3://test-bucket
```

## トラブルシューティング

### ポートが使用中

```bash
# 使用中のポートを確認
lsof -i :4566
lsof -i :25565

# 既存コンテナを停止
docker-compose down
```

### LocalStack が起動しない

```bash
# ログを確認
docker-compose logs localstack

# 再起動
docker-compose down -v
docker-compose up -d
```

### Minecraft が起動しない

```bash
# ログを確認
docker-compose logs minecraft

# よくある原因:
# - EULA=TRUE が設定されていない
# - メモリ不足（Docker Desktop の設定を確認）
# - ポート競合
```

## 本番との切り替え

```bash
# ローカル開発
tofu plan -var-file=environments/local.tfvars

# 本番デプロイ
tofu plan -var-file=environments/prod.tfvars
```

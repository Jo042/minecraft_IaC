# 技術リファレンス

開発者・将来の自分向けの技術詳細。

## アーキテクチャ概要

```
Discord ユーザー
    ↓ slash command
Lambda（Handler） ← Function URL（署名検証）
    ↓ 非同期呼び出し
Lambda（Worker） → EC2 start/stop / SSM send-command
    ↓ SSM
EC2（Amazon Linux 2023）
    └─ Docker Compose
        ├─ minecraft-server（itzg/minecraft-server）
        └─ Geyser（Bedrock クライアント対応）
```

## インフラ構成（tofu/）

| ファイル | 主なリソース |
|----------|-------------|
| `vpc.tf` | VPC (10.0.0.0/16)、パブリックサブネット (10.0.1.0/24)、IGW |
| `ec2.tf` | t3.medium、30GB gp3 EBS（暗号化）、Elastic IP、IMDSv2 強制 |
| `security_group.tf` | 25565/TCP（Java）、19132/UDP（Geyser）、25575/TCP（RCON、VPC 内のみ） |
| `s3.tf` | バックアップ用（バージョニング有効、30日ライフサイクル）、SSM セッションログ用（1日で自動削除） |
| `iam.tf` | EC2 ロール（S3・SSM・CloudWatch・自己停止）、Lambda ロール（EC2・SSM・CloudWatch） |
| `lambda.tf` | Handler Lambda（30秒）、Worker Lambda（300秒）、Lambda Layer |
| `cloudwatch.tf` | アラーム（CPU >80%、Lambda エラー >5）、ダッシュボード、メトリクスフィルター |

## Lambda 二段構成の設計理由

Discord は Interactions Endpoint に **3秒以内** のレスポンスを要求する。EC2 の起動や SSM コマンドの実行は数十秒かかるため、単一 Lambda では応答できない。

- **Handler Lambda**（タイムアウト 30秒）: 署名検証 → 即座に `200 OK` → Worker を非同期呼び出し
- **Worker Lambda**（タイムアウト 300秒）: 実処理 → Discord Webhook URL に結果を POST

## EC2 アクセスに SSM を採用した理由

- SSH キーペア不要（キー管理・流出リスクをなくす）
- セキュリティグループで SSH ポートを開放不要
- Session Manager 経由のセッションログが S3 に自動保存される
- IAM ポリシーでアクセス制御できる

## デプロイパイプライン

`make deploy` の内部ステップ:

1. `_check-secrets` — `.secrets/credentials.yml` と `tofu/environments/prod.tfvars` の存在確認
2. `_build-layer` — `scripts/build-lambda-layer.sh`（manylinux2014_x86_64 wheels でビルド）
3. `_tofu-apply` — `tofu init -upgrade && tofu apply`
4. `_sync-infra` — `scripts/sync_infra.sh`（Tofu outputs → `ansible/inventory/host_vars/minecraft-server.yml`）
5. `_ansible-setup` — `playbooks/setup.yml`（Docker、CloudWatch エージェント等）
6. `_ansible-deploy` — `playbooks/deploy.yml`（Docker Compose 起動、ヘルスチェック）

## Ansible 構成

```
ansible/
├── inventory/
│   ├── hosts.yml              # SSM プラグインで EC2 に接続
│   ├── group_vars/all/        # 共通変数
│   └── host_vars/             # sync_infra.sh が生成（instance_id 等）
├── playbooks/                 # 各操作のエントリポイント
└── roles/
    ├── common/                # タイムゾーン・パッケージ
    ├── docker/                # Docker インストール
    ├── monitoring/            # CloudWatch エージェント
    └── minecraft/
        ├── tasks/setup.yml    # Docker Compose 配置・起動
        ├── tasks/backup.yml   # backup.sh + cron 設定
        └── tasks/auto-stop.yml # auto-stop.sh + cron（5分毎）
```

接続方式: `aws_ssm` プラグイン経由（SSH キー不要）、ユーザー: `ssm-user`

## CI/CD（.github/workflows/）

### ci.yml（Push / PR）

| ジョブ | 内容 |
|--------|------|
| tofu-validate | `tofu fmt -check` + `tofu validate` |
| python-lint | flake8（max 120文字）+ black チェック |
| python-test | pytest + カバレッジ（モック環境変数を設定） |
| ansible-lint | playbooks + roles のリント |
| security-scan | Gitleaks（シークレット検出）+ tfsec（soft fail） |

### plan.yml（PR → main）

`tofu plan` を実行し、結果を PR コメントに投稿。コンカレンシー制御あり（古い plan は自動キャンセル）。

### deploy.yml（main マージ / 手動）

1. manylinux2014_x86_64 wheels で Lambda Layer をビルド
2. `tofu apply`（GitHub Secrets から認証情報を注入）
3. Discord コマンドを再登録

### GitHub Secrets（CI/CD 利用時に設定が必要）

| Secret 名 | 値 |
|-----------|-----|
| `AWS_ACCESS_KEY_ID` | AWS アクセスキー |
| `AWS_SECRET_ACCESS_KEY` | AWS シークレットキー |
| `DISCORD_PUBLIC_KEY` | Discord Public Key |
| `RCON_PASSWORD` | RCON パスワード |
| `ALERT_EMAIL` | アラートメール（任意） |

## コスト構成

| 状態 | 月額目安 |
|------|----------|
| 起動中 | 約 $30〜40 |
| 停止中 | 約 $7（EBS + Elastic IP） |
| 完全削除後 | $0 |

主なコスト要因: EC2 t3.medium（稼働時間比例）、EBS 30GB gp3（常時）、Elastic IP（停止中も課金）

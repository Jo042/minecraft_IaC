# 運用ガイド

Minecraft サーバーの日常的な運用方法を説明します。

## 基本操作

### サーバーを起動する

```
Discord: /server start
```

または

```bash
# ターミナルから
make ssh
# EC2 内で
cd /opt/minecraft && docker-compose up -d
```

### サーバーを停止する

```
Discord: /server stop
```

**💡 使わない時は停止して節約しましょう！**

### 状態を確認する

```
Discord: /server status
```

または

```bash
make status
```

## バックアップ

### 自動バックアップ

毎日 AM 4:00 (JST) に自動でバックアップされます。

### 手動バックアップ

```
Discord: /server backup
```

### バックアップの確認

```bash
# S3 バケットの中身を確認
aws s3 ls s3://minecraft-prod-backup-xxxxx/ --profile minecraft-prod
```

## サーバー設定の変更

### Minecraft の設定を変更する

1. EC2 に接続

```bash
make ssh
```

2. 設定ファイルを編集

```bash
cd /opt/minecraft
vim docker-compose.yml
```

3. サーバーを再起動

```bash
docker-compose down
docker-compose up -d
```

### よく変更する設定

| 設定 | 環境変数 | 説明 |
|------|----------|------|
| 難易度 | `DIFFICULTY` | peaceful/easy/normal/hard |
| ゲームモード | `MODE` | survival/creative/adventure |
| 最大人数 | `MAX_PLAYERS` | デフォルト 20 |
| メモリ | `MEMORY` | 例: 4G |

## トラブル対応

### サーバーが重い

```bash
make ssh
htop  # CPU/メモリ使用率を確認
docker logs minecraft-server --tail 100  # ログを確認
```

### サーバーに接続できない

1. EC2 が起動しているか確認
   ```
   /server status
   ```

2. Minecraft コンテナが起動しているか確認
   ```bash
   make ssh
   docker ps
   ```

3. ログを確認
   ```bash
   docker logs minecraft-server --tail 50
   ```

## 課金を止める

### 一時停止（データ保持）

```
Discord: /server stop
```

月額: 約 $7（EBS + Elastic IP）

### 完全削除

```bash
make destroy
```

月額: $0

**⚠️ ワールドデータも削除されます！先にバックアップしてください**
```

**📁 ファイル作成: `docs/troubleshooting.md`**

```markdown
# トラブルシューティング

よくある問題と解決方法をまとめています。

## 目次

- [デプロイ時のエラー](#デプロイ時のエラー)
- [Discord Bot のエラー](#discord-bot-のエラー)
- [接続できない](#接続できない)
- [その他](#その他)

---

## デプロイ時のエラー

### 「credentials が見つからない」

```
Error: No valid credential sources found
```

**解決方法:**

```bash
# AWS プロファイルを確認
aws configure list --profile minecraft-prod

# 環境変数を設定
export AWS_PROFILE=minecraft-prod
```

### 「.secrets/credentials.yml が見つからない」

**解決方法:**

```bash
make init
```

### 「Ansible で fork エラー」

```
objc: +[NSPlaceholderNumber initialize] may have been in progress in another thread
```

**解決方法:**

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

または Makefile を使う（自動で設定される）:

```bash
make deploy
```

### 「SSM Agent が接続できない」

```
TargetNotConnected
```

**解決方法:**

1. EC2 が起動しているか確認
2. 5分待って再試行（起動直後は時間がかかる）
3. それでもダメなら EC2 を再起動

```bash
aws ec2 reboot-instances --instance-ids i-xxxxx --profile minecraft-prod
```

---

## Discord Bot のエラー

### 「Interactions endpoint URL is invalid」

**原因:** Lambda がエラーを返している

**解決方法:**

```bash
# Lambda ログを確認
make lambda-logs

# よくある原因:
# - DISCORD_PUBLIC_KEY が間違っている
# - Lambda がデプロイされていない
```

### 「コマンドが表示されない」

**原因:** コマンドが登録されていない

**解決方法:**

```bash
source .secrets/discord.env
make discord-setup
```

**注意:** 反映まで最大1時間かかることがあります

### 「Interaction failed」

**原因:** Lambda でエラー

**解決方法:**

```bash
# ログを確認
make lambda-logs

# よくある原因:
# - EC2 Instance ID が間違っている
# - IAM 権限が不足している
```

---

## 接続できない

### Minecraft クライアントから接続できない

**確認1:** サーバーが起動しているか

```
Discord: /server status
```

**確認2:** IP アドレスが正しいか

`/server status` で表示される IP を使用

**確認3:** ポートが開いているか

```bash
# Security Group を確認
aws ec2 describe-security-groups \
  --profile minecraft-prod \
  --query 'SecurityGroups[].IpPermissions'
```

ポート 25565 が 0.0.0.0/0 に開放されているか確認

### SSM で接続できない

**確認1:** インスタンスが起動しているか

```bash
make status
```

**確認2:** Session Manager プラグインがインストールされているか

```bash
session-manager-plugin --version
```

インストール:
```bash
brew install --cask session-manager-plugin
```

---

## その他

### 予想より課金が高い

**確認:**

```bash
# EC2 が起動しっぱなしでないか
aws ec2 describe-instances \
  --profile minecraft-prod \
  --query 'Reservations[].Instances[].{State:State.Name}'
```

**対策:**
- 使わない時は `/server stop` で停止
- 完全に不要なら `make destroy` で削除

### ワールドデータをバックアップしたい

```bash
# S3 からダウンロード
aws s3 cp s3://minecraft-prod-backup-xxxxx/latest.tar.gz ./backup/ --profile minecraft-prod
```

### 古いバージョンに戻したい

```bash
# S3 のバックアップ一覧
aws s3 ls s3://minecraft-prod-backup-xxxxx/ --profile minecraft-prod

# 特定のバックアップをダウンロード
aws s3 cp s3://minecraft-prod-backup-xxxxx/minecraft_backup_2024xxxx.tar.gz ./
```

---

## それでも解決しない場合

1. GitHub Issue を確認
2. 新しい Issue を作成
3. エラーメッセージとログを添付
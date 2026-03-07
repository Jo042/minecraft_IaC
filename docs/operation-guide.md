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
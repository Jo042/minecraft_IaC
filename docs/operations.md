# 運用ガイド

## 日常操作

### Discord コマンド（推奨）

| コマンド | 内容 |
|----------|------|
| `/server start` | EC2 起動 + Minecraft 起動（2〜3分） |
| `/server stop` | Minecraft 停止 + EC2 停止 |
| `/server status` | 状態・接続先 IP 確認 |
| `/server backup` | 手動バックアップ |
| `/server logs` | サーバーログ表示 |

### make コマンド

```bash
make server-start   # Minecraft コンテナ起動（EC2 起動済みの前提）
make server-stop    # プレイヤー通知 → ワールド保存 → 停止
make backup         # S3 に手動バックアップ
make restore        # S3 から復元（対話形式）
make upgrade        # バージョンアップ（対話形式）
make logs           # サーバーログをリアルタイム表示
make ssh            # EC2 に SSM で接続
make status         # インフラ状態を表示
```

## バックアップ

自動バックアップは毎日 AM 4:00 (JST) に実行。保持期間は 30 日。

### 手動バックアップ

```bash
make backup
```

### バックアップ一覧確認

```bash
BUCKET=$(cd tofu && tofu output -raw backup_bucket_name)
aws s3 ls s3://${BUCKET}/backups/ --profile minecraft-prod
```

### ローカルにダウンロード

```bash
BUCKET=$(cd tofu && tofu output -raw backup_bucket_name)
aws s3 cp s3://${BUCKET}/backups/minecraft_backup_20240301_040000.tar.gz ./ --profile minecraft-prod
```

## リストア

```bash
make restore
```

対話で聞かれる内容:
1. バックアップファイル名（例: `minecraft_backup_20240301_040000.tar.gz`）
2. 確認 → `yes`

処理内容: サーバー停止 → 現データ退避 → S3 からダウンロード → 展開 → サーバー起動

リストア失敗時は退避データから手動復旧できる:

```bash
make ssh
# EC2 上で:
cd /opt/minecraft
docker-compose down
rm -rf data
mv data_before_restore_<timestamp> data
docker-compose up -d
```

## バージョンアップ

```bash
make upgrade
```

対話で聞かれる内容:
1. 新バージョン（例: `1.21.5`）
2. 確認 → `yes`

処理内容: 事前バックアップ → プレイヤー通知（5分前/3分前/1分前）→ 保存 → 停止 → イメージ更新 → 起動

失敗時は `make restore` で直前のバックアップから復元できる。

> バージョンダウンは非推奨（ワールドデータの互換性問題）

## サーバー設定の変更

```bash
make ssh
# EC2 上で:
cd /opt/minecraft
vim docker-compose.yml
docker-compose down && docker-compose up -d
```

よく変更する環境変数:

| 環境変数 | 説明 | 例 |
|----------|------|----|
| `DIFFICULTY` | 難易度 | `peaceful` / `easy` / `normal` / `hard` |
| `MODE` | ゲームモード | `survival` / `creative` |
| `MAX_PLAYERS` | 最大人数 | `20` |
| `MEMORY` | メモリ割り当て | `4G` |
| `WHITELIST` | ホワイトリスト | `true` / `false` |

設定を永続化するには `ansible/inventory/group_vars/all/main.yml` を更新する。

## 課金管理

```bash
# 一時停止（EBS + Elastic IP 約 $7/月）
/server stop  # Discord コマンド

# 完全削除（$0 / 月）※ワールドデータも削除される
make destroy
```

完全削除前にバックアップをダウンロードしておく:

```bash
BUCKET=$(cd tofu && tofu output -raw backup_bucket_name)
aws s3 cp s3://${BUCKET}/backups/minecraft_backup_XXXXXXXX.tar.gz ./ --profile minecraft-prod
```

## トラブルシューティング

### AWS 認証エラー

```
Error: No valid credential sources found
```

```bash
export AWS_PROFILE=minecraft-prod
aws configure list --profile minecraft-prod  # 設定確認
```

### macOS で Ansible が fork エラー

```
objc: +[NSPlaceholderNumber initialize] may have been in progress...
```

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

`make` コマンド経由では自動設定されるため不要。

### SSM 接続エラー（TargetNotConnected）

1. EC2 が起動しているか確認: `make status`
2. 起動直後は 3〜5 分待つ
3. それでも繋がらない場合:
   ```bash
   aws ec2 reboot-instances --instance-ids $(cd tofu && tofu output -raw instance_id) --profile minecraft-prod
   ```

### Discord「Interactions endpoint URL is invalid」

Lambda がエラーを返している。ログを確認:

```bash
make lambda-logs
```

よくある原因: `DISCORD_PUBLIC_KEY` の設定ミス、Lambda 未デプロイ

### Discord コマンドが表示されない

```bash
source .secrets/discord.env
make discord-setup
```

反映まで最大 1 時間かかることがある。

### Minecraft に接続できない

1. `/server status` でサーバー起動確認
2. 表示された IP アドレスを使用しているか確認
3. ポート確認:
   ```bash
   aws ec2 describe-security-groups --profile minecraft-prod \
     --query 'SecurityGroups[].IpPermissions'
   ```
   ポート 25565/TCP が `0.0.0.0/0` に開放されているか確認

### サーバーが重い

```bash
make ssh
# EC2 上で:
htop
docker logs minecraft-server --tail 100
```

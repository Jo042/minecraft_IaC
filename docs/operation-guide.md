# 運用ガイド

Minecraft サーバーの日常的な運用方法を説明します。

## 目次

- [基本操作（Discord）](#基本操作discord)
- [基本操作（Ansible）](#基本操作ansible)
- [バックアップ](#バックアップ)
- [リストア（復元）](#リストア復元)
- [バージョンアップ](#バージョンアップ)
- [サーバー設定の変更](#サーバー設定の変更)
- [課金を止める](#課金を止める)

---

## 基本操作（Discord）

Discord Bot を使った操作。最も簡単な方法。

### サーバーを起動する

```
/server start
```

### サーバーを停止する

```
/server stop
```

### 状態を確認する

```
/server status
```

### 手動バックアップ

```
/server backup
```

---

## 基本操作（Ansible）

Discord Bot を使わず、ターミナルから直接操作する方法。

### 環境変数（毎回必要）

```bash
export AWS_PROFILE=minecraft-prod
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES  # macOS のみ
```

### サーバーを起動する

```bash
cd ansible
ansible-playbook playbooks/start.yml
```

**処理内容:**
- EC2 上で `docker-compose up -d` を実行
- Minecraft コンテナが起動

### サーバーを停止する

```bash
cd ansible
ansible-playbook playbooks/stop.yml
```

**処理内容:**
- プレイヤーに通知（RCON 経由）
- ワールドを保存（`save-all`）
- `docker-compose down` でコンテナ停止

### セットアップをやり直す

```bash
cd ansible

# Docker 等の初期セットアップ
ansible-playbook playbooks/setup.yml

# Minecraft コンテナのデプロイ
ansible-playbook playbooks/deploy.yml
```

---

## バックアップ

### 自動バックアップ

毎日 AM 4:00 (JST) に自動でバックアップされます。

- 保存先: S3 バケット
- 保持期間: 7日間（設定変更可能）

### 手動バックアップ（Discord）

```
/server backup
```

### 手動バックアップ（Ansible）

```bash
cd ansible
ansible-playbook playbooks/backup.yml
```

**処理内容:**
1. プレイヤーに通知
2. ワールドを保存（`save-all`）
3. 書き込み停止（`save-off`）
4. tar.gz で圧縮
5. S3 にアップロード
6. 書き込み再開（`save-on`）

### バックアップの確認

```bash
# S3 バケットの中身を確認
aws s3 ls s3://minecraft-prod-backup-xxxxx/ --profile minecraft-prod
```

---

## リストア（復元）

バックアップからワールドデータを復元します。

### 手順

```bash
cd ansible
ansible-playbook playbooks/restore.yml
```

**対話形式で以下を入力:**

1. **バックアップファイル名**: S3 にあるファイル名を指定
   ```
   例: minecraft_backup_20240301_040000.tar.gz
   ```

2. **確認**: `yes` と入力

**処理内容:**
1. Minecraft サーバーを停止
2. 現在のワールドデータを退避（`world_backup_before_restore`）
3. S3 からバックアップをダウンロード
4. 展開して配置
5. Minecraft サーバーを起動

### バックアップファイルの確認方法

```bash
# 利用可能なバックアップ一覧
aws s3 ls s3://minecraft-prod-backup-xxxxx/ --profile minecraft-prod

# 出力例:
# 2024-03-01 04:00:00  minecraft_backup_20240301_040000.tar.gz
# 2024-03-02 04:00:00  minecraft_backup_20240302_040000.tar.gz
```

### リストア失敗時

退避されたデータから復旧できます:

```bash
# EC2 に接続
make ssh

# 退避データを確認
ls /opt/minecraft/world_backup_before_restore/

# 手動で戻す場合
cd /opt/minecraft
docker-compose down
rm -rf world
mv world_backup_before_restore world
docker-compose up -d
```

---

## バージョンアップ

Minecraft サーバーのバージョンを更新します。

### 手順

```bash
cd ansible
ansible-playbook playbooks/upgrade.yml
```

**対話形式で以下を入力:**

1. **新しいバージョン**: 
   ```
   例: 1.21.5
   ```

2. **確認**: `yes` と入力

**処理内容:**
1. 事前バックアップを作成
2. プレイヤーに通知（5分前、3分前、1分前）
3. ワールドを保存
4. サーバーを停止
5. docker-compose.yml のバージョンを更新
6. 新しいイメージを pull
7. サーバーを起動

### バージョン確認方法

現在のバージョン:
```bash
# EC2 に接続して確認
make ssh
docker exec minecraft-server cat /data/version.txt
```

利用可能なバージョン:
- https://www.minecraft.net/ja-jp/download/server

### バージョンアップ失敗時

事前バックアップから復元できます:

```bash
cd ansible
ansible-playbook playbooks/restore.yml
# バージョンアップ直前のバックアップファイルを指定
```

### 注意事項

- バージョンダウンは非推奨（ワールドデータの互換性問題）
- メジャーバージョンアップ時は事前にバックアップを確認
- MOD やプラグインを使用している場合は互換性を確認

---

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
| シード値 | `SEED` | ワールド生成シード |
| ホワイトリスト | `WHITELIST` | true/false |

### 設定変更を永続化する

Ansible の設定を変更しておくと、再デプロイ時にも反映されます:

```bash
vim ansible/inventory/group_vars/all/main.yml
```

---

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

---

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

**⚠️ ワールドデータも削除されます！先にバックアップをダウンロードしてください:**

```bash
aws s3 cp s3://minecraft-prod-backup-xxxxx/latest.tar.gz ./my-backup.tar.gz --profile minecraft-prod
```

---

## Ansible Playbook 一覧

| Playbook | 用途 | 実行タイミング |
|----------|------|---------------|
| `setup.yml` | EC2 初期セットアップ | 初回デプロイ時 |
| `deploy.yml` | Minecraft デプロイ | 初回・設定変更時 |
| `start.yml` | コンテナ起動 | 手動起動時 |
| `stop.yml` | コンテナ停止 | 手動停止時 |
| `backup.yml` | 手動バックアップ | 任意 |
| `restore.yml` | バックアップから復元 | 障害復旧時 |
| `upgrade.yml` | バージョンアップ | 新バージョンリリース時 |
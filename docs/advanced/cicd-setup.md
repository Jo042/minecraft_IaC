# CI/CD セットアップ（オプション）

このガイドは、GitHub Actions で自動デプロイを設定したい上級者向けです。

**通常の利用には不要です。** `make deploy` で手動デプロイできます。

## 概要

このリポジトリには CI/CD ワークフローが含まれています:

| ワークフロー | トリガー | 内容 |
|--------------|----------|------|
| `ci.yml` | Push/PR | コードチェック（Lint, Validate） |
| `plan.yml` | PR | `tofu plan` を実行して差分をコメント |
| `deploy.yml` | main マージ | 自動デプロイ |

## 設定手順

### 1. リポジトリを Fork

このリポジトリを自分のアカウントに Fork してください。

### 2. GitHub Secrets を設定

リポジトリの Settings → Secrets → Actions で以下を設定:

| Secret 名 | 値 |
|-----------|-----|
| `AWS_ACCESS_KEY_ID` | AWS アクセスキー |
| `AWS_SECRET_ACCESS_KEY` | AWS シークレットキー |
| `DISCORD_PUBLIC_KEY` | Discord Public Key |
| `RCON_PASSWORD` | RCON パスワード |
| `ALERT_EMAIL` | アラートメール（任意） |

### 3. ワークフローを有効化

Fork したリポジトリの Actions タブで:

「I understand my workflows, go ahead and enable them」をクリック

## 使い方

### 通常の開発フロー

1. ブランチを作成
2. コードを変更
3. Push → CI が自動実行
4. PR 作成 → Plan が自動実行、差分がコメントされる
5. レビュー後、main にマージ → 自動デプロイ

### 手動デプロイ

Actions タブ → Deploy → Run workflow

## 注意事項

- Fork した人は自分で Secrets を設定する必要があります
- 元リポジトリの Secrets は使用できません
- AWS 料金は自己負担です
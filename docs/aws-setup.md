# AWS 設定ガイド

AWS アカウントの作成から、デプロイに必要な設定までを説明します。

## 1. AWS アカウント作成

https://aws.amazon.com/jp/

「無料アカウントを作成」から作成してください。

**必要なもの:**
- メールアドレス
- クレジットカード（無料枠でも必要）
- 電話番号（本人確認用）

## 2. IAM ユーザー作成

セキュリティのため、ルートユーザーではなく IAM ユーザーを使用します。

### 手順

1. AWS コンソールにログイン
2. 「IAM」を検索して開く
3. 左メニューの「ユーザー」をクリック
4. 「ユーザーを作成」をクリック

### ユーザー設定

| 設定 | 値 |
|------|-----|
| ユーザー名 | `minecraft-deployer` |
| AWS Management Console へのアクセス | 不要（チェックしない） |

### 権限設定

「ポリシーを直接アタッチする」を選択し、以下にチェック:

- `AdministratorAccess`

**⚠️ 本番環境では最小権限にすべきですが、学習目的ではこれで OK です**

### アクセスキー作成

1. 作成したユーザーをクリック
2. 「セキュリティ認証情報」タブを開く
3. 「アクセスキーを作成」をクリック
4. 「コマンドラインインターフェイス (CLI)」を選択
5. アクセスキーとシークレットキーをメモ

**⚠️ シークレットキーは一度しか表示されません！**

## 3. AWS CLI 設定

```bash
aws configure --profile minecraft-prod
```

入力内容:

```
AWS Access Key ID: あなたのアクセスキー
AWS Secret Access Key: あなたのシークレットキー
Default region name: ap-northeast-1
Default output format: json
```

### 確認

```bash
aws sts get-caller-identity --profile minecraft-prod
```

以下のような出力があれば成功:

```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/minecraft-deployer"
}
```

## 4. Session Manager プラグインのインストール

EC2 への接続に使用します。

### Mac

```bash
brew install --cask session-manager-plugin
```

### 確認

```bash
session-manager-plugin --version
```

## コスト管理

### 請求アラートの設定

1. AWS コンソールで「Billing」を検索
2. 「Billing preferences」をクリック
3. 「Receive Billing Alerts」にチェック
4. 保存

### 無料枠の確認

https://console.aws.amazon.com/billing/home#/freetier

## トラブルシューティング

### 「Unable to locate credentials」と表示される

```bash
# プロファイルが正しく設定されているか確認
aws configure list --profile minecraft-prod

# 環境変数を確認
echo $AWS_PROFILE
```

### リージョンエラー

```bash
# 正しいリージョンが設定されているか確認
aws configure get region --profile minecraft-prod
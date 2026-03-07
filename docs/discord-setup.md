# Discord Bot 設定ガイド

Discord Bot を作成して、サーバーに追加する手順を説明します。

## 1. Discord Developer Portal にアクセス

https://discord.com/developers/applications

Discord アカウントでログインしてください。

## 2. アプリケーションを作成

1. 右上の「New Application」をクリック
2. 名前を入力（例: `Minecraft Server Bot`）
3. 利用規約に同意して「Create」

## 3. 必要な情報をメモ

「General Information」ページで以下をメモしてください:

| 項目 | 説明 |
|------|------|
| APPLICATION ID | アプリケーションの ID |
| PUBLIC KEY | 署名検証に使用 |

**⚠️ これらは後で `make init` で入力します**

## 4. Bot を作成

1. 左メニューの「Bot」をクリック
2. 「Reset Token」をクリック
3. 表示されたトークンをメモ

**⚠️ トークンは一度しか表示されません！必ずメモしてください**

## 5. Bot の設定

以下を設定します:

| 設定 | 値 |
|------|-----|
| PUBLIC BOT | OFF（自分のサーバーのみ） |
| REQUIRES OAUTH2 CODE GRANT | OFF |

## 6. Bot をサーバーに追加

1. 左メニューの「OAuth2」→「URL Generator」をクリック
2. SCOPES で以下にチェック:
   - `bot`
   - `applications.commands`
3. BOT PERMISSIONS で以下にチェック:
   - `Send Messages`
   - `Use Slash Commands`
4. 生成された URL をコピー
5. ブラウザで URL を開く
6. Bot を追加するサーバーを選択
7. 「認証」をクリック

## 7. Interactions Endpoint URL の設定

**⚠️ これは `make discord-setup` 実行後に行います**

1. Discord Developer Portal に戻る
2. 「General Information」をクリック
3. 「INTERACTIONS ENDPOINT URL」に Lambda URL を入力
4. 「Save Changes」をクリック

成功すると設定が保存されます。失敗する場合は:
- URL が正しいか確認
- Lambda が正常にデプロイされているか確認

## トラブルシューティング

### 「Interactions endpoint URL is invalid」と表示される

Lambda がまだデプロイされていないか、エラーが発生しています。

```bash
# Lambda ログを確認
make lambda-logs
```

### コマンドが Discord に表示されない

コマンド登録を再実行してください。

```bash
source .secrets/discord.env
make discord-setup
```

**注意:** コマンドが反映されるまで最大1時間かかることがあります。
"""
Lambda エントリーポイント
Discord からのリクエストを受け取り、処理を振り分ける
"""

import json
import os
from nacl.signing import VerifyKey
from nacl.exceptions import BadSignatureError

from utils.discord_utils import (
    InteractionType,
    InteractionResponseType,
    create_response,
    create_error_response
)
from commands.server import handle_server_command

# 環境変数
DISCORD_PUBLIC_KEY = os.environ.get("DISCORD_PUBLIC_KEY")

def verify_signature(event: dict) -> bool:
    """
    Discord からのリクエストの署名を検証
    
    Discord は全てのリクエストに署名を付与する。
    この署名を検証することで、リクエストが本物の Discord からのものか確認できる。
    
    Args:
        event: API Gateway から渡されるイベント
    
    Returns:
        True: 署名が有効
        False: 署名が無効
    """
    try:
        signature = event["headers"].get("x-signature-ed25519", "")
        timestamp = event["headers"].get("x-signature-timestamp", "")
        body = event.get("body", "")
        
        # 公開鍵で署名を検証
        verify_key = VerifyKey(bytes.fromhex(DISCORD_PUBLIC_KEY))
        verify_key.verify(
            f"{timestamp}{body}".encode(),
            bytes.fromhex(signature)
        )
        return True
    except BadSignatureError:
        return False
    except Exception as e:
        print(f"Signature verification error: {e}")
        return False


def lambda_handler(event: dict, context) -> dict:
    """
    Lambda のエントリーポイント
    
    Args:
        event: API Gateway からのイベント
        context: Lambda コンテキスト
    
    Returns:
        API Gateway 形式のレスポンス
    """
    print(f"Received event: {json.dumps(event)}")
    
    # 署名検証
    if not verify_signature(event):
        print("Invalid signature")
        return {
            "statusCode": 401,
            "body": json.dumps({"error": "Invalid signature"})
        }
    
    # リクエストボディをパース
    try:
        body = json.loads(event.get("body", "{}"))
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid JSON"})
        }
    
    interaction_type = body.get("type")
    
    # PING（Discord からの疎通確認）
    if interaction_type == InteractionType.PING:
        print("Responding to PING")
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"type": InteractionResponseType.PONG})
        }
    
    # スラッシュコマンド
    if interaction_type == InteractionType.APPLICATION_COMMAND:
        command_name = body.get("data", {}).get("name")
        print(f"Handling command: {command_name}")
        
        if command_name == "server":
            response = handle_server_command(body)
        else:
            response = create_error_response(f"Unknown command: {command_name}")
        
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(response)
        }
    
    # その他のインタラクション
    return {
        "statusCode": 400,
        "body": json.dumps({"error": "Unknown interaction type"})
    }
"""
worker.py（Worker）
役割：実際の処理（EC2/SSM） → Discord Webhook に結果を POST
"""
import json
import os
import urllib.request
import urllib.error 
from commands.server import (
    handle_start,
    handle_stop,
    handle_status,
    handle_backup,
    handle_logs
)

DISCORD_APPLICATION_ID = os.environ.get("DISCORD_APPLICATION_ID")

def send_followup_message(token: str, content: dict) -> None:
    """
    Discord の「考え中...」を実際の結果で上書きする

    Args:
        token: interaction の token（body から取り出す）
        content: discord_utils で作った response の "data" 部分
    """
    url = (
        f"https://discord.com/api/v10/webhooks/"
        f"{DISCORD_APPLICATION_ID}/{token}/messages/@original"
    )

    
    print(f"APP_ID: {DISCORD_APPLICATION_ID}")  # ← 追加
    print(f"URL: {url}")                         # ← 追加
    print(f"Content: {json.dumps(content)}")     # ← 追加
    
    # content は discord_utils の response["data"] を渡す
    data = json.dumps(content).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=data,
        method="PATCH",  # ← 上書きなので PATCH
        headers={
            "Content-Type": "application/json",
            "User-Agent": "DiscordBot (https://github.com/minecraft-bot, 1.0.0)"
        }
    )

    try:
        with urllib.request.urlopen(req) as res:
            print(f"Discord webhook response: {res.status}")
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()  
        print(f"HTTP {e.code}: {error_body}")  
    except Exception as e:
        print(f"Failed to send followup: {e}")


def lambda_handler(event: dict, context) -> None:
    """
    Worker のエントリーポイント
    Receiver から body がそのまま渡されてくる
    """
    print(f"Worker received: {json.dumps(event)}")

    # Receiver から渡された Discord の body
    body = event

    token = body.get("token")  # Discord の Interaction Token
    options = body.get("data", {}).get("options", [])
    subcommand = options[0].get("name") if options else None

    print(f"Processing subcommand: {subcommand}")

    # サブコマンドを処理（server.py の関数をそのまま使う）
    handlers = {
        "start":  handle_start,
        "stop":   handle_stop,
        "status": handle_status,
        "backup": handle_backup,
        "logs":   handle_logs
    }

    handler = handlers.get(subcommand)

    if handler:
        subcommand_options = options[0].get("options", []) if options else []
        response = handler(subcommand_options)
    
    else:
        response = {
            "type": 4,
            "data": {"content": f"Unknown subcommand: {subcommand}"}
        }

    # response["data"] を Discord に送って「考え中...」を上書き
    send_followup_message(token, response.get("data", {}))

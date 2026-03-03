"""
server.py - /server コマンドの処理
===================================

/server start  - サーバー起動
/server stop   - サーバー停止
/server status - 状態確認
/server backup - バックアップ
/server logs   - ログ表示
"""

import os
from utils.discord_utils import (
    create_response,
    create_embed_response,
    create_error_response,
    Colors
)
from utils.ec2 import (
    get_instance_status,
    start_instance,
    stop_instance,
)
from utils.ssm import (
    get_minecraft_players,
    run_backup,
    safe_stop_minecraft,
    run_command
)

MINECRAFT_PORT = os.environ.get("MINECRAFT_PORT", "25565")

def handle_server_command(body: dict) -> dict:
    """
    /server コマンドを処理
    
    Args:
        body: Discord からのリクエストボディ
    
    Returns:
        Discord レスポンス
    """
    options = body.get("data", {}).get("options", [])

    if not options:
        return create_error_response("サブコマンドを指定してください")
    
    subcommand = options[0].get("name")
    subcommand_options = options[0].get("options", [])

    # サブコマンドの振り分け
    handlers = {
        "start": handle_start,
        "stop": handle_stop,
        "status": handle_status,
        "backup": handle_backup,
        "logs": handle_logs
    }

    handler = handlers.get(subcommand)
    if handler:
        return handler(subcommand_options)
    else:
        return create_error_response(f"Unknown subcommand: {subcommand}")
    
def handle_start(options: list) -> dict:
    """
    /server start - サーバーを起動
    """
    try:
        status = get_instance_status()
        
        if status["state"] == "running":
            return create_embed_response(
                title="--サーバー状態--",
                description="サーバーは既に起動しています",
                color=Colors.BLUE,
                fields=[
                    {"name": "IP", "value": f"`{status['public_ip']}:{MINECRAFT_PORT}`", "inline": True},
                    {"name": "状態", "value": "🟢 Running", "inline": True}
                ]
            )
        
        if status["state"] == "pending":
            return create_embed_response(
                title="--起動中--",
                description="サーバーは現在起動処理中です。しばらくお待ちください。",
                color=Colors.ORANGE
            )
        
        result = start_instance()

        if result["success"]:
            return create_embed_response(
                title="--サーバー起動開始--",
                description="Minecraft サーバーを起動しています...\n\n"
                           "起動完了まで 2-3 分かかります。\n"
                           "`/server status` で状態を確認してください。",
                color=Colors.GREEN
            )
        else:
            return create_error_response(result["message"])
        
    except Exception as e:
        print(f"Error in handle_start: {e}")
        return create_error_response(f"起動に失敗しました: {str(e)}")
    
def handle_stop(options: list) -> dict:
    """
    /server stop - サーバーを停止
    """
    try:
        status = get_instance_status()
        
        if status["state"] == "stopped":
            return create_embed_response(
                title="--サーバー状態--",
                description="サーバーは既に停止しています",
                color=Colors.BLUE
            )
        
        if status["state"] == "stopping":
            return create_embed_response(
                title="--停止中--",
                description="サーバーは現在停止処理中です。",
                color=Colors.ORANGE
            )
        
        if status["state"] != "running":
            return create_error_response(
                f"サーバーは現在 {status['state']} 状態のため停止できません"
            )
        
        players = get_minecraft_players()
        if players["player_count"] > 0:
            player_list = ", ".join(players["players"]) if players["players"] else "不明"
            return create_embed_response(
                title="==プレイヤーがいます==",
                description=f"現在 {players['player_count']} 人のプレイヤーが接続中です。\n"
                           f"プレイヤー: {player_list}\n\n"
                           f"本当に停止する場合は、先にプレイヤーに通知してください。",
                color=Colors.YELLOW
            )
        
        mc_stop_result = safe_stop_minecraft()
        
        if not mc_stop_result["success"]:
            return create_error_response(mc_stop_result["message"])
        
        result = stop_instance()
        
        if result["success"]:
            return create_embed_response(
                title="🛑 サーバー停止開始",
                description="サーバーを停止しています...\n\n"
                           "完全に停止するまで 1-2 分かかります。",
                color=Colors.GREEN
            )
        else:
            return create_error_response(result["message"])
    
    except Exception as e:
        print(f"Error in handle_stop: {e}")
        return create_error_response(f"停止に失敗しました: {str(e)}")
    
def handle_status(options: list) -> dict:
    """
    /server status - サーバーの状態を確認
    """
    try:
        status = get_instance_status()
        
        # 状態に応じたアイコン
        state_icons = {
            "running": "🟢",
            "stopped": "🔴",
            "pending": "🟡",
            "stopping": "🟠"
        }
        state_icon = state_icons.get(status["state"], "⚪")
        
        fields = [
            {"name": "EC2 状態", "value": f"{state_icon} {status['state']}", "inline": True},
            {"name": "インスタンスタイプ", "value": status["instance_type"], "inline": True}
        ]
        
        # 起動中の場合は追加情報を取得
        if status["state"] == "running":
            ip = status["public_ip"]
            fields.append({"name": "接続先", "value": f"`{ip}:{MINECRAFT_PORT}`", "inline": False})
            
            players = get_minecraft_players()
            
            if players["online"]:
                player_info = f"{players['player_count']}/{players['max_players']} 人"
                if players["players"]:
                    player_info += f"\n {', '.join(players['players'])}"
                fields.append({"name": "プレイヤー", "value": player_info, "inline": False})
                mc_status = "🟢 オンライン"
            else:
                mc_status = "🟡 起動中/準備中"
            
            fields.append({"name": "Minecraft", "value": mc_status, "inline": True})
        
        return create_embed_response(
            title="===サーバーステータス===",
            description="Minecraft サーバーの現在の状態",
            color=Colors.GREEN if status["state"] == "running" else Colors.RED,
            fields=fields
        )
    
    except Exception as e:
        print(f"Error in handle_status: {e}")
        return create_error_response(f"状態取得に失敗しました: {str(e)}")


def handle_backup(options: list) -> dict:
    """
    /server backup - バックアップを実行
    """
    try:
        status = get_instance_status()
        
        if status["state"] != "running":
            return create_error_response(
                "サーバーが起動していないためバックアップできません"
            )
        
        result = run_backup()
        
        if result["success"]:
            return create_embed_response(
                title="--バックアップ完了--",
                description=result["message"],
                color=Colors.GREEN,
                fields=[
                    {"name": "ファイル", "value": result.get("backup_file", "N/A"), "inline": False}
                ]
            )
        else:
            return create_error_response(result["message"])
    
    except Exception as e:
        print(f"Error in handle_backup: {e}")
        return create_error_response(f"バックアップに失敗しました: {str(e)}")
    
def handle_logs(options: list) -> dict:
    """
    /server logs - 直近のログを表示
    """
    try:
        status = get_instance_status()
        
        if status["state"] != "running":
            return create_error_response(
                "サーバーが起動していないためログを取得できません"
            )
        
        # オプションから行数を取得（デフォルト: 10）
        lines = 10
        for opt in options:
            if opt.get("name") == "lines":
                lines = min(opt.get("value", 10), 30)  # 最大30行
        
        # ログを取得
        result = run_command([f"docker logs minecraft-server --tail {lines}"])
        
        if result["success"]:
            logs = result["output"]
            # Discord の文字数制限（2000文字）を考慮
            if len(logs) > 1800:
                logs = logs[-1800:]
                logs = "...(省略)...\n" + logs
            
            return create_embed_response(
                title="--サーバーログ--",
                description=f"```\n{logs}\n```",
                color=Colors.BLUE
            )
        else:
            return create_error_response(f"ログ取得に失敗しました: {result['error']}")
    
    except Exception as e:
        print(f"Error in handle_logs: {e}")
        return create_error_response(f"ログ取得に失敗しました: {str(e)}")
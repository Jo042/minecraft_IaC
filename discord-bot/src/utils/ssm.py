"""
AWS Systems Manager 操作ユーティリティ
SSM Run Command を使って EC2 上でコマンドを実行する
"""

import boto3
import os
import time
from typing import Dict, Any, List

AWS_REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
EC2_INSTANCE_ID = os.environ.get("EC2_INSTANCE_ID")
RCON_PASSWORD = os.environ.get("RCON_PASSWORD", "")


def get_ssm_client():
    """SSM クライアントを取得"""
    return boto3.client("ssm", region_name=AWS_REGION)


def run_command(
    commands: List[str], timeout_seconds: int = 60, wait: bool = True
) -> Dict[str, Any]:
    """
    EC2 インスタンス上でコマンドを実行

    Args:
        commands: 実行するコマンドのリスト
        timeout_seconds: タイムアウト秒数
        wait: コマンド完了を待つかどうか

    Returns:
        {
            "success": True/False,
            "command_id": "...",
            "status": "Success" | "Failed" | "TimedOut",
            "output": "...",
            "error": "..."
        }

    Example:
        run_command(["docker ps", "docker logs minecraft-server"])
    """
    ssm = get_ssm_client()

    # コマンドを送信(実行完了は待たず、command_idで後から結果を取りに行く)
    response = ssm.send_command(
        InstanceIds=[EC2_INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": commands},
        TimeoutSeconds=timeout_seconds,
    )

    command_id = response["Command"]["CommandId"]

    if not wait:
        return {
            "success": True,
            "command_id": command_id,
            "status": "InProgress",
            "output": "",
            "error": "",
        }

    # コマンド完了を待機
    max_attempts = timeout_seconds // 2
    for _ in range(max_attempts):
        time.sleep(2)

        try:
            result = ssm.get_command_invocation(
                CommandId=command_id, InstanceId=EC2_INSTANCE_ID
            )

            status = result["Status"]

            if status in ["Success", "Failed", "TimedOut", "Cancelled"]:
                return {
                    "success": status == "Success",
                    "command_id": command_id,
                    "status": status,
                    "output": result.get("StandardOutputContent", ""),
                    "error": result.get("StandardErrorContent", ""),
                }
        except ssm.exceptions.InvocationDoesNotExist:
            # まだ結果が準備できていない
            continue

    return {
        "success": False,
        "command_id": command_id,
        "status": "TimedOut",
        "output": "",
        "error": "Command execution timed out",
    }


def get_minecraft_players() -> Dict[str, Any]:
    """
    Minecraft サーバーの接続プレイヤー情報を取得

    Returns:
        {
            "success": True/False,
            "online": True/False,
            "player_count": 0,
            "max_players": 20,
            "players": ["player1", "player2"]
        }
    """
    result = run_command(
        [
            f'docker exec minecraft-server rcon-cli --password "{RCON_PASSWORD}" list 2>/dev/null || echo "OFFLINE"'
        ]
    )

    if not result["success"]:
        return {
            "success": False,
            "online": False,
            "player_count": 0,
            "max_players": 0,
            "players": [],
        }

    output = result["output"].strip()

    if "OFFLINE" in output or not output:
        return {
            "success": True,
            "online": False,
            "player_count": 0,
            "max_players": 0,
            "players": [],
        }

    try:
        # "There are X of a max of Y players online: ..."
        parts = output.split("players online:")
        count_part = parts[0]  # "There are 1 of a max of 20 "
        numbers = [int(s) for s in count_part.split() if s.isdigit()]
        player_count = numbers[0]  # 1
        max_players = numbers[1]  # 20

        players = []
        if len(parts) > 1 and parts[1].strip():
            players = [p.strip() for p in parts[1].strip().split(",")]

        return {
            "success": True,
            "online": True,
            "player_count": player_count,
            "max_players": max_players,
            "players": players,
        }
    except Exception:
        return {
            "success": True,
            "online": True,
            "player_count": 0,
            "max_players": 20,
            "players": [],
        }


def run_backup() -> Dict[str, Any]:
    """
    バックアップを実行

    Returns:
        {
            "success": True/False,
            "message": "...",
            "backup_file": "..."
        }
    """
    result = run_command(
        ["/opt/minecraft/backup.sh"], timeout_seconds=300  # バックアップは時間がかかる
    )

    if result["success"]:
        # 出力からバックアップファイル名を抽出
        output = result["output"]
        backup_file = ""
        for line in output.split("\n"):
            if "minecraft_backup_" in line:
                backup_file = line.strip()
                break

        return {
            "success": True,
            "message": "バックアップが完了しました",
            "backup_file": backup_file,
        }
    else:
        return {
            "success": False,
            "message": f"バックアップに失敗しました: {result['error']}",
            "backup_file": "",
        }


def safe_stop_minecraft() -> Dict[str, Any]:
    """
    Minecraft サーバーを安全に停止

    処理:
    1. プレイヤーに通知
    2. ワールドを保存
    3. コンテナを停止

    Returns:
        {
            "success": True/False,
            "message": "..."
        }
    """
    commands = [
        f'docker exec minecraft-server rcon-cli --password "{RCON_PASSWORD}" "say [Server] サーバーを停止します。" || true',
        f'docker exec minecraft-server rcon-cli --password "{RCON_PASSWORD}" "save-all" || true',
        "sleep 5",
        "cd /opt/minecraft && docker compose down",
    ]

    result = run_command(commands, timeout_seconds=120)

    return {
        "success": result["success"],
        "message": (
            "Minecraft サーバーを停止しました"
            if result["success"]
            else f"停止に失敗: {result['error']}"
        ),
    }

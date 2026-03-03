"""
EC2 操作ユーティリティ
EC2 インスタンスの起動、停止、状態確認を行う
"""

import boto3
import os
from typing import Optional, Dict, Any

AWS_REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
EC2_INSTANCE_ID = os.environ.get("EC2_INSTANCE_ID")

def get_ec2_client():
    return boto3.client("ec2", region_name = AWS_REGION)

def get_instance_status() -> Dict[str, Any]:
    """
    EC2 インスタンスの状態を取得
    
    Returns:
        {
            "instance_id": "i-xxxxx",
            "state": "running" | "stopped" | "pending" | "stopping",
            "public_ip": "54.x.x.x" | None,
            "instance_type": "t3.medium",
            "launch_time": datetime
        }
    """
    ec2 = get_ec2_client()
    
    response = ec2.describe_instances(
        InstanceIds=[EC2_INSTANCE_ID]
    )
    
    # レスポンスからインスタンス情報を抽出
    instance = response["Reservations"][0]["Instances"][0]
    
    return {
        "instance_id": instance["InstanceId"],
        "state": instance["State"]["Name"],
        "public_ip": instance.get("PublicIpAddress"), # キーがなければ None を返す
        "instance_type": instance["InstanceType"],
        "launch_time": instance.get("LaunchTime")
    }


def start_instance() -> Dict[str, Any]:
    """
    EC2 インスタンスを起動
    
    Returns:
        {
            "success": True/False,
            "message": "...",
            "current_state": "...",
            "previous_state": "..."
        }
    """
    ec2 = get_ec2_client()
    
    # 現在の状態を確認
    current_status = get_instance_status()
    
    if current_status["state"] == "running":
        return {
            "success": False,
            "message": "インスタンスは既に起動しています",
            "current_state": "running",
            "previous_state": "running"
        }
    
    if current_status["state"] == "pending":
        return {
            "success": False,
            "message": "インスタンスは起動処理中です",
            "current_state": "pending",
            "previous_state": "pending"
        }
    
    # インスタンスを起動
    response = ec2.start_instances(
        InstanceIds=[EC2_INSTANCE_ID]
    )
    
    new_state = response["StartingInstances"][0]["CurrentState"]["Name"]
    prev_state = response["StartingInstances"][0]["PreviousState"]["Name"]
    
    return {
        "success": True,
        "message": "インスタンスを起動しました",
        "current_state": new_state,
        "previous_state": prev_state
    }


def stop_instance() -> Dict[str, Any]:
    """
    EC2 インスタンスを停止
    
    Returns:
        {
            "success": True/False,
            "message": "...",
            "current_state": "...",
            "previous_state": "..."
        }
    """
    ec2 = get_ec2_client()
    
    # 現在の状態を確認
    current_status = get_instance_status()
    
    if current_status["state"] == "stopped":
        return {
            "success": False,
            "message": "インスタンスは既に停止しています",
            "current_state": "stopped",
            "previous_state": "stopped"
        }
    
    if current_status["state"] == "stopping":
        return {
            "success": False,
            "message": "インスタンスは停止処理中です",
            "current_state": "stopping",
            "previous_state": "stopping"
        }
    
    # インスタンスを停止
    response = ec2.stop_instances(
        InstanceIds=[EC2_INSTANCE_ID]
    )
    
    new_state = response["StoppingInstances"][0]["CurrentState"]["Name"]
    prev_state = response["StoppingInstances"][0]["PreviousState"]["Name"]
    
    return {
        "success": True,
        "message": "インスタンスを停止しました",
        "current_state": new_state,
        "previous_state": prev_state
    }

def wait_for_instance_running(timeout: int = 300) -> bool:
    """
    インスタンスが running になるまで待機
    
    Args:
        timeout: タイムアウト秒数
    
    Returns:
        True: 起動成功
        False: タイムアウト
    """
    ec2 = get_ec2_client()
    
    waiter = ec2.get_waiter("instance_running")
    
    try:
        waiter.wait(
            InstanceIds=[EC2_INSTANCE_ID],
            WaiterConfig={
                "Delay": 15,  # 15秒ごとにチェック
                "MaxAttempts": timeout // 15
            }
        )
        return True
    except Exception:
        return False
    
def wait_for_instance_stopped(timeout: int = 300) -> bool:
    """
    インスタンスが stopped になるまで待機
    
    Args:
        timeout: タイムアウト秒数
    
    Returns:
        True: 停止成功
        False: タイムアウト
    """
    ec2 = get_ec2_client()
    
    waiter = ec2.get_waiter("instance_stopped")
    
    try:
        waiter.wait(
            InstanceIds=[EC2_INSTANCE_ID],
            WaiterConfig={
                "Delay": 15,
                "MaxAttempts": timeout // 15
            }
        )
        return True
    except Exception:
        return False
"""
test_handler.py - ハンドラーのテスト
"""

import pytest
import json
from unittest.mock import patch, MagicMock

# テスト用の環境変数を設定
import os
os.environ["DISCORD_PUBLIC_KEY"] = "test_key"
os.environ["EC2_INSTANCE_ID"] = "i-test123"
os.environ["AWS_REGION"] = "ap-northeast-1"


class TestHandler:
    """Lambda ハンドラーのテスト"""
    
    def test_ping_response(self):
        """PING に PONG を返すこと"""
        from src.handler import lambda_handler
        
        # 署名検証をモック
        with patch("src.handler.verify_signature", return_value=True):
            event = {
                "headers": {},
                "body": json.dumps({"type": 1})  # PING
            }
            
            response = lambda_handler(event, None)
            
            assert response["statusCode"] == 200
            body = json.loads(response["body"])
            assert body["type"] == 1  # PONG
    
    def test_invalid_signature(self):
        """無効な署名を拒否すること"""
        from src.handler import lambda_handler
        
        with patch("src.handler.verify_signature", return_value=False):
            event = {
                "headers": {},
                "body": "{}"
            }
            
            response = lambda_handler(event, None)
            
            assert response["statusCode"] == 401


class TestServerCommands:
    """サーバーコマンドのテスト"""
    
    @patch("src.commands.server.get_instance_status")
    def test_status_command(self, mock_status):
        """status コマンドが正しく動作すること"""
        from src.commands.server import handle_status
        
        mock_status.return_value = {
            "instance_id": "i-test123",
            "state": "running",
            "public_ip": "54.1.2.3",
            "instance_type": "t3.medium"
        }
        
        response = handle_status([])
        
        assert response["type"] == 4
        assert "embeds" in response["data"]
        assert "54.1.2.3" in str(response["data"]["embeds"])
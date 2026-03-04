"""
Discord API ヘルパー関数
Discord Interactions API のレスポンス生成などを担当
"""

from enum import IntEnum


class InteractionType(IntEnum):
    """Discord Interaction のタイプ"""

    PING = 1  # Discord からの疎通確認
    APPLICATION_COMMAND = 2  # スラッシュコマンド
    MESSAGE_COMPONENT = 3  # ボタン、セレクトメニュー
    APPLICATION_COMMAND_AUTOCOMPLETE = 4  # オートコンプリート
    MODAL_SUBMIT = 5  # モーダル送信


class InteractionResponseType(IntEnum):
    """Discord への応答タイプ"""

    PONG = 1  # PING への応答
    CHANNEL_MESSAGE_WITH_SOURCE = 4  # メッセージを送信
    DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE = 5  # 「考え中...」を表示して後で更新
    DEFERRED_UPDATE_MESSAGE = 6  # メッセージを後で更新
    UPDATE_MESSAGE = 7  # 既存メッセージを更新


def create_response(content: str, ephemeral: bool = False) -> dict:
    """ "
    通常のテキストレスポンスを作成

    Args:
        content: メッセージ内容
        ephemeral: True なら送信者のみに表示（他の人には見えない）

    Returns:
        Discord API 形式のレスポンス辞書
    """
    response = {
        "type": InteractionResponseType.CHANNEL_MESSAGE_WITH_SOURCE,
        "data": {"content": content},
    }

    if ephemeral:
        response["data"]["flags"] = 64  # EPHEMERAL フラグ

    return response


def create_embed_response(
    title: str,
    description: str,
    color: int = 0x00FF00,  # 緑色
    fields: list = None,
    ephemeral: bool = False,
) -> dict:
    """
    Embed（埋め込み）形式のレスポンスを作成

    Args:
        title: タイトル
        description: 説明文
        color: 埋め込みの色（16進数）
        fields: フィールドのリスト [{"name": "...", "value": "...", "inline": True}, ...]
        ephemeral: 送信者のみに表示

    Returns:
        Discord API 形式のレスポンス辞書
    """
    embed = {"title": title, "description": description, "color": color}

    if fields:
        embed["fields"] = fields

    response = {
        "type": InteractionResponseType.CHANNEL_MESSAGE_WITH_SOURCE,
        "data": {"embeds": [embed]},
    }

    if ephemeral:
        response["data"]["flags"] = 64

    return response


def create_deferred_response() -> dict:
    """
    遅延レスポンスを作成（「Bot is thinking...」を表示）

    時間のかかる処理（EC2起動など）の場合に使用
    Discord は 3 秒以内にレスポンスを求めるため、
    長い処理は「考え中」を返してから後で更新する

    Returns:
        Discord API 形式のレスポンス辞書
    """
    return {"type": InteractionResponseType.DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE}


def create_error_response(message: str) -> dict:
    """
    エラーレスポンスを作成

    Args:
        message: エラーメッセージ

    Returns:
        赤色の埋め込みレスポンス
    """
    return create_embed_response(
        title="エラー", description=message, color=0xFF0000, ephemeral=True  # 赤色
    )


class Colors:
    """Discord の埋め込みで使う色"""

    GREEN = 0x00FF00  # 成功
    RED = 0xFF0000  # エラー
    YELLOW = 0xFFFF00  # 警告
    BLUE = 0x0099FF  # 情報
    ORANGE = 0xFF9900  # 処理中

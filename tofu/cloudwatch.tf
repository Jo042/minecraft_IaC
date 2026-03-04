# ============================================
# cloudwatch.tf - 監視・アラート設定
# ============================================

# --------------------------------------------
# SNS トピック（通知先）
# --------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = local.common_tags
}

# メール通知のサブスクリプション
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --------------------------------------------
# EC2 CPU 使用率アラーム
# --------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  alarm_description   = "EC2 の CPU 使用率が高くなっています"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3      # 3回連続で
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300     # 5分間の平均
  statistic           = "Average"
  threshold           = 80      # 80% を超えたら

  dimensions = {
    InstanceId = aws_instance.minecraft.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# --------------------------------------------
# EC2 ステータスチェックアラーム
# --------------------------------------------
resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${local.name_prefix}-status-check"
  alarm_description   = "EC2 インスタンスのステータスチェックに失敗しています"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    InstanceId = aws_instance.minecraft.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# --------------------------------------------
# Lambda エラーアラーム
# --------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.name_prefix}-lambda-errors"
  alarm_description   = "Discord Bot Lambda でエラーが発生しています"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5  # 5分間に5回以上エラー

  dimensions = {
    FunctionName = aws_lambda_function.discord_bot.function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}


# --------------------------------------------
# Lambda 実行時間アラーム
# --------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${local.name_prefix}-lambda-duration"
  alarm_description   = "Discord Bot Lambda の実行時間が長くなっています"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 10000  # 10秒

  dimensions = {
    FunctionName = aws_lambda_function.discord_bot.function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}


# --------------------------------------------
# 課金アラーム
# --------------------------------------------
resource "aws_cloudwatch_metric_alarm" "billing" {
  count = var.environment == "prod" && var.billing_alarm_threshold > 0 ? 1 : 0

  alarm_name          = "${local.name_prefix}-billing"
  alarm_description   = "AWS の月額料金が閾値を超えています"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600  # 6時間
  statistic           = "Maximum"
  threshold           = var.billing_alarm_threshold

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}


# --------------------------------------------
# CloudWatch ダッシュボード
# --------------------------------------------
resource "aws_cloudwatch_dashboard" "minecraft" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # EC2 CPU 使用率
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 CPU 使用率"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.minecraft.id]
          ]
          period = 300
          stat   = "Average"
        }
      },
      
      # EC2 ネットワーク
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 ネットワーク I/O"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.minecraft.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.minecraft.id]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      
      # Lambda 呼び出し回数
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Discord Bot 呼び出し回数"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.discord_bot.function_name]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      
      # Lambda エラー
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Discord Bot エラー"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.discord_bot.function_name]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      
      # Lambda 実行時間
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Discord Bot 実行時間"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.discord_bot.function_name]
          ]
          period = 300
          stat   = "Average"
        }
      },
      
      # アラーム状態
      {
        type   = "alarm"
        x      = 0
        y      = 12
        width  = 24
        height = 4
        properties = {
          title  = "アラーム状態"
          alarms = [
            aws_cloudwatch_metric_alarm.cpu_high.arn,
            aws_cloudwatch_metric_alarm.status_check.arn,
            aws_cloudwatch_metric_alarm.lambda_errors.arn
          ]
        }
      }
    ]
  })
}



# --------------------------------------------
# Minecraft サーバーログ用 Log Group
# --------------------------------------------
resource "aws_cloudwatch_log_group" "minecraft" {
  name              = "/minecraft/server"
  retention_in_days = 14

  tags = local.common_tags
}

# --------------------------------------------
# メトリクスフィルター（ログからメトリクスを抽出）
# --------------------------------------------

# プレイヤー参加のカウント
resource "aws_cloudwatch_log_metric_filter" "player_joined" {
  name           = "${local.name_prefix}-player-joined"
  log_group_name = aws_cloudwatch_log_group.minecraft.name
  pattern = "\"joined the game\""

  metric_transformation {
    name      = "PlayerJoined"
    namespace = "Minecraft"
    value     = "1"
  }
}

# プレイヤー退出のカウント
resource "aws_cloudwatch_log_metric_filter" "player_left" {
  name           = "${local.name_prefix}-player-left"
  log_group_name = aws_cloudwatch_log_group.minecraft.name
  pattern = "\"left the game\""

  metric_transformation {
    name      = "PlayerLeft"
    namespace = "Minecraft"
    value     = "1"
  }
}

# エラーのカウント
resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${local.name_prefix}-errors"
  log_group_name = aws_cloudwatch_log_group.minecraft.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "Errors"
    namespace = "Minecraft"
    value     = "1"
  }
}
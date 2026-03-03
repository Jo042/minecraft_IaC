# --------------------------------------------
# Lambda 用 IAM ロール
# --------------------------------------------
resource "aws_iam_role" "discord_bot" {
  name = "${local.name_prefix}-discord-bot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# CloudWatch Logs への書き込み権限
resource "aws_iam_role_policy_attachment" "discord_bot_logs" {
  role       = aws_iam_role.discord_bot.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# EC2 操作権限
resource "aws_iam_role_policy" "discord_bot_ec2" {
  name = "${local.name_prefix}-discord-bot-ec2-policy"
  role = aws_iam_role.discord_bot.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2StartStop"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = aws_instance.minecraft.arn
      }
    ]
  })
}

# SSM 操作権限
resource "aws_iam_role_policy" "discord_bot_ssm" {
  name = "${local.name_prefix}-discord-bot-ssm-policy"
  role = aws_iam_role.discord_bot.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMSendCommand"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# --------------------------------------------
# Lambda 関数用の ZIP ファイル
# --------------------------------------------
data "archive_file" "discord_bot" {
  type        = "zip"
  source_dir  = "${path.module}/../discord-bot/src"
  output_path = "${path.module}/../discord-bot/dist/discord_bot.zip"
}

# --------------------------------------------
# Lambda 関数
# --------------------------------------------
resource "aws_lambda_function" "discord_bot" {
  function_name = "${local.name_prefix}-discord-bot"
  description   = "Discord Bot for Minecraft Server"

  filename         = data.archive_file.discord_bot.output_path
  source_code_hash = data.archive_file.discord_bot.output_base64sha256

  handler = "handler.lambda_handler"
  runtime = "python3.11"

  role = aws_iam_role.discord_bot.arn

  timeout     = 30
  memory_size = 256

  # Layer を追加
  layers = [
    aws_lambda_layer_version.discord_bot_deps.arn
  ]

  environment {
    variables = {
      DISCORD_PUBLIC_KEY = var.discord_public_key
      EC2_INSTANCE_ID    = aws_instance.minecraft.id
      AWS_REGION_NAME    = var.aws_region
      MINECRAFT_PORT     = tostring(var.minecraft_port)
      RCON_PASSWORD      = var.rcon_password
      WORKER_FUNCTION_NAME = aws_lambda_function.discord_bot_worker.function_name
    }
  }

  tags = local.common_tags
}

# --------------------------------------------
# Worker Lambda
# --------------------------------------------
resource "aws_lambda_function" "discord_bot_worker" {
  function_name = "${local.name_prefix}-discord-bot-worker"
  description   = "Worker: EC2/SSM処理 + Discord Webhook送信"

  filename         = data.archive_file.discord_bot_worker.output_path
  source_code_hash = data.archive_file.discord_bot_worker.output_base64sha256

  handler = "worker.lambda_handler"
  runtime = "python3.11"

  role = aws_iam_role.discord_bot.arn  # ← 同じ IAM ロールを使い回す

  timeout     = 300   
  memory_size = 256

  layers = [
    aws_lambda_layer_version.discord_bot_deps.arn
  ]

  environment {
    variables = {
      EC2_INSTANCE_ID       = aws_instance.minecraft.id
      AWS_REGION_NAME       = var.aws_region
      MINECRAFT_PORT        = tostring(var.minecraft_port)
      RCON_PASSWORD         = var.rcon_password
      DISCORD_APPLICATION_ID = var.discord_application_id  # ← 新規変数（後述）
    }
  }

  tags = local.common_tags
}


# --------------------------------------------
# Lambda 関数 URL（
# --------------------------------------------

resource "aws_lambda_function_url" "discord_bot" {
  function_name      = aws_lambda_function.discord_bot.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["*"]
  }
}

# --------------------------------------------
# CloudWatch Logs
# --------------------------------------------
resource "aws_cloudwatch_log_group" "discord_bot" {
  name              = "/aws/lambda/${aws_lambda_function.discord_bot.function_name}"
  retention_in_days = 14

  tags = local.common_tags
}


# --------------------------------------------
# Lambda Layer（依存パッケージ）
# --------------------------------------------
resource "aws_lambda_layer_version" "discord_bot_deps" {
  filename            = "${path.module}/../discord-bot/dist/lambda_layer.zip"
  layer_name          = "${local.name_prefix}-discord-bot-deps"
  compatible_runtimes = ["python3.11"]
  
  source_code_hash = filebase64sha256("${path.module}/../discord-bot/dist/lambda_layer.zip")

  description = "Dependencies for Discord Bot (PyNaCl, boto3, etc.)"
}



# --------------------------------------------
# 既存 IAM ロールに Lambda 呼び出し権限を追加
# （Receiver が Worker を呼べるようにする）
# --------------------------------------------
resource "aws_iam_role_policy" "discord_bot_invoke_worker" {
  name = "${local.name_prefix}-discord-bot-invoke-worker-policy"
  role = aws_iam_role.discord_bot.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeWorkerLambda"
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        # Worker Lambda の ARN を直接参照
        Resource = aws_lambda_function.discord_bot_worker.arn
      }
    ]
  })
}

# --------------------------------------------
# Worker Lambda 用 ZIP
# （src フォルダは Receiver と共用）
# --------------------------------------------
data "archive_file" "discord_bot_worker" {
  type        = "zip"
  source_dir  = "${path.module}/../discord-bot/src"
  output_path = "${path.module}/../discord-bot/dist/discord_bot_worker.zip"
}


# --------------------------------------------
# Worker Lambda の CloudWatch Logs
# --------------------------------------------
resource "aws_cloudwatch_log_group" "discord_bot_worker" {
  name              = "/aws/lambda/${aws_lambda_function.discord_bot_worker.function_name}"
  retention_in_days = 14

  tags = local.common_tags
}
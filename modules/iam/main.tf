resource "aws_iam_role" "lambda_guardduty_role" {
  name = "lambda_guardduty_isolation_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_policy" "lambda_guardduty_policy" {
  name = "LambdaGuardDutyIsolationPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:ModifyInstanceAttribute"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_guardduty_role.name
  policy_arn = aws_iam_policy.lambda_guardduty_policy.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_guardduty_role.arn
}

resource "aws_iam_policy" "lambda_log_policy" {
  name = "LambdaLoggingPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_log_policy.arn
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "bedrock_invoke_policy" {
  name = "SecureScrapeX-BedrockInvoke"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel"
        ],
        Resource = "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-v2"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_bedrock_policy" {
  role = aws_iam_role.lambda_guardduty_role.name
  policy_arn = aws_iam_policy.bedrock_invoke_policy.arn
}

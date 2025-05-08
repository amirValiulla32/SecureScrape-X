resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/GuardDutyIsolateInstance"
  retention_in_days = 7
}

resource "aws_lambda_function" "gd_remediation_lambda" {
  function_name = "GuardDutyIsolateInstance"
  role          = var.lambda_role_arn
  handler       = "isolate_instance.lambda_handler"
  runtime       = "python3.11"
  timeout       = 10
  environment {
      variables = {
        ENVIRONMENT = var.environment
      }
    }

  filename         = "${path.module}/../../lambda/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambda/lambda.zip")
}

output "lambda_function_arn" {
  value = aws_lambda_function.gd_remediation_lambda.arn
}

variable "lambda_role_arn" {
  description = "IAM role ARN for the Lambda"
  type        = string
}
variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

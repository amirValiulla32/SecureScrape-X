output "lambda_execution_role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}

output "lambda_guardduty_role_arn" {
  value = aws_iam_role.lambda_guardduty_role.arn
}

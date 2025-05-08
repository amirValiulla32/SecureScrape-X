resource "aws_cloudwatch_event_rule" "gd_exfiltration_rule" {
  name = "guardduty-exfiltration"
  event_pattern = jsonencode({
    source = ["aws.guardduty"],
    detail-type = ["GuardDuty Finding"],
    detail = {
      type = ["UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS"]
    }
  })
}

resource "aws_cloudwatch_event_target" "gd_target_lambda" {
  rule      = aws_cloudwatch_event_rule.gd_exfiltration_rule.name
  target_id = "SendToLambda"
  arn       = var.lambda_function_arn
}


variable "lambda_function_arn" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "GuardDutyHighSeverity"
  description = "Trigger Lambda on high severity GuardDuty findings"
  event_pattern = jsonencode({
    source = ["aws.guardduty"],
    detail = {
      type = ["UnauthorizedAccess:InstanceCredentialExfiltration.OutsideAWS"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToLambda"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}


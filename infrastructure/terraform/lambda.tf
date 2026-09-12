data "archive_file" "api" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/yatoca-api/index.mjs"
  output_path = "${path.module}/.yatoca-api.zip"
}

resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-api"
  role          = aws_iam_role.api_lambda.arn

  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256

  runtime       = "nodejs22.x"
  architectures = ["arm64"]
  handler       = "index.handler"
  memory_size   = 128
  timeout       = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.feedback.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.feedback_table,
  ]
}

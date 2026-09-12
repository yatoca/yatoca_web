resource "aws_dynamodb_table" "feedback" {
  name                        = var.feedback_table_name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  range_key                   = "sk"
  deletion_protection_enabled = true

  point_in_time_recovery {
    enabled                 = true
    recovery_period_in_days = 35
  }

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }
}

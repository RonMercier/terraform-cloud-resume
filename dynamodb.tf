resource "aws_dynamodb_table" "visitor_count" {
  name         = "visitorCount"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  deletion_protection_enabled = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_codecommit_repository" "source" {
  count    = var.enable_codecommit ? 1 : 0
  provider = aws.codecommit

  repository_name = var.codecommit_repository_name
  description     = "Yatoca web source repository"
}

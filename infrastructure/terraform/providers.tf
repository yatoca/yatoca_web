provider "aws" {
  region = var.aws_region
}

# CloudFront requires ACM certificates to live in us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Current source repository is in us-east-2. Creation is optional because
# some new AWS accounts may not have CodeCommit available.
provider "aws" {
  alias  = "codecommit"
  region = var.codecommit_region
}

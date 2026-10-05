# terraform-cloud-resume

Terraform for the AWS infrastructure behind my portfolio site, ron-mercier101.com. The stack was originally built with AWS SAM and the console. This repo brings all of it under Terraform with remote state, with no downtime.

## What it manages

- **Backend:** DynamoDB table, Lambda function and its IAM role, HTTP API Gateway (integration, route, stage), Lambda invoke permission
- **Frontend:** S3 bucket (versioning, website config, policy), CloudFront distribution, Route 53 alias records, ACM validation records
- **Read-only references:** the Route 53 hosted zone is a data source, not a managed resource, so a mistake here can't take the domain offline

## How it was built: import first, improve second

Every resource already existed, so each one was written to match reality, imported, and checked with `terraform plan` until it said "No changes" before anything was changed on purpose. That kept the live site up the whole time and made every improvement a small, reviewable diff.

Findings from that process:

- Two extra API Gateway routes (`ANY /` and `ANY /{proxy+}`) and a Lambda invoke permission covering every path and method existed outside the SAM template. They weren't used by the site, so they were removed and the endpoint was re-verified with curl.

## Layout

    bootstrap/      creates the S3 state bucket and DynamoDB lock table (run once, local state)
    backend.tf      empty S3 backend block, settings come from backend.hcl
    providers.tf    AWS provider
    variables.tf    inputs
    iam.tf, lambda.tf, lambda_permissions.tf, dynamodb.tf, api_gateway.tf
    s3.tf, cloudfront.tf, route53.tf

## Notes

- Lambda code is deployed by a separate SAM and GitHub Actions pipeline. Terraform manages the function's configuration and ignores code changes, so the two tools don't fight.
- Bucket objects are deployed by a separate pipeline too. Terraform manages the bucket's settings, not its contents.

## Running it

The backend settings and certificate ARN are kept out of git.

1. Create `backend.hcl` with `bucket`, `key`, `region`, `dynamodb_table`, and `encrypt` for your state bucket.
2. Create `terraform.tfvars` with `acm_certificate_arn` (a certificate in us-east-1).
3. Create the placeholder the Lambda resource needs for schema validation:

        echo placeholder > placeholder.txt && zip placeholder.zip placeholder.txt

4. Run:

        terraform init -backend-config=backend.hcl
        terraform plan

## Not in the repo

State files, `backend.hcl`, `terraform.tfvars`, and credentials, all covered by `.gitignore`.

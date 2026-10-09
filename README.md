# terraform-cloud-resume

> **Important:** This repository began by matching an existing live AWS environment so it could be imported into Terraform without downtime. Some configuration intentionally reflects legacy settings that are being improved in later phases. Treat this repository as a migration case study, not a reference architecture to copy unchanged.

Terraform for the AWS infrastructure behind my portfolio site, [ron-mercier101.com](https://ron-mercier101.com). The stack was originally built with AWS SAM and the console. This repo brings the infrastructure configuration under Terraform with remote state, without rebuilding anything and without downtime.

The write-up: *Importing My Cloud Resume into Terraform Without Taking the Site Down* on [SecureByDefault.io](https://securebydefault.io).

## Project purpose

Show the process of adopting live infrastructure into Terraform safely: write config that matches reality, import, plan until clean, and only then improve. It is not a from-scratch Cloud Resume Challenge tutorial.

## Architecture

<img width="3620" height="2144" alt="architecture-overview" src="https://github.com/user-attachments/assets/1137c6c6-98c7-4916-bdd9-2669d64c9a96" />

- **Frontend path:** Route 53 (apex and `www`, A and AAAA aliases) to CloudFront to an S3 bucket, using the bucket's website endpoint as the origin.
- **Backend path:** Browser to API Gateway (HTTP API, `GET /count`) to Lambda to DynamoDB.

## Deployment ownership

Terraform does not own everything. This is deliberate.

<img width="3277" height="2146" alt="ownership-map" src="https://github.com/user-attachments/assets/acb65602-bc2e-470a-839b-689d5e867347" />

| Layer | Owner |
|---|---|
| Infrastructure configuration (DynamoDB, IAM role, Lambda settings, API Gateway, S3 bucket settings, CloudFront, Route 53 records) | This repo (Terraform) |
| Lambda application code | [cloud-resume-backend](https://github.com/RonMercier/cloud-resume-backend) (SAM and GitHub Actions) |
| Website files in the bucket | [AWS-S3-Static-Website](https://github.com/RonMercier/AWS-S3-Static-Website) (GitHub Actions) |

The Lambda resource uses a placeholder `filename` and `lifecycle { ignore_changes = [filename, source_code_hash] }`, so Terraform manages configuration while the pipeline manages code.

The SAM-created CloudFormation stack (`portfolio-app`) still exists and still tracks some of the same resources, and the SAM template does not currently match the live API (see the backend repo README). Until that is reconciled, avoid changing those resources from both tools.

The Route 53 hosted zone is a data source, not a managed resource. The ACM validation records are managed with `prevent_destroy`.

## Import methodology

`Inspect → Describe → Import → Plan → Match → Verify → Improve`

1. **Inspect** the live resource with the AWS CLI.
2. **Describe** it by writing Terraform that matches it.
3. **Import** it with `terraform import`.
4. **Plan**, and read every line.
5. **Match**: if the plan shows an unexpected difference, change the configuration to match the live resource.
6. **Verify**: a clean plan ("No changes") is the baseline.
7. **Improve**: make intentional changes only after the baseline is clean, one small diff at a time.

<img width="2373" height="319" alt="import-flow" src="https://github.com/user-attachments/assets/6621d523-ddd0-4c33-8e6c-7515fe6be237" />

`terraform import` records an existing resource in state. It does not generate configuration and it does not change the resource.

Findings from the process:

- Two extra API Gateway routes (`ANY /` and `ANY /{proxy+}`) and a Lambda invoke permission covering every path and method existed outside the SAM template. The site did not use them. They were removed through Terraform and the endpoint was re-verified from outside: `GET /count` works, other paths and methods return 404.
- The DynamoDB tags (`Project`, `Environment`) were added before the first clean plan, a small deliberate exception to the rule above.

## Important migration note

These settings were imported as they were, and are candidates for later phases:

- CloudFront reaches S3 through the bucket's website endpoint over HTTP, with a `Referer` header and a matching bucket policy. The bucket's public access block is not enabled.
- CloudFront `http_version` is `http1.1`.
- The CloudFront `Name` tag has a leading space (matched exactly to keep the plan clean).
- Three ACM certificates exist for the domain; two are expired and unused. Only one is attached to CloudFront.
- The API CORS configuration allows two origins.

Planned hardening (Part 2, **not deployed**): Origin Access Control with a private S3 origin, certificate cleanup, and Terraform plans on pull requests.

## State management

- Remote state in S3 (versioned, encrypted, public access blocked), created by `bootstrap/`.
- State locking currently uses a DynamoDB table (`dynamodb_table`). Terraform now reports this parameter as deprecated, and current versions of the S3 backend support native locking with `use_lockfile = true`. Moving to that is a planned improvement, not done. New setups should evaluate `use_lockfile` first.
- The committed backend block is empty (`backend "s3" {}`). Settings come from a local, ignored `backend.hcl`.

## Security

- `.gitignore` excludes state files, `.terraform/`, `*.tfvars`, `backend.hcl`, `crash.log` and the placeholder zip.
- No credentials are stored in this repo. Do not commit access keys, session tokens or state.
- State files can contain sensitive values. Keep them in the private remote backend only.
- AWS account IDs are not credentials, but they are kept out of the code anyway (the bootstrap uses an `aws_caller_identity` data source). The ID appears once in early commit history; I chose not to rewrite history for a non-secret.
- Before every commit: `grep` for account IDs and `AKIA`/`ASIA` key prefixes.
- Pushing from a server uses an SSH deploy key scoped to this one repository.
- For a fresh setup, prefer short-lived credentials (IAM Identity Center or an assumed role) over long-term IAM user keys. The migration itself used a dedicated IAM user.

## Layout

```
bootstrap/      creates the S3 state bucket and DynamoDB lock table (run once, local state)
backend.tf      empty S3 backend block, settings come from backend.hcl
providers.tf    AWS provider
variables.tf    inputs
iam.tf, lambda.tf, lambda_permissions.tf, dynamodb.tf, api_gateway.tf
s3.tf, cloudfront.tf, route53.tf
```

## Running it

The backend settings and certificate ARN are kept out of git.

1. Create `backend.hcl` with `bucket`, `key`, `region`, `dynamodb_table` and `encrypt` for your state bucket.
2. Create `terraform.tfvars` with `acm_certificate_arn` (a certificate in us-east-1).
3. Create the placeholder the Lambda resource needs for schema validation:

   ```bash
   echo placeholder > placeholder.txt && zip placeholder.zip placeholder.txt
   ```

4. Run:

   ```bash
   terraform init -backend-config=backend.hcl
   terraform plan
   ```

Read the plan for the word "destroy" before any apply.

## Related repositories

- [cloud-resume-backend](https://github.com/RonMercier/cloud-resume-backend): Lambda code, SAM template, backend CI/CD
- [AWS-S3-Static-Website](https://github.com/RonMercier/AWS-S3-Static-Website): website files, frontend CI/CD

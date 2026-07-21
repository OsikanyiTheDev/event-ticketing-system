# Deployment Runbook

End-to-end instructions for deploying the Event Registration & Ticketing System
from a clean AWS account.

## Prerequisites

| Requirement | Check |
|-------------|-------|
| AWS account + admin access | `aws sts get-caller-identity` |
| AWS CLI configured | `aws configure` |
| Terraform ≥ 1.10 | `terraform --version` |
| Python 3.12 + venv | `python3 --version` |
| S3 state bucket exists | see [Step 1](#1-one-time-state-backend) |

---

## 1. One-time state backend

Terraform stores state in an S3 bucket. Create it once (skip if it exists):

```bash
BUCKET="yourname-terraform-state-2026"   # globally unique
aws s3api create-bucket --bucket $BUCKET --region us-east-1
aws s3api put-bucket-versioning --bucket $BUCKET \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket $BUCKET \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

Then set the bucket name in `terraform/environments/dev/versions.tf` (the
`backend "s3"` block).

## 2. Configure environment settings

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars:
#   notification_email = "<your real email>"   ← receives SNS + alarms + budgets
#   monthly_budget_usd = "5.00"
```

## 3. Deploy the infrastructure

```bash
terraform init      # connects to S3 backend, downloads providers + modules
terraform plan      # review (~40 resources)
terraform apply     # type 'yes' — creates DynamoDB, IAM, Lambda, API GW, SNS, alarms, budget
terraform output    # note api_url, table names
```

## 4. Confirm subscriptions (one-time)

`terraform apply` sends confirmation emails to `notification_email`:
1. **SNS confirmation topic** — click "Confirm subscription" → enables registration emails
2. **SNS alarm topic** — click "Confirm subscription" → enables alarm emails

(Budgets email directly — no confirmation needed.)

Verify:
```bash
aws sns list-subscriptions-by-topic --topic-arn "$(terraform output -raw sns_topic_arn)"
# SubscriptionArn should NOT say "PendingConfirmation"
```

## 5. Seed sample events

```bash
cd ../../..
source .venv/bin/activate
python scripts/seed_events.py "$(terraform -chdir=terraform/environments/dev output -raw events_table_name)"
```

## 6. Test the live API

```bash
API=$(terraform -chdir=terraform/environments/dev output -raw api_url)

curl -s "$API/events" | python3 -m json.tool                                   # list events
curl -s -X POST "$API/register" -H "Content-Type: application/json" \
  -d '{"event_id":"aws-bootcamp","email":"you@example.com","name":"You"}'      # register
curl -s "$API/registrations/you@example.com" | python3 -m json.tool            # view yours
```
Check your inbox for the confirmation email 📧

---

## Tear down (cost safety)

```bash
cd terraform/environments/dev
terraform destroy     # removes ALL app resources (keeps the state bucket)
```

> The S3 state bucket is NOT destroyed by `terraform destroy` (it's outside
> the stack). Delete it manually only when you're done with the project:
> ```bash
> aws s3 rb s3://$BUCKET --force
> ```

---

## Cost Optimization (how this stays in Free Tier)

| Strategy | Where |
|----------|-------|
| **DynamoDB on-demand** (pay per request, idle = free) | `modules/dynamodb` `PAY_PER_REQUEST` |
| **Lambda 128 MB** (smallest, cheapest) | `modules/lambda_function` default |
| **Log retention 14 days** (no infinite log growth) | `modules/lambda_function` `log_retention_in_days` |
| **API Gateway** (pay per call, idle = free) | REST API, serverless |
| **AWS Budget $5/mo** with 50% + 100% alerts | `modules/budgets` |
| **Daily `terraform destroy`** between dev sessions | operational habit |

All resources use **serverless** services (no always-on servers), so an idle
deployment costs ~$0. The only standing cost is the S3 state bucket's storage
(pennies).

## Resource Lifecycle Policies

- **CloudWatch Logs**: 14-day retention (auto-deleted after) → prevents log cost creep
- **DynamoDB**: encryption at rest enabled; PITR off by default (toggle via `dynamodb_point_in_time_recovery`)
- **S3 state bucket**: versioning + encryption on

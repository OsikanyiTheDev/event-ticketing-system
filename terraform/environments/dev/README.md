# Dev Environment — Stage 1 Infrastructure

This folder **deploys** the `dev` environment. The reusable modules live in
`terraform/modules/` and are composed here in `main.tf`.

## Run (from this folder)

```bash
# 1. Your settings
cp terraform.tfvars.example terraform.tfvars
#    edit terraform.tfvars → set Owner to your name

# 2. Initialise (downloads provider + loads the modules)
terraform init

# 3. Preview what will be created (~6 resources: 2 tables, GSI, role, policy, attachment)
terraform plan

# 4. Create them (type 'yes')
terraform apply

# 5. See exported values
terraform output
```

> You run every command from **this folder** (`terraform/environments/dev/`),
> never from inside `modules/`.

## Add a `prod` environment later

Copy this `dev/` folder to `prod/`, change `environment = "prod"` in its
`terraform.tfvars`, and run the same commands. **Same modules — different settings.**

## (Optional) Remote state — bootstrap once

```bash
BUCKET="event-ticketing-tfstate-CHANGEME"   # globally unique

aws s3api create-bucket --bucket $BUCKET --region us-east-1
aws s3api put-bucket-versioning --bucket $BUCKET \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```
Then uncomment the `backend "s3"` block in `versions.tf` and re-run `terraform init`.

## Tear down (cost safety)

```bash
terraform destroy
```
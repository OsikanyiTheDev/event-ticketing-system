# 🎟️ Event Registration & Ticketing System — Project Plan

> **Capstone project for Cloud Computing course.** A serverless Event Registration & Ticketing System on AWS that replaces Microsoft Forms + Excel with a scalable REST API.

---

## 1. Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| **Language** | Python 3.12 | Runtime for all Lambda functions |
| **Infra-as-Code** | Terraform | Declarative, reproducible AWS infrastructure |
| **Compute** | AWS Lambda | Serverless business logic (pay-per-use) |
| **API** | API Gateway (REST) | Public HTTP endpoints for the 4 operations |
| **Database** | DynamoDB | NoSQL store for Events & Registrations |
| **Notifications** | SNS | Confirmation emails on registration |
| **Monitoring** | CloudWatch | Logs, metrics, alarms |
| **CI/CD** | GitHub Actions | Automated test + deploy on push |
| **Version Control** | Git + GitHub | Branching, PRs, stage tags |

## 2. Architecture Overview

```
                        ┌──────────────────────────────────────────────┐
                        │                 GitHub                        │
                        │   (main + develop + feature/* branches)       │
                        │              GitHub Actions CI/CD             │
                        └───────────────────┬──────────────────────────┘
                                            │ deploy (Terraform)
                                            ▼
   Client ──HTTP──► API Gateway (REST) ──► AWS Lambda (Python)
                         │                      │
                         │                      ├──► DynamoDB (Events, Registrations)
                         │                      ├──► SNS (confirmation email)
                         │                      └──► CloudWatch (logs, metrics, alarms)
                         │
                   AWS Budgets (Free Tier cost guardrails)
```

### The 4 Core Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/register` | Register a user for an event |
| `GET` | `/events` | List all available events |
| `GET` | `/registrations/{email}` | View all registrations for an email |
| `DELETE` | `/registration/{id}` | Cancel a registration by ID |

---

## 3. Git & Versioning Strategy

We use a **Git Flow–lite** model — great for a portfolio because it demonstrates branching, pull requests, and version tagging.

```
main      ──●────────●────────●────────●──────●────────●──── (stable releases, tagged)
             \      /        /        /        /        /
develop       ●────●────────●────────●────────●────────●──── (integration branch)
                    \      / \      /          \      /
feature/...          ●────●   ●────●            ●────●   (one per chunk of work)
```

- **`main`** — always stable & deployable. Each milestone gets a **tag** (e.g. `v0.2.0-stage1-infra`).
- **`develop`** — integration branch where features merge.
- **`feature/<name>`** — short-lived branches for each piece of work → merged via **Pull Request** into `develop`.
- **Tags** — mark each completed Stage so reviewers (and your CV) can navigate the evolution of the project.

### Stage → Tag → Branch map

| Stage | Branch | Merges to | Tag |
|-------|--------|-----------|-----|
| 0 — Scaffold | `feature/stage0-scaffold` | `main` | `v0.1.0-stage0-scaffold` |
| 1 — Infra Foundation | `feature/stage1-infra` | `develop` | `v0.2.0-stage1-infra` |
| 2 — Lambda Functions | `feature/stage2-lambda` | `develop` | `v0.3.0-stage2-lambda` |
| 3 — API Gateway + CORS | `feature/stage3-apigw` | `develop` | `v0.4.0-stage3-apigw` |
| 4 — CI/CD | `feature/stage4-cicd` | `develop` | `v0.5.0-stage4-cicd` |
| 5 — Monitoring + Security + SNS | `feature/stage5-monitoring` | `develop` | `v0.6.0-stage5-monitoring` |
| 6 — Deploy + Optimize + CD | `feature/stage6-deploy` | `develop` | `v0.7.0-stage6-deploy` |
| 7 — Docs + Presentation | `feature/stage7-docs` | `main` | `v1.0.0-release` |

---

## 4. Stage-by-Stage Breakdown

### 🟦 Stage 0 — Project Scaffold & Git Setup
**Goal:** A clean, professional repo skeleton.

- [ ] Repository structure (lambda/, terraform/, tests/, scripts/, docs/)
- [ ] `.gitignore`, README.md, LICENSE
- [ ] Python tooling (pytest, requirements files)
- [ ] Initialize git, branching strategy, first tag
- **Deliverable:** tagged `v0.1.0` skeleton

### 🟦 Stage 1 — Phase 1: Infrastructure Foundation
**Goal:** Define all AWS infrastructure in Terraform.

- [ ] Terraform providers, backend, variables, remote state
- [ ] DynamoDB tables: `Events` (PK: event_id) and `Registrations` (PK: registration_id, GSI: email)
- [ ] IAM roles for Lambda (least-privilege foundation)
- [ ] Outputs & local dev values
- **Deliverable:** `terraform plan` clean; tables creatable

### 🟦 Stage 2 — Phase 2: API Development (Lambda)
**Goal:** The 4 Lambda handlers + shared utilities + tests.

- [ ] Shared lib: response builder, error handling, input validation/sanitization, CORS helper
- [ ] `POST /register` → validate, write to DynamoDB, publish SNS
- [ ] `GET /events` → scan Events table
- [ ] `GET /registrations/{email}` → query Registrations GSI
- [ ] `DELETE /registration/{id}` → delete item
- [ ] Unit tests (pytest) for each handler
- **Deliverable:** all handlers pass tests

### 🟦 Stage 3 — API Gateway + CORS
**Goal:** Expose the Lambdas as a public REST API.

- [ ] API Gateway REST API + resources + methods
- [ ] Lambda integrations + permissions
- [ ] CORS preflight (`OPTIONS`) + headers
- [ ] Deployment stage + API URL output
- **Deliverable:** live API callable with curl

### 🟦 Stage 4 — Phase 3: CI/CD (GitHub Actions)
**Goal:** Automated quality gate on every push/PR.

- [ ] CI workflow: checkout → setup Python → install deps → lint (ruff) → test (pytest)
- [ ] `terraform fmt` + `terraform validate` check
- [ ] Branch protection rules (require PR + passing CI)
- [ ] Monitor build success/failure in Actions tab
- **Deliverable:** green CI pipeline

### 🟦 Stage 5 — Phase 4: Monitoring, Security & SNS
**Goal:** Production-grade observability, security, notifications.

- [ ] CloudWatch log groups for each Lambda
- [ ] Alarms: error rate > 5%, Lambda duration, throttles, failed registrations
- [ ] Input validation & sanitization hardening
- [ ] SNS topic + email subscription for confirmation emails
- [ ] Lambda → SNS integration on registration
- [ ] IAM least-privilege review
- [ ] AWS Budgets (Free Tier alerts)
- **Deliverable:** alarms + email confirmations working

### 🟦 Stage 6 — Phase 5: Deployment, Optimization & CD
**Goal:** Repeatable deployment + cost optimization.

- [ ] Deployment runbook (manual apply steps)
- [ ] (Optional) GitHub Actions CD workflow for Terraform apply
- [ ] Seed script to load sample events into DynamoDB
- [ ] Cost optimization: DynamoDB on-demand, log retention, Lambda memory tuning
- [ ] Resource lifecycle policies (log expiry)
- **Deliverable:** reproducible deploy; sample data loaded

### 🟦 Stage 7 — Documentation & Presentation
**Goal:** Portfolio-ready docs.

- [ ] Polished README (architecture, setup, API usage, screenshots)
- [ ] Architecture diagram
- [ ] Product presentation deck (problem, challenges, demo)
- [ ] Final release tag `v1.0.0`
- **Deliverable:** everything above

---

## 5. Final Deliverables Checklist (from the guide)

- [x] GitHub repo with API code
- [x] CI/CD pipeline (GitHub Actions)
- [x] Lambda functions
- [x] DynamoDB table definitions
- [x] CloudWatch alarms config
- [x] README file
- [x] Product presentation (problem, challenges, demo)

## 6. How We'll Work Together

1. I build **one Stage at a time**, writing all code + explanation in the workspace.
2. For every file, I tell you **what it does** and **what changed** (new vs. updated).
3. Each Stage ends with: tests passing → commit → tag → PR instructions.
4. You run any AWS/deploy commands on your machine (I flag them clearly).
5. We tag each milestone so your repo history tells a clear story.

---

*This plan is our living roadmap. We'll check off items as we go.*

# 🎟️ Event Registration & Ticketing System

> A **serverless** event registration & ticketing platform on AWS, replacing Microsoft Forms + Excel with a scalable REST API.

![Status](https://img.shields.io/badge/status-WIP%20Stage%200-orange)
![Python](https://img.shields.io/badge/Python-3.12-blue)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC)
![AWS](https://img.shields.io/badge/AWS-Serverless-FF9900)

---

## 📖 Overview

This project is the capstone for our Cloud Computing course. It provisions a fully serverless REST API on AWS for registering attendees to events, viewing events, looking up registrations by email, and cancelling registrations.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/register` | Register for an event |
| `GET` | `/events` | List all events |
| `GET` | `/registrations/{email}` | View registrations for an email |
| `DELETE` | `/registration/{id}` | Cancel a registration |

## 🏗️ Architecture

```
Client ──► API Gateway (REST) ──► Lambda (Python) ──► DynamoDB
                                       │
                                       ├──► SNS (confirmation email)
                                       └──► CloudWatch (logs / alarms)
```

**Services:** API Gateway · AWS Lambda · DynamoDB · SNS · CloudWatch · AWS Budgets · GitHub Actions · Terraform

## 🚀 Quick Start

> Detailed setup lands in Stage 1. High-level flow:

```bash
# 1. Clone
git clone https://github.com/<your-user>/event-ticketing-system.git
cd event-ticketing-system

# 2. Install dev tooling
pip install -r requirements-dev.txt

# 3. Run tests
pytest -v

# 4. Deploy (Stage 6)
cd terraform && terraform init && terraform apply
```

## 📂 Project Structure

```
event-ticketing-system/
├── .github/workflows/   # CI/CD pipelines (GitHub Actions)
├── docs/                # Architecture diagrams & presentation
├── lambda/              # Lambda function source (Python)
│   ├── common/          # Shared utilities (response, validation, cors)
│   ├── register/
│   ├── list_events/
│   ├── get_registrations/
│   └── cancel_registration/
├── terraform/           # Infrastructure-as-Code (Terraform)
├── scripts/             # Seed & helper scripts
├── tests/               # Unit tests (pytest)
├── .gitignore
├── PROJECT_PLAN.md      # Full roadmap & stage breakdown
├── README.md
└── requirements-dev.txt
```

## 🔁 Versioning

We follow a staged release model — each milestone is a git tag. See [`PROJECT_PLAN.md`](./PROJECT_PLAN.md) for the full roadmap.

## 📜 License

MIT — see [LICENSE](./LICENSE).

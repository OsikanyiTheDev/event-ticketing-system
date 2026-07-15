# 🛠️ Development & Git Workflow

This document explains how we branch, review, and release code in this project.

## Branching Model (Git Flow–lite)

| Branch | Purpose |
|--------|---------|
| `main` | Stable, production-ready. Tagged at every milestone. |
| `develop` | Integration branch — feature work merges here. |
| `feature/<name>` | One branch per chunk of work. Short-lived. |

```
main      ──●────────────────●────────●────────●  (tagged releases)
             \              /        /        /
develop       ●────────────●────────●────────●  (integration)
                 \        /  \     /
feature/...       ●──────●    ●───●  (PRs merge here)
```

## Typical Workflow

```bash
# 1. Make sure you're up to date
git checkout develop
git pull origin develop

# 2. Create a feature branch (use the stage naming convention)
git checkout -b feature/stage1-infra

# 3. Do your work, commit in logical chunks
git add .
git commit -m "feat(infra): add DynamoDB tables for events and registrations"

# 4. Push and open a Pull Request into `develop`
git push -u origin feature/stage1-infra
# → Open PR on GitHub, request review, ensure CI is green, then merge

# 5. At milestone boundaries, merge develop → main and tag
git checkout main
git merge develop
git tag -a v0.2.0-stage1-infra -m "Stage 1: Infrastructure foundation"
git push origin main --tags
```

## Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

type   = feat | fix | docs | test | refactor | chore | ci | infra
scope  = infra | lambda | apigw | cicd | monitoring | docs
```

Examples:
- `feat(lambda): implement POST /register handler`
- `fix(apigw): correct CORS preflight headers`
- `docs(readme): add architecture diagram`

## Tags

Each completed Stage is tagged so the repo history tells a clear story:

| Tag | Stage |
|-----|-------|
| `v0.1.0-stage0-scaffold` | Project scaffold |
| `v0.2.0-stage1-infra` | Infrastructure foundation |
| `v0.3.0-stage2-lambda` | Lambda functions |
| `v0.4.0-stage3-apigw` | API Gateway + CORS |
| `v0.5.0-stage4-cicd` | CI/CD pipeline |
| `v0.6.0-stage5-monitoring` | Monitoring + security + SNS |
| `v0.7.0-stage6-deploy` | Deployment + optimization |
| `v1.0.0-release` | Final release |

## Branch Protection (set up in GitHub)

Once Stage 4 (CI/CD) is done, protect `main` and `develop`:
- Require a pull request before merging
- Require status checks to pass (CI workflow)
- Require approvals (at least 1)

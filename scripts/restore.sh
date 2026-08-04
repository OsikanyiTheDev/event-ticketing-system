#!/usr/bin/env bash
###############################################################################
# Morning restore — rebuild the WHOLE stack: domain layer + app + UI.
#
# Two layers now:
#   • domain layer (Route 53, ACM, SES, SPF/DMARC) — idempotent; persists
#   • app layer      (DynamoDB, Lambda, API GW, CloudFront, UI, alarms) — recreated
#
# Because the app layer recreates the SNS topics, you must re-confirm those
# (see MANUAL STEP). The SES domain identity persists in the domain layer, so
# NO SES re-verification is needed.
###############################################################################
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOMAIN_DIR="$ROOT/terraform/domain"
ENV_DIR="$ROOT/terraform/environments/dev"
EMAIL="${1:-osikanyie@gmail.com}"

cd "$ROOT"
echo "▶ Activating venv…"
# shellcheck disable=SC1091
source .venv/bin/activate || true

echo ""
echo "=== 0/5  Domain layer (Route 53, ACM, SES, SPF/DMARC) — idempotent ==="
terraform -chdir="$DOMAIN_DIR" apply -auto-approve

echo ""
echo "=== 1/5  App infrastructure (~5–15 min, includes CloudFront) ==="
terraform -chdir="$ENV_DIR" apply -auto-approve

echo ""
echo "=== 2/5  Seed sample events ==="
python scripts/seed_events.py "$(terraform -chdir="$ENV_DIR" output -raw events_table_name)"

echo ""
echo "=== 3/5  Deploy the UI (injects the new API URL) ==="
bash scripts/deploy_ui.sh

echo ""
echo "=========================================="
echo "🟡 4/5  MANUAL — open $EMAIL and click:"
echo "=========================================="
echo "  [ ] SNS confirmation topic  → \"AWS Notification - Subscription Confirmation\""
echo "  [ ] SNS alarm topic         → \"AWS Notification - Subscription Confirmation\""
echo "  (SES domain identity auto-verifies via DNS — no manual step)"
echo ""
echo "  Verify:"
echo "    aws sns list-subscriptions-by-topic --topic-arn \"\$(terraform -chdir=$ENV_DIR output -raw sns_topic_arn)\" --query 'Subscriptions[0].SubscriptionArn' --output text"
echo "    → should be a real ARN, not 'PendingConfirmation'"
echo ""
echo "⚠️  If the domain zone was recreated, its nameservers may have changed:"
echo "    terraform -chdir=$DOMAIN_DIR output nameservers"
echo "    Re-paste them at Namecheap (Nameservers → Custom DNS) if different."
echo ""
echo "=========================================="
echo "✅ 5/5  DONE → open in browser:"
echo "  https://ticketservice.osikanyi.online   (custom domain, HTTPS)"
echo "  $(terraform -chdir="$ENV_DIR" output -raw website_url)   (S3 direct, HTTP)"
echo "=========================================="

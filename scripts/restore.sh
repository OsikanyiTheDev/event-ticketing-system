#!/usr/bin/env bash
###############################################################################
# Morning restore — rebuild the stack, seed data, deploy the UI.
#
# Because `terraform destroy` recreates the SNS topics + SES identity, you MUST
# click 3 confirmation links in your email afterward (see MANUAL STEP below).
# That's the one thing a script can't do for you.
###############################################################################
set -euo pipefail
ENV_DIR="terraform/environments/dev"
EMAIL="${1:-osikanyie@gmail.com}"   # pass your email, or edit the default

cd "$(dirname "$0")/.."
echo "▶ Activating venv…"
# shellcheck disable=SC1091
source .venv/bin/activate || true

echo ""
echo "=== 1/4  Rebuild infrastructure (auto-approve, ~3–8 min) ==="
terraform -chdir="$ENV_DIR" apply -auto-approve

echo ""
echo "=== 2/4  Seed sample events ==="
python scripts/seed_events.py "$(terraform -chdir="$ENV_DIR" output -raw events_table_name)"

echo ""
echo "=== 3/4  Deploy the UI (injects the new API URL) ==="
bash scripts/deploy_ui.sh

echo ""
echo "=========================================="
echo "🟡 4/4  MANUAL STEP — open $EMAIL and click these:"
echo "=========================================="
echo "  [ ] SNS confirmation topic  → \"AWS Notification - Subscription Confirmation\""
echo "  [ ] SNS alarm topic         → \"AWS Notification - Subscription Confirmation\""
echo "  [ ] SES sender verify       → \"Amazon Web Services Email Address Verification\""
echo ""
echo "Then verify they're all confirmed:"
echo "  aws sns list-subscriptions-by-topic --topic-arn \"\$(terraform -chdir=$ENV_DIR output -raw sns_topic_arn)\""
echo "  aws sns list-subscriptions-by-topic --topic-arn \"\$(terraform -chdir=$ENV_DIR output -raw alarm_topic_arn)\""
echo "  aws ses get-identity-verification-attributes --identities $EMAIL"
echo "  → SNS should NOT say 'PendingConfirmation'; SES should say 'Success'"
echo ""
echo "=========================================="
echo "✅ DONE → open in browser:"
echo "  $(terraform -chdir="$ENV_DIR" output -raw website_url)"
echo "=========================================="

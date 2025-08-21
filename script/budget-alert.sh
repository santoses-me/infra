aws budgets create-budget \
  --account-id "$(aws sts get-caller-identity --query Account --output text)" \
  --budget file://json/budget.json \
  --notifications-with-subscribers file://json/notifications.json
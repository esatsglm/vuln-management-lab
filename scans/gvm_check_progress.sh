#!/bin/bash
# Requires SUDO_PASS and GVM_ADMIN_PASS env vars set (do not hardcode credentials).
CLI() { echo "$SUDO_PASS" | sudo -S -u _gvm gvm-cli --gmp-username admin --gmp-password "$GVM_ADMIN_PASS" socket --xml "$1" 2>/dev/null; }
TASK_ID="2be33885-b897-45bb-b969-f315d85f0066"
CLI "<get_tasks task_id=\"$TASK_ID\"/>" | grep -oP '<status>\K[^<]+|<progress>\K[^<]+'
echo "--- memory ---"
free -h

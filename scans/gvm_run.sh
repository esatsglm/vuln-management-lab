#!/bin/bash
# Requires SUDO_PASS and GVM_ADMIN_PASS env vars set (do not hardcode credentials).
CLI() { echo "$SUDO_PASS" | sudo -S -u _gvm gvm-cli --gmp-username admin --gmp-password "$GVM_ADMIN_PASS" socket --xml "$1" 2>/dev/null; }

PORTLIST="730ef368-57e2-11e1-a90f-406186ea4fc5"
CONFIG="daba56c8-73ec-11df-a475-002264764cea"

echo "--- create_target ---"
TARGET_XML=$(CLI "<create_target><name>Metasploitable2</name><hosts>192.168.56.101</hosts><port_list id=\"$PORTLIST\"/></create_target>")
echo "$TARGET_XML"
TARGET_ID=$(echo "$TARGET_XML" | grep -oP 'id="\K[^"]+' | head -1)
echo "TARGET_ID=$TARGET_ID"

echo "--- create_task ---"
TASK_XML=$(CLI "<create_task><name>Metasploitable2 Full Scan</name><config id=\"$CONFIG\"/><target id=\"$TARGET_ID\"/></create_task>")
echo "$TASK_XML"
TASK_ID=$(echo "$TASK_XML" | grep -oP 'id="\K[^"]+' | head -1)
echo "TASK_ID=$TASK_ID"

echo "--- start_task ---"
CLI "<start_task task_id=\"$TASK_ID\"/>"

echo "$TASK_ID" > /mnt/vulnlab/gvm_task_id.txt
echo "--- saved task id to gvm_task_id.txt ---"

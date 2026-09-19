#!/bin/bash
# Requires SUDO_PASS and GVM_ADMIN_PASS env vars set (do not hardcode credentials).
CLI() { echo "$SUDO_PASS" | sudo -S -u _gvm gvm-cli --gmp-username admin --gmp-password "$GVM_ADMIN_PASS" socket --xml "$1" 2>/dev/null; }

OLD_TASK="7d11c7e8-8eea-443e-a170-24119da04f55"
echo "--- stop old task ---"
CLI "<stop_task task_id=\"$OLD_TASK\"/>"

CONFIG="daba56c8-73ec-11df-a475-002264764cea"
PORTS="21,22,23,25,53,80,111,139,445,512,513,514,1099,1524,2049,2121,3306,3632,5432,5900,6000,6667,6697,8009,8180,8787,35738,36559,47839,59250"

echo "--- create_target (30 known open ports) ---"
TARGET_XML=$(CLI "<create_target><name>Metasploitable2-KnownPorts</name><hosts>192.168.56.101</hosts><port_range>$PORTS</port_range></create_target>")
echo "$TARGET_XML"
TARGET_ID=$(echo "$TARGET_XML" | grep -oP 'id="\K[^"]+' | head -1)
echo "TARGET_ID=$TARGET_ID"

echo "--- create_task ---"
TASK_XML=$(CLI "<create_task><name>Metasploitable2 Known-Ports Scan</name><config id=\"$CONFIG\"/><target id=\"$TARGET_ID\"/></create_task>")
echo "$TASK_XML"
TASK_ID=$(echo "$TASK_XML" | grep -oP 'id="\K[^"]+' | head -1)
echo "TASK_ID=$TASK_ID"

echo "--- start_task ---"
START_XML=$(CLI "<start_task task_id=\"$TASK_ID\"/>")
echo "$START_XML"

echo "$TASK_ID" > /mnt/vulnlab/gvm_task_id2.txt

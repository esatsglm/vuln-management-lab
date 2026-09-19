#!/bin/bash
# Requires SUDO_PASS env var set (do not hardcode credentials).
echo "$SUDO_PASS" | sudo -S shutdown -h now

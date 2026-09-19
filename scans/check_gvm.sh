#!/bin/bash
sed -i 's/^\[sudo\] password for kali: //' /mnt/vulnlab/gvm_results_full.xml
head -c 100 /mnt/vulnlab/gvm_results_full.xml

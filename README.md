# Vulnerability Management Lab — Metasploitable2

Scan a lab target, risk-rank the findings, and deliver a prioritized remediation plan.
This repo is the deliverable: the report, not the raw scan.

## Lab setup

- **Target:** Metasploitable2 (intentionally vulnerable training VM), VirtualBox,
  host-only network, no internet egress.
- **Attacker/scanner:** Kali Linux, VirtualBox, same host-only network.
- **Tools:** Nmap 7.95 (port discovery, NSE vuln scripts, `vulners` CVE correlation) and
  Greenbone OpenVAS/GVM 25.04 (credentialed default-account brute force, active exploit
  verification, CVSS scoring).

## What's in this repo

| Path | Contents |
|---|---|
| [`report/Vuln_Management_Report.md`](report/Vuln_Management_Report.md) | The deliverable: executive summary, risk-ranked findings, detailed write-ups, prioritized remediation plan |
| `scans/metasploitable2_detailed.txt` / `.xml` | Raw Nmap output |
| `scans/nmap_confirmed_findings.md` | Nmap-only interim findings notes |
| `scans/gvm_results_full.xml` | Raw GVM/OpenVAS results (GMP `get_results` export) |
| `scans/gvm_summary.tsv` | Parsed, severity-sorted summary of all GVM results |
| `scans/parse_results.py` | Script that turns the raw GVM XML into the TSV summary |
| `scans/gvm_run.sh`, `gvm_run2.sh` | Scripts that created/started the GVM scan targets and tasks via GMP (`gvm-cli`) |
| `scans/gvm_check_progress.sh`, `check_gvm.sh` | Monitoring helper scripts |

`lab/` (the VM disk images) is excluded via `.gitignore` — it's a ~2.7GB third-party
training VM, not part of the deliverable. Get it yourself from
[SourceForge](https://sourceforge.net/projects/metasploitable/files/Metasploitable2/) if
you want to reproduce this lab.

## Reproducing this

1. Import Metasploitable2 into VirtualBox on a host-only network with no internet access.
2. From Kali on the same network: `nmap -p- -T4 --min-rate=1000 <target>` to find open
   ports, then `nmap -sV -sC -O --script vuln -p <ports> <target>` for details.
3. Install GVM (`apt install gvm && gvm-setup && gvm-start`), create a target/task scoped
   to the ports Nmap found open (scanning all 65,535 ports in one GVM task hit repeated
   out-of-memory crashes during report finalization on this setup — see the appendix of
   the report for details), and run the scan.
4. Export results via GMP (`gvm-cli ... get_results`), parse, cross-reference against the
   Nmap findings, and risk-rank by proven exploitability rather than raw CVSS alone.

## Headline result

16 Critical + 10 High confirmed findings on a single host, including default credentials
accepted on five separate services (Tomcat, MySQL, PostgreSQL, VNC, FTP) and three
services where the scanner achieved actual remote command execution. Full detail in the
report.

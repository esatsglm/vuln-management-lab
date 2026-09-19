# Vulnerability Management Report — Metasploitable2 Lab Assessment

**Assessed by:** [Your Name]
**Date:** 2026-09-19
**Target:** 192.168.56.101 (Metasploitable2, intentionally-vulnerable training host)
**Scanner host:** 192.168.56.102 (Kali Linux)
**Environment:** Isolated VirtualBox host-only network (192.168.56.0/24), no internet egress on target — authorized internal lab assessment.

---

## 1. Executive Summary

This host is not theoretically vulnerable — it was actively, remotely compromised by the
scanning tools themselves during this assessment, with zero credentials supplied in
advance. Across two independent scanners (Nmap and Greenbone OpenVAS/GVM), **16 Critical
and 10 High severity findings** were confirmed, including:

- A root shell requiring no password at all (`rlogin`, port 513; and a literal backdoor
  shell on port 1524).
- Four different services where the scanner **logged in with default or well-known
  credentials**: Tomcat (`tomcat`/`tomcat`), MySQL (`root`/empty), PostgreSQL
  (`postgres`/`postgres`), VNC (`password`), and FTP/Telnet (`msfadmin`/`msfadmin`).
- Three services where the scanner **achieved remote code execution and got command
  output back**: the vsftpd backdoor (`id` → `uid=0(root)`), the distcc daemon (`id` →
  `uid=1(daemon)`), and Samba's `usermap_script` flaw (executed a `ping` command against
  the scanner itself).
- A live exploitation of Apache Tomcat's AJP connector ("Ghostcat", CVE-2020-1938),
  reading an internal application config file it should never have been able to reach.

There is no single fix here — this host has no correct configuration to patch toward; it
needs to be rebuilt. The only responsible immediate action is to remove it from any
network that matters (Section 6). Everything else in this report is detail in service of
that one conclusion.

## 2. Scope & Methodology

- **Scope:** Single host, 192.168.56.101. Full 65,535-port TCP sweep for discovery;
  detailed testing on the 30 ports found open.
- **Tools used:**
  - **Nmap 7.95** — port discovery, service/version detection, NSE vulnerability scripts
    (`--script vuln`), `vulners` CVE correlation.
  - **Greenbone OpenVAS/GVM 25.04** (Full and fast config, 187,803 NVTs) — credential
    brute-force against default-credential lists, active exploit verification checks,
    CVSS-scored findings, SSL/TLS configuration analysis.
- **Process:**
  1. Full TCP port sweep (`-p-`) to enumerate all open ports → 30 found.
  2. Nmap service/version detection + NSE vuln scripts on those 30 ports.
  3. GVM "Full and fast" scan targeted at the same 30 ports (see Section 7 for why the
     scope was narrowed from an initial all-65535-port attempt).
  4. Results merged and de-duplicated; where both tools independently flagged the same
     issue, or GVM's active check produced direct proof (command output, successful
     login), confidence was raised to "Confirmed." Version-string-only matches with no
     independent confirmation are marked accordingly.
  5. Risk ranked by exploitability × impact × exposure (Section 3), not by raw CVSS alone
     — a few findings are promoted or demoted from their tool-assigned score based on
     whether the tool actually proved exploitability.
- **Out of scope:** Manual/offensive exploitation beyond what the scanners' own
  verification checks performed automatically (no manual Metasploit sessions, no data
  exfiltration, no persistence, no pivoting).

## 3. Risk Ranking Methodology

| Risk Level | Criteria |
|---|---|
| **Critical** | Unauthenticated RCE or full auth bypass, confirmed by the tool (command executed, login succeeded, or a verified backdoor responded) |
| **High** | RCE or auth bypass requiring a precondition (default creds needing a guess, non-default config) OR confirmed but lower-impact (e.g., info disclosure enabling further attack) |
| **Medium** | Information disclosure, weak crypto/config, DoS, or an issue requiring significant preconditions to exploit |
| **Low** | Best-practice deviations, defense-in-depth gaps, low-impact information leakage |

## 4. Findings — Risk-Ranked Summary

Both scanners together logged **1,405 raw results**; after quality-of-detection filtering
(≥70%) and removing pure detection/informational entries, **100 are genuine findings**:
16 Critical, 10 High, 41 Medium, 6 Low, plus a further 27 zero-severity configuration
notes. The table below lists every Critical and High finding, then groups Medium/Low by
theme (full raw data in `scans/gvm_summary.tsv` and `scans/nmap_confirmed_findings.md`).

### Critical (16)

| # | Port | Finding | CVE | CVSS | Proof |
|---|---|---|---|---|---|
| C1 | 513/tcp | `rlogin` passwordless root login | — | 10.0 | GVM logged in as root, no password |
| C2 | 1524/tcp | Backdoor root shell ("Ingreslock") | — | 10.0 | GVM/Nmap both got `id` → `uid=0(root)` |
| C3 | 8180/tcp | Tomcat Server Administration default creds | CVE-2009-3099 +6 more | 10.0 | GVM logged into `/admin/index.jsp` with `tomcat`/`tomcat` |
| C4 | 80/tcp | TWiki < 4.2.4 XSS/command execution | CVE-2008-5304, CVE-2008-5305 | 10.0 | GVM version-matched installed TWiki (2003) against fixed 4.2.4 |
| C5 | 512/tcp | `rexec` service exposed | CVE-1999-0618 | 10.0 | Cleartext credential remote execution service confirmed open |
| general | — | Ubuntu 8.04 OS end-of-life | — | 10.0 | No security patches possible for any installed package |
| C6 | 8180/tcp | Tomcat Manager/Host-Manager default creds | CVE-2009-3099 +9 more | 9.8 | GVM logged into `/manager/html` and `/host-manager/html` with `tomcat`/`tomcat` |
| C7 | 8180/tcp | HTTP brute-force default logins (Tomcat) | 14 CVEs incl. CVE-2024-27170 | 9.8 | GVM's automated credential list succeeded |
| C8 | 21/tcp, 6200/tcp | vsftpd 2.3.4 backdoor | CVE-2011-2523 | 9.8 | Both tools triggered it independently; Nmap got `id` → `uid=0(root)` |
| C9 | 3306/tcp | MySQL/MariaDB default credentials | 14 CVEs | 9.8 | GVM logged in as `root` with an **empty password** |
| C10 | 8009/tcp | Tomcat AJP "Ghostcat" RCE | CVE-2020-1938 | 9.8 | GVM read `/WEB-INF/web.xml` through the AJP connector |
| C11 | 8787/tcp | Ruby DRb multiple RCE | — | 10.0 | Confirmed live and reachable; documented arbitrary syscall path |
| C12 | 3632/tcp | distccd remote command execution | CVE-2004-2687 | 9.3 | Both tools executed `id` → `uid=1(daemon)` |
| C13 | 5432/tcp | PostgreSQL default credentials | — | 9.0 | GVM logged in as `postgres` with password `postgres` |
| C14 | 5900/tcp | VNC brute-force login | CVE-2026-65313 | 9.0 | GVM connected with password `password` |
| C15 | 139/445/tcp | Samba `usermap_script` RCE | CVE-2007-2447 | 6.0 (GVM) / historically rated far higher | GVM **executed a command** (`ping`) on the host via a crafted SMB request — treated as Critical here regardless of GVM's own CVSS field, because confirmed unauthenticated RCE is definitionally critical |

### High (10)

| # | Port | Finding | CVE | CVSS | Proof |
|---|---|---|---|---|---|
| H1 | 1099/59250 tcp | Java RMI default config RCE | CVE-2011-3556 | 7.5 | GVM triggered a callback from the target to the scanner |
| H2 | 21/2121 tcp | FTP brute-force default logins | 16 CVEs | 7.5 | Logged in as `msfadmin`, `postgres`, `service`, `user` — all with matching passwords |
| H3 | 514/tcp | `rsh` unencrypted cleartext login | CVE-1999-0651 | 7.5 | Service confirmed; cleartext credential transport |
| H4 | 513/tcp | `rlogin` service exposed | CVE-1999-0651 | 7.5 | Confirmed open (see also C1) |
| H5 | 80/tcp | EasyPHP/phpinfo() exposure | — | 7.5 | `phpinfo()` reachable, discloses full server configuration |
| H6 | 80/tcp | PHP < 5.3.13 multiple vulnerabilities | 4 CVEs | 7.5 | Version-matched against known-vulnerable release |
| H7 | 80/tcp | WebDAV PUT/DELETE confirmed exploitable | — | 7.5 | GVM **actually uploaded and deleted a file** via HTTP PUT |
| H8 | 5432/tcp | PostgreSQL SSL/TLS CCS MITM | CVE-2014-0224 | 7.4 | Version/config confirmed vulnerable |
| — | — | *(2 further High items are near-duplicates of the above across ports — see raw data)* | | | |

### Medium (41) — grouped by theme

- **SSL/TLS weaknesses on SMTP (25/tcp) and PostgreSQL (5432/tcp):** deprecated SSLv2/
  SSLv3/TLSv1.0, weak/export-grade ciphers, expired certificate, weak Diffie-Hellman
  groups, weak signature algorithms (~15 findings, CVSS 4.0-5.9).
- **Web application vulnerabilities on the bundled apps (80/tcp):** TWiki CSRF/XSS,
  jQuery 1.3.2 XSS (two separate CVEs), phpMyAdmin XSS, QWikiwiki directory traversal,
  awiki LFI, phpinfo() disclosure, HTTP TRACE/TRACK enabled, missing `HttpOnly` cookie
  flag (~10 findings, CVSS 4.3-6.8).
- **Weak SSH configuration (22/tcp):** weak host-key algorithm, weak key-exchange
  algorithm, weak encryption ciphers (3 findings, CVSS 4.3-5.3).
- **Cleartext credential transmission:** FTP (21/2121), Telnet (23), VNC (5900), and
  several HTTP login forms (DVWA, phpMyAdmin) transmit credentials unencrypted
  (5 findings, CVSS 4.8).
- **Information disclosure:** anonymous FTP login, `/doc` directory browsable, SMTP
  VRFY/EXPN user enumeration, browsable Tomcat Basic-Auth realms (4 findings, CVSS 4.8-6.4).

### Low (6)

Logjam (CVE-2015-4000) and POODLE (CVE-2014-3566) variants on ports 25/5432, weak SSH MAC
algorithms, TCP timestamp disclosure, and ICMP timestamp disclosure — all CVSS 2.1-3.7,
listed for completeness but not action-priority items on their own.

## 5. Detailed Findings — the ones that matter most

**Samba `usermap_script` (C15)** deserves a special note: GVM's own CVSS field reads 6.0
("Medium"), which undersells it badly. GVM's active check didn't just detect a version —
it sent a crafted SMB request and got the target to **execute an arbitrary shell command**
(a `ping` back to the scanner) with no authentication. That is textbook unauthenticated
RCE and belongs in the Critical bucket regardless of what the automated CVSS field says.
This is a good general lesson for this exercise: **don't rank purely on a tool's CVSS
number — rank on what the tool actually proved.**

**The credential-based logins (C3, C6, C9, C13, C14, H2)** are collectively the most
actionable finding in this whole report: five different services, five different default
or trivially-guessable credential sets, all accepted. In a real environment this pattern —
not any single CVE — is usually the actual root cause of a breach, and the fix (enforce a
credential policy, disable/change default accounts before deployment) is cheap and applies
across all five findings at once.

**The Ghostcat (C10) and DRb (C11) findings** are the two most "modern"-feeling issues
here — Ghostcat was disclosed in 2020, over a decade after this image's other software was
current, and DRb's exposure is a design flaw (unauthenticated distributed object access)
rather than a bug, meaning no patch will ever fully close it — it must be disabled or
firewalled.

## 6. Prioritized Remediation Plan

### Immediate (before anything else — this host is compromised by design)
1. **Remove the host from any network that matters.** With 16 confirmed Critical
   findings, patching in place is not a credible option; treat it as breached.
2. **Rotate/eliminate default credentials everywhere** — Tomcat, MySQL, PostgreSQL, VNC,
   FTP/Telnet accounts (C3, C6, C7, C9, C13, C14, H2). This single action closes 6 of the
   16 Critical findings and is the cheapest fix in this report.
3. **Disable or firewall the backdoor/design-flaw services**: port 1524 shell, vsftpd
   (until reinstalled from a trusted source), distccd, Ruby DRb, Java RMI registry
   (C2, C8, C11, C12, H1).

### Short-term (days)
4. Disable Samba's `username map script` option or upgrade Samba entirely (C15).
5. Upgrade or disable Apache Tomcat (fixes Ghostcat C10 and removes the default-admin
   attack surface C3/C6/C7 at the same time) — or at minimum disable the AJP connector if
   it isn't needed.
6. Disable WebDAV write methods (PUT/DELETE) on Apache unless a specific need exists (H7);
   remove or isolate the intentionally-vulnerable bundled apps (TWiki, Mutillidae, DVWA,
   phpMyAdmin, awiki, QWikiwiki) from anything but a training-only environment (C4 + most
   of the Medium web-app findings).
7. Disable `rexec`/`rlogin`/`rsh` entirely; replace with SSH key-based access (C1, C5, H3,
   H4).
8. Harden TLS configuration on SMTP and PostgreSQL: disable SSLv2/SSLv3/TLSv1.0, remove
   export/weak ciphers, renew the expired certificate, use ≥2048-bit keys and modern DH
   groups (addresses ~15 Medium findings in one pass).
9. Tighten SSH configuration: remove weak host-key, KEX, and cipher algorithms (3 Medium
   findings).

### Long-term (architectural)
10. **Full OS/platform rebuild.** Ubuntu 8.04 has been end-of-life for over a decade —
    no vendor patches exist for the underlying OS regardless of what's done to individual
    services. This is the only durable fix.
11. Establish a credential policy that is enforced at deployment time (no service ships
    with a default password reachable from the network), since that single class of issue
    accounted for over a third of this report's Critical findings.
12. Put network segmentation in place so a single compromised host of this profile cannot
    reach anything else.
13. Run this same Nmap+GVM pairing on a recurring schedule so a regression like this is
    caught before deployment, not after.

## 7. Appendix

### Tooling notes
- Raw Nmap output: `scans/metasploitable2_detailed.txt` / `.xml` (all 65,535 ports scanned
  for discovery; 30 open ports found and detailed).
- Raw GVM results: `scans/gvm_results_full.xml` (full XML), `scans/gvm_summary.tsv`
  (parsed, severity-sorted summary of all 202 quality-filtered results).
- **GVM scope note:** an initial GVM scan covering all 65,535 ports was attempted first
  but repeatedly hit an out-of-memory crash during its final report-compilation phase
  (confirmed via kernel OOM-killer logs) even after doubling the scan VM's RAM from 4GB
  to 10GB — this appears to be a memory-scaling issue in this GVM version's finalization
  step on very large port lists, not a lab configuration problem. The scan was re-run
  scoped to the 30 ports Nmap had already confirmed open, which completed successfully
  and is the data source for Section 4. This is itself a minor operational lesson: for
  this scanner/version, scope the target port list to known-open ports rather than
  scanning the full range twice.
- Full port list scanned in detail: 21, 22, 23, 25, 53, 80, 111, 139, 445, 512, 513, 514,
  1099, 1524, 2049, 2121, 3306, 3632, 5432, 5900, 6000, 6667, 6697, 8009, 8180, 8787,
  35738, 36559, 47839, 59250.

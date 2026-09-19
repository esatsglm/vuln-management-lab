# Nmap Confirmed Findings — Metasploitable2 (192.168.56.101)

Scan date: 2026-09-17 | Scanner: Nmap 7.95 from Kali (192.168.56.102)
Command: `nmap -sV -sC -O --script vuln -p <30 open ports> 192.168.56.101`
Raw output: metasploitable2_detailed.txt / .xml

## Confirmed exploitable (nmap script executed code / verified state)

| # | Port/Service | Finding | CVE | CVSS | Evidence |
|---|---|---|---|---|---|
| 1 | 21/tcp vsftpd 2.3.4 | Backdoor in vsftpd source (2011 compromise) | CVE-2011-2523 | 10.0 | nmap `ftp-vsftpd-backdoor` got shell, ran `id` -> uid=0(root) |
| 2 | 3632/tcp distccd | Distcc daemon allows arbitrary command execution | CVE-2004-2687 | 9.3 | nmap `distcc-cve2004-2687` got shell as uid=1(daemon) |
| 3 | 6667,6697/tcp UnrealIRCd | Trojaned binary (2010 supply-chain compromise), backdoor command exec | - | ~10.0 | nmap `irc-unrealircd-backdoor` positive |
| 4 | 1099,59250/tcp Java RMI | Default RMI registry config allows remote class loading -> RCE | - | ~9.8 | nmap `rmi-vuln-classloader` VULNERABLE |
| 5 | 1524/tcp | Unauthenticated root shell listening directly on the port | - | 10.0 (design flaw) | Service literally named "Metasploitable root shell" in nmap fingerprint |

## Additional high-risk exposures (service/version-based, well documented for this image)

| Port/Service | Issue | Notes |
|---|---|---|
| 139,445/tcp Samba 3.X | usermap_script RCE (CVE-2007-2447) known for Samba 3.0.20 on this image | Not in default nmap vuln script set — recommend manual verification |
| 512,513,514/tcp rexec/rlogin/rsh | Cleartext, trust-based legacy remote access (`r-services`) | No modern auth; credentials/session sniffable |
| 2049/tcp + rpcbind family (111,35738,36559,47839) | NFS/RPC stack, historically exports `/` with no restriction | Info disclosure / unauthorized mount risk |
| 3306/tcp MySQL 5.0.51a | Old, multiple CVEs; well-known root/no-password on this image | Credential + version risk |
| 5432/tcp PostgreSQL 8.3 | Old, multiple CVEs; trust-based auth common on this image | Auth bypass risk |
| 5900/tcp VNC (protocol 3.3) | Legacy VNC auth, weak/no-password common on this image | Remote desktop takeover risk |
| 8009/tcp AJP13 + 8180/tcp Tomcat/Coyote 1.1 | Old Tomcat; `/manager/html` found (401) — brute-forceable; AJP lacks connector auth | RCE via manager deploy if creds guessed |
| 8787/tcp Ruby DRb | Unauthenticated distributed object access -> RCE (documented Metasploitable2 vector) | No auth on DRb endpoint |
| 80/tcp Apache 2.2.8 + DAV/2 | Hosts DVWA/Mutillidae (intentionally vulnerable web apps), WebDAV enabled, Slowloris DoS (CVE-2007-6750) | App-layer SQLi/XSS by design; DAV PUT could allow file upload RCE |
| 25/tcp Postfix | Weak/anonymous TLS: POODLE (CVE-2014-3566), Logjam (CVE-2015-4000), weak DH group | MITM / crypto downgrade |
| 53/tcp ISC BIND 9.4.2 | End-of-life DNS server, multiple historical CVEs | Cache poisoning / DoS surface |

## Noise / needs manual triage

The `vulners` NSE script matched ~1,300 CVE/exploit references purely by CPE/version string
(e.g. many `CVE-2026-*` entries that predate this software's actual disclosure history by over
a decade). These are **not** validated exploitability claims — they are database lookups by
version banner. Full list retained in `metasploitable2_detailed.txt` for reference; the report
will cite only the confirmed/well-documented items above unless GVM independently corroborates
a specific CVE with a verified check.

## Pending

- [ ] GVM/OpenVAS authenticated+unauthenticated scan for CVSS cross-validation
- [ ] Manual check: `nmap --script smb-vuln-cve-2007-2447 -p445 192.168.56.101`

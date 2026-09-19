import xml.etree.ElementTree as ET

tree = ET.parse('/mnt/vulnlab/gvm_results_full.xml')
root = tree.getroot()

rows = []
for result in root.findall('.//result'):
    name = result.findtext('name', '')
    port = result.findtext('port', '')
    threat = result.findtext('threat', '')
    severity = result.findtext('severity', '0')
    cves = [ref.get('id') for ref in result.findall('.//refs/ref') if ref.get('type') == 'cve']
    desc = (result.findtext('description') or '').strip().replace('\n', ' ')[:150]
    rows.append((float(severity), threat, port, name, ','.join(cves), desc))

rows.sort(key=lambda r: -r[0])

with open('/mnt/vulnlab/gvm_summary.tsv', 'w') as f:
    f.write("severity\tthreat\tport\tname\tcves\tdescription\n")
    for r in rows:
        f.write(f"{r[0]}\t{r[1]}\t{r[2]}\t{r[3]}\t{r[4]}\t{r[5]}\n")

print(f"Total results: {len(rows)}")
print(f"By threat level:")
from collections import Counter
c = Counter(r[1] for r in rows)
for k, v in c.most_common():
    print(f"  {k}: {v}")

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

SURFACE = "#fcfcfb"
INK = "#0b0b0b"
INK2 = "#52514e"
GRID = "#e1e0d9"

# Severity is ordered state: status palette (critical/serious/warning) + blue for Low.
data = [
    ("Critical", 16, "#d03b3b"),
    ("High", 10, "#ec835a"),
    ("Medium", 41, "#fab219"),
    ("Low", 6, "#6da7ec"),
]
total = sum(v for _, v, _ in data)

plt.rcParams["font.family"] = ["Segoe UI", "DejaVu Sans"]
fig, ax = plt.subplots(figsize=(10.8, 5.4), dpi=200)
fig.patch.set_facecolor(SURFACE)
ax.set_facecolor(SURFACE)

labels = [d[0] for d in data]
ys = list(range(len(data)))[::-1]
for y, (name, val, color) in zip(ys, data):
    ax.barh(y, val, height=0.56, color=color, edgecolor=SURFACE, linewidth=2)
    ax.text(val + 0.8, y, f"{val}", va="center", ha="left", fontsize=17,
            fontweight="bold", color=INK)
    ax.text(-0.8, y, name, va="center", ha="right", fontsize=15, color=INK)

ax.set_xlim(0, 48)
ax.set_ylim(-0.7, len(data) - 0.3)
ax.set_yticks([])
ax.set_xticks([0, 10, 20, 30, 40])
ax.tick_params(axis="x", colors=INK2, labelsize=11, length=0)
ax.xaxis.grid(True, color=GRID, linewidth=1)
ax.set_axisbelow(True)
for s in ("top", "right", "left"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_color(GRID)

fig.text(0.05, 0.93, f"{total} findings on one host, {data[0][1]} of them Critical",
         fontsize=20, fontweight="bold", color=INK, ha="left", va="top")
fig.text(0.05, 0.855,
         "Nmap + Greenbone OpenVAS scan of Metasploitable2 (intentionally vulnerable lab VM)",
         fontsize=12, color=INK2, ha="left", va="top")
fig.text(0.05, 0.03,
         "Findings with quality-of-detection >= 70%, severity > 0. Isolated lab, no real systems.",
         fontsize=10, color=INK2, ha="left", va="bottom")

fig.subplots_adjust(left=0.16, right=0.95, top=0.76, bottom=0.14)
fig.savefig(r"C:\Users\esatk\Documents\VulnLab\report\severity_chart.png", facecolor=SURFACE)

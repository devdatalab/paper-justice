import os
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from shutil import copyfile

mpl.rcParams['mathtext.fontset'] = 'custom'
mpl.rcParams['mathtext.rm'] = 'Bitstream Vera Sans'
mpl.rcParams['mathtext.it'] = 'Bitstream Vera Sans:italic'
mpl.rcParams['mathtext.bf'] = 'Bitstream Vera Sans:bold'

mpl.rc('font', **{'family': 'serif', 'serif': ['Computer Modern']})
mpl.rc('text', usetex=True)

# read in the data
df = pd.read_stata(os.path.join(TMP, "lit_coefs.dta"))

# convert coefficients to numeric
df['coef'] = df['coef'].astype(float)
df['coef'] = df['coef'].sort_values()

# define function to assign color based on sign of coefficient
def define_color(val):
    if val >= 1:
        return "#ab0513"
    elif val < 1:
        return "#671fa6"

# define the color for each health condition
color=tuple([define_color(x) for x in list(df['coef'])])

# reassign color of last bar for total
color_list = list(color)
color_list[0] = "#a61f1f"
color_list[1] = "#a61f1f"
color = tuple(color_list)    

# define the figure
f, ax = plt.subplots(figsize=[14,10])

# make the horizontal bar chart of coefficients
df['coef'].plot(kind="barh", color="None", xerr = df['ci'])

# plot the points as a scatter plot
ax.scatter(y=np.arange(df['coef'].shape[0]), x=df['coef'],
                   marker='o', s=40, color=color_list)

# plot the dashed line before total crimes
ax.plot([-13.5,13.5], [1.5,1.5], linestyle="-.", color="black", linewidth=0.5)
ax.axvline(x=0, linestyle="solid", color="#d6d6d6", linewidth=0.5)

# overwrite yticklabels with proper labels
labs = ax.set_yticklabels(df["name"], fontsize=28, color="black")

# add the annotation of the percentage for each bar
for p in ax.patches:
    note = "{:.2f}".format(p.get_width()) + " "
    if p.get_width() > 1:
        ax.annotate(note, (p.get_width() + 0.03, p.get_y()+.2), fontsize=24, fontweight="bold", color="black")
    else:
        ax.annotate(note, (p.get_width() - 0.2, p.get_y()+.35), fontsize=24, fontweight="bold", color="black")

# format axes
ax.tick_params(axis="x", labelsize=24)
ax.set_xlim([-0.8,1.8])
ax.set_ylim([-0.8,12])

# ax.set_title("Point estimates of judicial in-group bias in the literature", fontsize=18, fontweight = "bold", color="black")

# save figure
plt.savefig(os.path.join(IEC, "output", "judicial_bias", "lit_coef.png"), bbox_inches="tight", dpi=150)

# copy file for public html viewing
home = os.path.expanduser("~")
copyfile(os.path.join(IEC, "output", "judicial_bias", "lit_coef.png"),
         os.path.join(home, "public_html", "png", "lit_coef.png"))

plt.close("all")

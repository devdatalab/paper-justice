import os
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from shutil import copyfile
from pathlib import Path

TMP = Path(os.environ.get('TMP'))
IEC = Path(os.environ.get('IEC'))


mpl.rcParams['mathtext.fontset'] = 'custom'
mpl.rcParams['mathtext.rm'] = 'Bitstream Vera Sans'
mpl.rcParams['mathtext.it'] = 'Bitstream Vera Sans:italic'
mpl.rcParams['mathtext.bf'] = 'Bitstream Vera Sans:bold'

mpl.rc('font', **{'family': 'serif', 'serif': ['Computer Modern']})
mpl.rc('text', usetex=False)

# read in the data
df = pd.read_stata(os.path.join(TMP, "gender_coefplot.dta"))

# convert coefficients to numeric
df['diff'] = df['diff'].astype(float)

# define ordering of health conditions
sort_vars = {'murder': 1,
             'sexual': 2,
             'violent': 3,
             'theft': 4,
             'women': 5,
             'peace': 6,
             'property': 7,
             'marriage': 8,
             'petty': 9,
             'other': 10,
             'all': 11}

# sort health conditions
df['sort'] = df['crime'].apply(lambda x: sort_vars[x])
df = df.sort_values("sort", ascending=False)
df = df.drop("sort", axis=1)

# define label key 
label_key = {
    'murder': "Murder",
    'sexual': "Sexual assault",
    'violent': "Violent crimes causing hurt",
    'theft': "Violent theft/dacoity",
    'women': "Other crimes against women",
    'peace': "Disturbing public health/safety",
    'property': "Property crime",
    'marriage': "Marriage offenses",
    'petty': "Petty theft",
    'other': "All other crimes",
    'all': "Total"}
    
# define function to assign color based on sign of coefficient
def define_color(val):
    if val >= 0:
        return "#ab0513"
    elif val < 0:
        return "#0592ab"

# define the color for each health condition
color=tuple([define_color(x) for x in list(df['diff'])])

# reassign color of last bar for total
color_list = list(color)
color_list[0] = "black"
color = tuple(color_list)    

# define the figure
f, ax = plt.subplots(figsize=[9,13])

# make the horizontal bar chart of coefficients
df['diff'].plot(kind="barh", color="None")

# plot the points as a scatter plot
ax.scatter(y=np.arange(df['diff'].shape[0]), x=df['diff'],
                   marker='o', s=40, color=color)

# plot the 0 line
ax.plot([0,0], [-1,17.7], "k-", linewidth=0.75)

# plot the dashed line before total crimes
ax.plot([-13.5,13.5], [0.5,0.5], linestyle="-.", color="black", linewidth=0.5)

# overwrite yticklabels with proper labels
labs = ax.set_yticklabels([label_key[x] for x in list(df["crime"])], fontsize=30, color="black")

# add the annotation of the percentage for each bar
for p in ax.patches:
    note = "{:.3f}".format(p.get_width()) + " "
    if p.get_width() > 0:
        ax.annotate(note, (p.get_width() + 0.005, p.get_y()+.15), fontsize=26, fontweight="normal", color="black")
    else:
        ax.annotate(note, (p.get_width() - 0.001, p.get_y()+.15), fontsize=26, fontweight="normal", color="black")

# format axes
ax.tick_params(axis="x", labelsize=26)
ax.set_xlim([-0.01,0.09])
ax.set_ylim([-0.8,11])
#ax.set_title("B: Female $-$ male acquittal %", fontsize=36, fontweight = "bold", color="black")

# save figure
plt.savefig(os.path.join(IEC, "output", "judicial_bias", "g_coef2.png"), bbox_inches="tight", dpi=150)

# copy file for public html viewing
home = os.path.expanduser("~")
copyfile(os.path.join(IEC, "output", "judicial_bias", "g_coef2.png"),
         os.path.join(home, "public_html", "png", "g_coef2.png"))

plt.close("all")
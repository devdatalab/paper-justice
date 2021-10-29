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
df = pd.read_stata(os.path.join(TMP, "gender_crime_coef.dta"))

# convert coefficients to numeric
df['gender_bias'] = df['gender_bias'].astype(float)
df['ci'] = df['ci'].astype(float)

# define function to assign color based on sign of coefficient
def define_color(val):
    if val >= 1:
        return "#800040"
    elif val < 1:
        return "#800040"

# define the color for each health condition
color=tuple([define_color(x) for x in list(df['gender_bias'])])

# define the figure
f, ax = plt.subplots(figsize=[6,11])

# make the horizontal bar chart of coefficients
df['gender_bias'].plot(kind="barh", color="None", xerr = df['ci'], ecolor = "#A4A4A4")


# plot the points as a scatter plot
ax.scatter(y=np.arange(df['gender_bias'].shape[0]), x=df['gender_bias'],
                   marker='D', s=100, color=color)
ax.axvline(x=0, linestyle="-.", color = "black", linewidth = 0.6)

# overwrite yticklabels with proper labels
labs = ax.set_yticklabels(df["crime"], fontsize=16, color="black")

# add the annotation of the percentage for each bar
for p in ax.patches:
    note = "{:.3f}".format(p.get_width()) + " "
    ax.annotate(note, (p.get_width() + 0.0015, p.get_y()+.0002), fontsize=16, fontweight="bold", color="black")

# format axes
ax.tick_params(axis="x", labelsize=16)
ax.set_xlim([-0.04,0.06])
ax.set_ylim([-0.8,10])

ax.set_title("Panel A: In--group gender bias", fontsize=18, fontweight = "bold", color="black")

# save figure
plt.savefig(os.path.join(IEC, "output", "judicial_bias", "gender_crime_coef.png"), bbox_inches="tight", dpi=150)

# copy file for public html viewing
home = os.path.expanduser("~")
copyfile(os.path.join(IEC, "output", "judicial_bias", "gender_crime_coef.png"),
         os.path.join(home, "public_html", "png", "gender_crime_coef.png"))

# read in the data
df = pd.read_stata(os.path.join(TMP, "religion_crime_coef.dta"))

# convert coefficients to numeric
df['religion_bias'] = df['religion_bias'].astype(float)
df['ci'] = df['ci'].astype(float)

# define function to assign color based on sign of coefficient
def define_color(val):
    if val >= 1:
        return "#671fa6"
    elif val < 1:
        return "#671fa6"

# define the color for each health condition
color=tuple([define_color(x) for x in list(df['religion_bias'])])

# define the figure
f, ax = plt.subplots(figsize=[6,11])

# make the horizontal bar chart of coefficients
df['religion_bias'].plot(kind="barh", color="None", xerr = df['ci'], ecolor = "#A4A4A4")


# plot the points as a scatter plot
ax.scatter(y=np.arange(df['religion_bias'].shape[0]), x=df['religion_bias'],
                   marker='D', s=100, color=color)
ax.axvline(x=0, linestyle="-.", color = "black", linewidth = 0.6)

# overwrite yticklabels with proper labels
labs = ax.set_yticklabels(df["crime"], fontsize=16, color="black")

# add the annotation of the percentage for each bar
for p in ax.patches:
    note = "{:.3f}".format(p.get_width()) + " "
    ax.annotate(note, (p.get_width() + 0.0015, p.get_y()+.0002), fontsize=16, fontweight="bold", color="black")

# format axes
ax.tick_params(axis="x", labelsize=16)
ax.set_xlim([-0.04,0.06])
ax.set_ylim([-0.8,10])

ax.set_title("Panel B: In--group religious bias", fontsize=18, fontweight = "bold", color="black")

# save figure
plt.savefig(os.path.join(IEC, "output", "judicial_bias", "religion_crime_coef.png"), bbox_inches="tight", dpi=150)

# copy file for public html viewing
home = os.path.expanduser("~")
copyfile(os.path.join(IEC, "output", "judicial_bias", "religion_crime_coef.png"),
         os.path.join(home, "public_html", "png", "religion_crime_coef.png"))


plt.close("all")

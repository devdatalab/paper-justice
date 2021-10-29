import os
import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import warnings

mpl.rcParams['mathtext.fontset'] = 'custom'
mpl.rcParams['mathtext.rm'] = 'Bitstream Vera Sans'
mpl.rcParams['mathtext.it'] = 'Bitstream Vera Sans:italic'
mpl.rcParams['mathtext.bf'] = 'Bitstream Vera Sans:bold'
mpl.rc('font', **{'family': 'serif', 'serif': ['Computer Modern']})
mpl.rc('text', usetex=True)


# define function to assign color based on sign of coefficient
def define_color(val, split, c1="#007cc4", c2="#fc9a19"):
    """
    Define the color for each coef based on whether it is above or
    below a certain value. This function can be customized for any
    color rule you want for your specific plot.
    """
    if val < 2:
        return c1
    else:
        return c2


def coefplot(data, coef, ind, ci=None, varnames="variable", labels=None,
             plot_type="scatter", figpath=None, title=None,
             color=None, split=None, c1="#007cc4", c2="#fc9a19",
             write_coefs=True, split1 = None, split2 = None, split3 = None):

    """
    Make a coefplot.

    data: dataframe with coefficients
    coef: name of variable that contains coefficients
    ci: column containing error value for each coef,
        for now, only symmetrical intervals are supported.
    varnames: name of variable that lists the variable names,
              default is "variable"
    plot_type: "bar" or "scatter" for type of plot to be drawn,
                default is scatter
    figpath: filepath to output figure
    labelkey: name of variable that lists variabel labels to be
              used in plotting, defaults to varnames if none is specified
    color: single color for bars
    split: the threshold value on which to split the colors for the bars
    c1: the color used for coef values below threshold specified by split
    c2: the color used for coef values above threshold specified by split
    write_coefs: True to write the coefficient numbers on the plot itself
    """

    # ----------- #
    # Import Data #
    # ----------- #
    # check if the input data is a filepath
    if isinstance(data, str):

        # expand the path - this converts the "~" to the home directory
        data = os.path.expanduser(data)

        # check if file exists
        if not os.path.isfile(data):
            raise OSError("data filepath does not exist")

        # read in data if it is a csv
        if os.path.splitext(data)[1] == ".csv":
            data = pd.read_csv(data)

        # read in data if it is an excel doc
        elif (os.path.splitext(data)[1] == ".xls") | (os.path.splitext(data)[1] == ".xlsx"):
            data = pd.read_excel(data)

        # read in the data if it is a stat file
        elif os.path.splitext(data)[1] == ".dta":
            data = pd.read_stata(data)

        # else, raise an error that the filepath is the wrong type
        else:
            raise TypeError("filepath must be csv, xls/xlsx, or dta")

    # else, if data is not a dataframe, raise an error
    elif not isinstance(data, pd.DataFrame):
        raise OSError("data input must be filepath or pandas dataframe object")

    # if no figpath is given, default to coefplot.png in the public_html folder
    if figpath is None:
        figpath = f"{os.environ['HOME']}/public_html/png/coefplot.png"

    # check if the figpath is a string
    if isinstance(figpath, str):

        # if figpath has no file extension, set it to .png
        if os.path.splitext(figpath)[1] == "":
            figpath = f"{figpath}.png"

        # if the figpath is not a filepath, assume it is a file name meant to
        # be saved in the public html folder
        if not os.path.exists(figpath):
            figpath = os.path.join(f"{os.environ['HOME']}", figpath)

    # --------- #
    # Data Prep #
    # --------- #
    # ensure coefficients are numeric
    data[coef] = data[coef].astype(float)
    data[ind] = data[ind].astype(float)

    # ensure confidence intervals are numeric, if they are specified
    if ci is not None:
        data[ci] = data[ci].astype(float)

    # if both split and color are specified, raise warning
    if (split is not None) and (color is not None):
        warnings.warn("both split and color are specified, the split value is"
                      "used while color is ignored. to specify split color values,"
                      "use c1 and c2")
    # if split value was specified, assign colors based on the coef value
    if split is not None:
        color_list = tuple([define_color(x, split, c1=c1, c2=c2) for x in list(data[ind])])

    # else, if color is specified
    elif (split is None) and (color is not None):
        color_list = [color for x in data.index]

    # else, if neither split or color was specified, assign a default color to all values
    else:
        color_list = ["#007cc4" for x in data.index]

    # if no labels are specified, set them from the variable column
    if labels is None:
        labels = "labels"

        # replace underscores with spaces because latex text formatting
        # doesn't like the underscores
        data[labels] = [x.replace("_", " ") for x in list(data[varnames])]

    # reassign color of last bar for total
    # color_list = list(color)
    # color_list[0] = "black"
    # color = tuple(color_list)

    # -------- #
    # Plotting #
    # -------- #
    # define the figure
    f, ax = plt.subplots(figsize=[8, 8])

    # plot bar chart if specified
    if plot_type == "bar":
        data[coef].plot(kind="barh", color=color_list, xerr=data[ci])

    # else plot points if sepcified
    elif plot_type == "scatter":

        # make the bar plot with no color to ensure all points are labelled
        data[coef].plot(kind="barh", color="none", xerr=data[ci])

        # plot the points as a scatter plot
        ax.scatter(y=np.arange(data[coef].shape[0]), x=data[coef],
                   marker='o', s=60, color=color_list)

        # if there are confidence intervals, plot them
        if ci is not None:
            ax.errorbar(x=data[coef], y=np.arange(data[coef].shape[0]),
                        xerr=data[ci], fmt="none", ecolor="#798e91")

    # else raise error that plot_type is incorrectly specified
    else:
        raise ValueError("plot_type must be 'bar' or 'scatter'")

    # plot split line if a value was specified
    if split is not None:
        ax.axvline(x=split, linestyle="--", color="black", linewidth=0.75)

    # overwrite yticklabels with proper labels
    ax.set_yticklabels(list(data[labels]), fontsize=12, color="black")

    # make dummy ci if no ci is specified
    if ci is None:
        ci = "ci"
        data["ci"] = 0

    # get the x and y coordinates for plotting the annotation
    data = data.reset_index(drop=True)
    data["x"] = data.apply(
        lambda row: row[coef] + np.sign(row[coef]) * row[ci],
        axis=1
    )

    # add a shift to the x coordinates to ensure they are not
    # plotted on top of the points/errorbars/bars
    xshift = (data["x"].max() - data["x"].min()) * .02
    data["x"] = data["x"].apply(lambda x: x + (np.sign(x) * xshift))

    # get the y coordinate from the index, minus a small shift
    data["y"] = data.index - ((data.index.max() - data.index.min()) * 0.0075)

    # get coefficient as a string
    data["note"] = data["coef"].round(2).astype(str)

    # plot the annotations if specified
    if write_coefs is True:

        # cycle through each row and add annotation
        for i in data.index:
            ax.annotate(
                data.loc[i, "note"],
                (data.loc[i, "x"], data.loc[i, "y"]),
                fontsize=8,
                fontweight="bold",
                color="black",
                ha='center'
            )

    # set axis label
    ax.set_xlabel("Regression coefficients - Acquitted", color="black", fontsize=12)

    # set x axis limit
    ax.set_xlim(-0.06, 0.06)

    # save figure
    plt.savefig(figpath, bbox_inches="tight")
    plt.close("all")

    return f, ax

f, ax = coefplot("/scratch/adibmk/coef_cm.dta", "coef", "ind", ci="ci", varnames = "variables", plot_type="scatter", title ="Judicial bias results (court-month fixed effects)", split=0, figpath="iec/output/judicial_bias/court_month",  write_coefs=False, c1="#9ad453",  c2="#53c5d4")

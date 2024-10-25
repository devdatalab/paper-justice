import geopandas as gpd
import os
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import time
import rasterio
from rasterio.plot import show
from collections import Counter
from shapely.geometry import Point, LineString, box, Polygon
from IPython.core.display import display, HTML
from pathlib import Path
from shutil import copyfile

# get the tmp and iec environment vars
TMP = Path(os.environ.get('TMP'))
IEC = Path(os.environ.get('IEC'))

# set some master parameters to make the font look good
mpl.rcParams['mathtext.fontset'] = 'custom'
mpl.rcParams['mathtext.rm'] = 'Bitstream Vera Sans'
mpl.rcParams['mathtext.it'] = 'Bitstream Vera Sans:italic'
mpl.rcParams['mathtext.bf'] = 'Bitstream Vera Sans:bold'
mpl.rc('font', **{'family': 'serif', 'serif': ['Computer Modern']})

# this turns on latex, which makes font and number look really nice, but also 
# forces latex syntax which can cause problems (can be set to False)
mpl.rc('text', usetex=False)

# this sets the dots per inch- it's the resolution the figure will render at.
# make this larger for more precise rendering, though larger sizes will take longer
mpl.rcParams['figure.dpi'] = 100

#load justice RCT district-level court count data
justice_rct = pd.read_stata(os.path.join(TMP, "justice_rct.dta"))

#load justice district keys
justice_key = pd.read_stata(os.path.join(TMP, "pc11_court_district_key.dta"))

#Join RCT sample with district keys on state and district 
justice_rct = justice_rct.merge(justice_key, left_on = ['state_code', 'dist_code'], 
                            right_on = ['state_code', 'dist_code'], how = "left")

#rename variables to match with shape file
justice_rct = justice_rct.rename(columns={'court_count':'court_count_rct',
                                          'pc11_state_id': 'pc11_s_id', 'pc11_district_id': 'pc11_d_id'})
#load district-level shapefile
geodist = gpd.read_file(f"{os.environ['IEC']}/gis/pc11/mlinfo/pc11-district.shp")

#Convert dataframe to a geodataframe
geodist = gpd.GeoDataFrame(geodist)

#join RCT analysis sample with district spatial dataset
geodist = geodist.merge(justice_rct, left_on = ['pc11_s_id', 'pc11_d_id'], 
                        right_on = ['pc11_s_id', 'pc11_d_id'], how = "left")

#create identifier for districts belonging in the RCT sample
geodist["rct"] = np.where(geodist["court_count_rct"] > 0, 1, 0)

#Add States' Outlines
geostate = gpd.read_file(f"{os.environ['IEC']}/gis/pc11/mlinfo/pc11-state.shp")

## plot court count maps for RCT Analysis Sample
# choose colormap
cmap = "viridis_r"

# set up figure
fu, axu = plt.subplots(figsize=[10,10])

# plot data
geodist.plot(ax=axu, column="court_count_rct", 
             cmap = cmap, missing_kwds = dict(color = "whitesmoke", linewidth = 1.3), alpha = 0.9)
geostate.plot(ax = axu, color = "none", linewidth = 0.2, alpha = 0.9)

# axis settings
axu.set_aspect("equal")
axu.grid(True)
axu.yaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.xaxis.grid(color='gray', linewidth=0.25, linestyle="--")
axu.grid(zorder=0)
axu.set_title("Distribution of Courts in analysis Sample")

# add custom colorbar
# l:left, b:bottom, w:width, h:height; in normalized unit (0-1)
cax = fu.add_axes([0.94, 0.2, 0.025, 0.6])
sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(vmin=0, vmax=90))
sm._A = []
cbar = fu.colorbar(sm, cax=cax)
cbar.ax.set_ylabel("Number of Courts", labelpad=20, fontsize=14, rotation=270)

# save figure
plt.savefig(os.path.join(IEC, "output", "judicial_bias", "court_map_rct.png"), bbox_inches="tight", dpi=150)

# copy file for public html viewing
home = os.path.expanduser("~")
copyfile(os.path.join(IEC, "output", "judicial_bias", "court_map_rct.png"),
         os.path.join(home, "public_html", "png", "court_map_rct.png"))

plt.close("all")


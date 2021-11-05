# paper-judicial-bias-india

## Overview
These code and data files replicate the results in "Measuring Gender and Religious Bias in the Indian Judiciary," by Elliot Ash, Sam Asher, Aditi Bhowmick, Daniel Chen, Tanaya Devi, Christoph Goessman, Paul Novosad, Bilal Siddiqi (2021). A working paper version of the manuscript can be found [here](http://paulnovosad.com/pdf/india-judicial-bias.pdf).

---
## Replication Code and Data for Judicial bias (India, 2021)
To regenerate the tables and figures from the paper, take the following steps:

* Download and unzip the replication data package from [here](https://drive.google.com/file/d/1N_7vKKRDiBHhMZT5eRqNszR1aksMrlJd/view?usp=sharing)

* Open the do file `make_justice_results.do`, and set the globals `out`, `repdata`, `tmp`, and `jcode`.

1. `$out` is the target folder for all outputs, such as tables and graphs.
2. `$tmp` is the folder for the data files and temporary data files that will be created during the rebuild.
3. `$jdata` is the folder where you unzipped and saved the replication data package.
4. `$jcode` is the code folder of the clone of the replication repo

* Run the do file `make_justice_repl.do`. This will run through all the other do files to regenerate all of the results.

* We have included all the required programs to generate the main results. However, some of the estimation output commands (like estout) may fail if certain Stata packages are missing. These can be replaced by the estimation output commands preferred by the user.

* Please note we use globals for pathnames, which will cause errors if filepaths have spaces in them. Please store code and data in paths that can be access without spaces in filenames.

* This code was tested using Stata 15.0. Run time to generate all results on our server was about 8 hours.

## Data download

To download the data needed to replicate this paper in zipped tarball format, please [click here](https://drive.google.com/file/d/1N_7vKKRDiBHhMZT5eRqNszR1aksMrlJd/view?usp=sharing).

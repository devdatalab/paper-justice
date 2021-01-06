# paper-justice

---
## Replication Code and Data for Justice bias 2021
To regenerate the tables and figures from the paper, take the following steps:

* Download and unzip the replication data package from this Google Drive folder (not yet linked--waiting for sharing permission)

1. To get as many files as possible in .dta form, plus necessary CSVs, use this link (tbd)
2. To get all the files in CSV format, use this link (tbd)
3. Regardless of your choice from the two above options, use this link (tbd) to download the case records and judge records data, which can be used to re-build the clean analysis dataset.
4. Clone this repo and switch to the code folder.

* Open the do file `make_justice_repl.do`, and set the globals `out`, `repdata`, `tmp`, and `jcode`.

1. `$out` is the target folder for all outputs, such as tables and graphs.
2. `$tmp` is the folder for the data files and temporary data files that will be created during the rebuild.
3. `$repdata` is the folder where you unzipped and saved the replication data package.
4. `$jcode` is the code folder of the clone of the replication repo

* Run the do file `make_justice_repl.do`. This will run through all the other do files to regenerate all of the results.

* We have included all the required programs to generate the main results. However, some of the estimation output commands (like estout) may fail if certain Stata packages are missing. These can be replaced by the estimation output commands preferred by the user.

* Please note we use globals for pathnames, which will cause errors if filepaths have spaces in them. Please store code and data in paths that can be access without spaces in filenames.

* This code was tested using Stata 15.0. Run time to generate all results on our server was about __ minutes.


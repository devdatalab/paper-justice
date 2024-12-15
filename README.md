# In-group bias in the Indian judiciary

## Overview
These code and data files replicate the results in "In-group bias in the Indian judiciary: Evidence from 5 million criminal cases" by Elliot Ash, Sam Asher, Aditi Bhowmick, Daniel Chen, Tanaya Devi, Christoph Goessman, Paul Novosad, Bilal Siddiqi (2021). A working paper version of the manuscript can be found [here](http://paulnovosad.com/pdf/india-judicial-bias.pdf).

## Data Availability

All data sources used in the paper are available in the paper's data packet.The primary data source is the recently digitized data from the eCourts platform (a semi-public system by Indian government to host summary data and full text from orders and judgements in courts across the country) on the outcomes of close to the universe of criminal cases in India from 2010-2018. The data files are separated by each year and follows the naming convention "cases_clean_20xx".

The authors have legitimate access to and permission to use the data used in this manuscript.

## Description of Data Files

| Dataset             | Description      |
|:-------------------:|:----------------:|
| `cases_clean_2010` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2010. |
| `cases_clean_2011` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2011. |
| `cases_clean_2012` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2012. |
| `cases_clean_2013` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2013. |
| `cases_clean_2014` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2014. |
| `cases_clean_2015` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2015. |
| `cases_clean_2016` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2016. |
| `cases_clean_2017` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2017. |
| `cases_clean_2018` | The file contains data on all criminal court cases from Indian lower Judiciary from the year 2018. |
| `judges_clean` | The file contains data on judges in all courts in the Indian lower judiciary from the eCourts platform.|
| `poi_master` | The file contains data on People of India; only modules used in the data are shared.|
| `ACLED_India_violence_2005-2023` | The file contains data on violent conflict and protests in India, collected by ACLED (Armed Conflict Location & Event Data) which is an independent, impartial, international non-profit organization collecting data on violent conflict and protest across the world.|
| `acled_districts` | The file contains keys to match the ACLED violence data to Indian districts. |

## Computational Requirements

This package is designed to be run on a *nix system with Python 3.2+, Matlab 2019+, and Stata 16+ installed. Data and code folders for the replication must not include spaces. This package may require modification to run on Windows due to the use of some Unix shell commands. This package was tested on a system with about 30 GB of memory.

## Description of programs / code

The file `make_justice.do` describes the build and analysis process in detail.

---
## Instruction to Replicators
To regenerate the tables and figures from the paper, take the following steps:

* Download and unzip the replication data package from [here](https://www.dropbox.com/scl/fo/cfq579yumprye6t9l1h0j/AL6Xo6LLZ7WcYHBgqODdbm4?rlkey=aq0v86upxy21qi0q8lji2j97i&st=9gofrsko&dl=0).

* Clone this repo (github) or copy all the code into a folder.

* Create a python environment following the package list in `requirements.yml`. For example:

```
conda env create -f requirements.yml -n py_justice
conda activate py_justice
```

* Set the following environment variables so that Python will be able to find the data and output paths. From the Unix/OSX shell (before running Stata):

```
export TMP=[path to working files]
export OUT=[destination path for exhibits]
export JDATA=[folder where the replication data package is unzipped]
```

* Open the do file `make_justice.do`, and set the globals `out`, `jdata`, `tmp`, and `jcode`. These need to match the environment variables set in the previous step!

1. `$out` is the target folder for all outputs, such as tables and graphs.
2. `$tmp` is the folder for the data files and temporary data files that will be created during the rebuild.
3. `$jdata` is the folder where you unzipped and saved the replication data package.
4. `$jcode` is the code folder of the clone of the replication repo

* Run the do file `make_justice.do`. This will run through all the other do files to regenerate all of the results.

* We have included all the required programs to generate the main results. However, some of the estimation output commands (like estout) may fail if certain Stata packages are missing. These can be replaced by the estimation output commands preferred by the user.

* Please note we use globals for pathnames, which will cause errors if filepaths have spaces in them. Please store code and data in paths that can be access without spaces in filenames.

* This code was tested using Stata 16.0. Run time to generate all results on our server was about 8 hours.

The mapping of do files to tables and figures is as follows:

| Exhibit | Code filename                    | Output                             Filename                    |
|-----------|----------------|-----------------------|
| Figure  1  |   make_gender_coefplot.py     | g_coef1.png, g_coef2.png, r_coef1.png, r_coef2.png |
| Table   1   |  judge_summary.do            | judge_summary.tex                  |
| Table   2   |  table_rct_gender.do         | gender_acquitted.tex               , gender_decision.tex       |
| Table   3   |  table_rct_religion.do       | religion_acquitted.tex             , religion_decision.tex     |
| Table   4   |  table_victim_ramadan.do     | victim_inter.tex                   |
| Table   5   |  test_same_lastname.do       | last_names.tex                     |
| Figure  2  |   prep_lit_coefs.do           , graph_scatter_pub_bias.do          | lit_coef.png              , pub_bias.png |
| Table   6   |  graph_scatter_pub_bias.do   | pub_bias.tex                       |
| Figure  A5     | explore_discretion.do     | judge_acquittal_resids.png         |
| Figure  A6     | test_same_lastname_app.do | name_balance_coef_rcap.png         |
| Figure  A7     | test_same_lastname_app.do | rare_names_weighted.png            , rare_names_unweighted.png |
| Table   A2     | table_sample_representativeness.do | table_crime_in_sample.tex          , table_state_in_sample.tex |
| Table   A3     | class_success.do          | class_success.tex                  |
| Table   A5     | robustness_checks.do      | gender_amb.tex                     |
| Table   A6     | robustness_checks.do      | religion_amb.tex                   |
| Table   A7     | table_rct_gender.do       | gender_non_convicted.tex           |
| Table   A8     | table_rct_gender.do       | gender_acquitted_amb.tex           |
| Table   A9     | table_rct_religion.do     | religion_non_convicted.tex         |
| Table   A10    | table_rct_religion.do     | religion_acquitted_amb.tex         |
| Table   A11    | summary_stats.do          | gbal.tex                           |
| Table   A12    | summary_stats.do          | rbal.tex                           |
| Table   A13    | table_rct_statewise.do                        | output_sample_accounting_1.tex     |
| Table   A14    | table_rct_statewise.do                        | output_sample_accounting_2.tex     |
| Table   A15    | table_balance_extended.do | balance_extended_missing.tex       |
| Table   A16    | table_balance_extended.do | balance_extended_lawyers.tex       |
| Table   A17    | table_judge_type_by_crime_cat.do                        | table_judges_by_crime_category.tex |
| Table   A18    | explore_ambiguity.do      | low_ambiguity_rcts.tex             |
| Table   A19    | table_balance_lawyers.do  | balance_lawyers.tex                |
| Table   A20    | table_rct_lawyers.do      | lawyers_religion.tex               |
| Table   A21    | table_rct_lawyers.do      | lawyers_gender.tex                 |
| Table   A22    | table_victim_ramadan.do   | victim_inter_all_g.tex             |
| Table   A23    | table_victim_ramadan.do   | victim_inter_all_r.tex             |
| Table   A24    | crimes_against_women.do   | crimes_against_women.tex           |
| Table   A25    | table_victim_ramadan.do   | victim_inter_cy.tex                |
| Table   A26    | table_rct_by_year.do      | rct_2year_bins.tex                 |
| Table   A27    | tables_election_month.do                        | table_election_month.tex           |
| Table   A28    | test_same_lastname.do     | last_names_loc_year.tex            |
| Table   A29    | test_same_lastname_app.do | surname_freq_table.tex             |
| Table   A30    | table_ingroup_poi.do                        | table_balance_poi.tex              |
| Table   A31    | table_ingroup_poi.do      | table_ingroup_poi.tex              |
| Table   B1     | table_balance.do          | random_acq.tex                     |

## Data download

The data to replicate this paper is available at this link: [click here](https://www.dropbox.com/scl/fo/cfq579yumprye6t9l1h0j/AL6Xo6LLZ7WcYHBgqODdbm4?rlkey=aq0v86upxy21qi0q8lji2j97i&st=9gofrsko&dl=0).

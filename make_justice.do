/* This runs multiple do files in sequence to build the analysis
   dataset for the justice project and to run the analysis. */

/* The starting point is $jdata/cases_clean_*.dta.
   These are generated by make_justice_prebuild.do  */

/* install needed Stata programs */
cap ssc install ivreghdfe
cap ssc install ivreg2
cap ssc install ranktest
cap ssc install rangejoin
cap ssc install rangestat
cap ssc install reclink
cap ssc install reghdfe
cap ssc install ftools
cap ssc install estout
cap ssc install savesome
cap ssc install estout, replace
cap ssc install texsave
cap ssc install distinct

/* set globals for stata-tex */
global PYTHONPATH ~/ddl/stata-tex

/* set globals for code and data */
global jcode ~/ddl/paper-justice
global jdata /dartfs-hpc/scratch/muhtadi/justice/replication/raw

global norms $jdata
global MASALA_PATH ~/paper-justice/masala-merge
global STATATEX_PATH ~/paper-justice/stata-tex

#global tmp
global out /scratch/muhtadi

/* timestamp so we know how long this takes */
di c(current_date)
di c(current_time)

/* load justice programs */
do $jcode/justice_progs

/* load custom stata programs */
do $jcode/tools.do

do $jcode/masala-merge/masala_merge.do
do $jcode/stata-tex/stata-tex.do

/***********************************************************/
/* Step 4: Prepare analysis datasets for RCT & event study */
/***********************************************************/

/* build rct analysis dataset */
do $jcode/b/build_rct_analysis.do 
di c(current_time)
/* validate classification in case reclassification of names */
/* was done as part of re-running this make */
/* note that build will crash here if smth was off with re-classification */
/* in such a case, open up this do file and debug */
// do $jcode/b/validate_reclassification.do
 
/* clean up the csv with coefficients from the literature  */
do $jcode/b/prep_lit_coefs.do

/* prep analysis dataset for last names analysis */
do $jcode/b/build_lastname_analysis.do

/* prepare lawyer analysis */
/* Note this is here to understand the build, but we in fact don't run this file, which involves a manual name selection step. */
/* This file creates the CSV exclusion list $jcode/b/csv/lawyer_non_names.csv */
// do $jcode/b/create_lawyer_name_exclusion_list.do

/* prepare religious violence data */
do $jcode/b/create_riots_indicators.do
di c(current_time)

/* clean up POI data */
do $jcode/b/prep_poi_data.do
  
/* prep caste categories in POI dataset */
do $jcode/b/prep_poi_caste_names.do

/*******************************/
/* ANALYSIS - TABLES & FIGURES */
/*******************************/

/* insert timer */
timer on 1

/* Table 1 in paper: coding of outcome variables */
/* created in overleaf itself */

/* Table 2: Outcome probability, by judge identity (summary stat) */
do $jcode/a/judge_summary.do

/* Tables A3 & A4: Summary stats by defendant characteristics*/
do $jcode/a/summary_stats.do
di c(current_time)

/* Fig 1: Coefplots */
python script $jcode/a/py/make_gender_coefplot.py
python script $jcode/a/py/make_gender_coefplot2.py
python script $jcode/a/py/make_religion_coef.py
python script $jcode/a/py/make_religion_coef2.py
di c(current_time)

/* Tables 5, A6, A8: RCT gender results */
do $jcode/a/table_rct_gender.do
do $jcode/a/table_victim_ramadan.do

/* creates tables for bias by lawyer identity */
do $jcode/a/table_rct_lawyers.do

/* Tables 6, A7, A9: RCT religion results */
do $jcode/a/table_rct_religion.do
di c(current_time)
/* Figure 4: Literature coefplot and scatter */
python script $jcode/a/py/make_coefplot_literature.py
do $jcode/a/graph_scatter_pub_bias.do
di c(current_time)
/* Appendix: validation of LSTM muslim classifier */
// Commented, since it does not produce any outputs used by the paper
// do $jcode/a/validate_lstm_muslim.do

/* Table 3: Test for random assignment to judges */
/* Note: this needs to come below table_rct_lawyer.do */
do $jcode/a/table_balance.do

/* Table Ax: Balance table for the lawyer subsample */
do $jcode/a/table_balance_lawyers.do

/* Appendix: court size distribution */
do $jcode/a/graph_court_size.do

/* Appendix: classification rates by state */
do $jcode/a/class_success.do

/* Appendix: Robustness check tables */
do $jcode/a/robustness_checks.do
di c(current_time)
/* figure for the appendix - in-group bias by crime category */
/* dropped from manuscript */
//do $jcode/a/crime_type_analysis.do
//python script $jcode/a/py/crime_type_coefplot.py

/* Appendix: Summary stats of datasets used to train the name classifier */
/* Not in replication package to preserve privacy of individual names */
// do $jcode/a/training_sum_stats.do

/* Appendix: Statewise religious in group bias tables */
do $jcode/a/table_rct_statewise.do

/*****************/
/* New analyses  */
/*****************/

/* last name test */
do $jcode/a/test_same_lastname.do

/* maps for court distribution */
do $jcode/a/court_count_district.do
di c(current_time)
timer off 1
timer list

// Omit court maps from replication, since they require restricted MLInfoMap district shapefile
// python script $jcode/a/py/court_count_maps.py

/***************************/
/* New analysis 06/10/2022 */
/***************************/

/* results on religious violence */
do $jcode/a/table_religious_riots.do

/* results adjusting for ambiguity rate */
do $jcode/a/explore_ambiguity.do

/* explore judge discretion (judge FE R2) */
do $jcode/a/explore_discretion.do

/* show that drops due to missing defendants are representative by state/crime */
do $jcode/a/table_sample_representativeness.do

/***************************/
/* R&R Analyses */
/***************************/

/* extended balance analysis */
do $jcode/a/table_balance_extended.do

/* extended last name analysis */
do $jcode/a/test_same_lastname_app.do

/* last name analysis including unmatched names */
do $jcode/a/test_same_lastname_unmatched.do

/* partition into different year bins */
do $jcode/a/table_rct_by_year.do

/* religious violence Results */
do $jcode/a/table_religious_riots.do

/* IV version of main gender / religion ingroup results */
do $jcode/a/table_rct_iv.do

/* appendix table of in-group bias for sexual assault vs. other crimes against women */
do $jcode/a/crimes_against_women.do

/* main ingroup bias analysis, POI dataset */
do $jcode/a/table_ingroup_poi.do

/* appendix table of distribution of female and muslim judges by crime category */
do $jcode/a/table_judge_type_by_crime_cat.do

/***************************************************/
/* JUSTICE DATA BUILD AND ANALYSIS FOR REPLICATION */
/***************************************************/

/********************************************/
/* FRONT MATTER: PATHS, PROGRAMS, AND TOOLS */
/********************************************/

/* clear any existing globals, programs, data to make sure they don't clash */
clear all

/* set the following globals:
$out: path where output files will be created
$repdata: path to initial data inputs 
$tmp: intermediate data files will be put here
$jcode: path to folder of build and analysis .do and .py files*/

global out ~/paper-justice/exhibits
global jdata /scratch/adibmk/justice
global tmp  /scratch/f004qzy/justice-test
global jcode ~/paper-justice/code

if mi("$out") | mi("$tmp") | mi("$datapath, eg.$mining") {
  display as error "Globals 'out', 'tmp', and 'datapath, eg.$mining' must be set for this to run."
  error 1
}

/* load Stata programs */
qui do tools.do
qui do masala-merge/masala_merge
qui do stata-tex/stata-tex
qui do ado/justice_programs.do

/* add ado folder to adopath */
adopath + ado

cap log close
log using $out/logfilename.log, text replace


/* define programs for justice analysis */
do $jcode/ado/justice_programs.do
do $jcode/ado/tools.do

/************/
/* ANALYSIS */
/************/

/* Table 2: Outcome probability, by judge identity (summary stat) */
do $jcode/a/judge_summary.do

/* Table 3: Test for random assignment to judges */
do $jcode/a/tables_balance.do

/* Tables A3 & A4: Summary stats by defendant characteristics*/
do $jcode/a/summary_stats.do

/* Tables 5, A6, A8: RCT gender results */
do $jcode/a/tables_rct_gender.do

/* Tables 6, A7, A9: RCT religion results */
do $jcode/a/tables_rct_religion.do

/* Figure 4: Literature coefplot and scatter */
shell python $jcode/a/py/make_coefplot_literature.py
do $jcode/a/graph_scatter_pub_bias.do

/* Appendix: court size distribution */
do $jcode/a/graph_court_size.do

/* Appendix: Robustness check tables */
do $jcode/a/robustness_checks.do

/* victim analysis */
do $jcode/a/table_victim_mismatch.do

/* last name test */
do $jcode/a/test_same_lastname.do

/* ramadan analysis */
do $jcode/a/table_ramadan.do

/* maps for court distribution */
do $jcode/a/court_count_district.do

/* note that environment py_spatial should be activated */
/* for script below to run */
shell python $jcode/a/py/court_count_maps.py

log close

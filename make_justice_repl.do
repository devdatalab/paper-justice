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

global out
global repdata 
global tmp 
global jcode 

/* redirect several directories used in the code to $repdata */
global jdata $repdata

/* display an error and break if any of the globals are empty or set to old values*/
if "$out" == "" | regexm("$out", "iec|ddl| ") ///
    display  "error: Global out not set properly. See instructions in README"

if "$repdata" == "" | regexm("$repdata", "iec|ddl| ") ///
    display  "error: Global repdata not set properly. See instructions in README"

if "$mcode" == "" | regexm("$jcode", "iec| ") ///
    display  "error: Global mcode not set properly. See instructions in README"

if "$tmp" == "" | regexm("$tmp", "iec|ddl| ") ///
    display  "error: Global tmp not set properly. See instructions in README"

/* set the makefile to crash immediately if globals aren't set properly  */
if "$out" == "" | regexm("$out", "iec|ddl| ") ///
    | "$repdata" == "" | regexm("$repdata", "iec|ddl| ") ///
    | "$tmp" == "" | regexm("$tmp", "iec|ddl| ") ///
    | "$mcode" == "" | regexm("$jcode", "iec| ") ///
    exit 1

/* define programs for justice analysis */
do $jcode/ado/justice_programs.do
do $jcode/ado/tools.do

/*********/
/* BUILD */
/*********/

/* Prep judge-level dataset */
do $jcode/b/create_judges_clean.do

/* Prep court-level dataset */
do $jcode/b/create_court_ts.do

/* Merge judge-case, and court-case data to create analysis datasets */
do $jcode/b/build_case_analysis.do 

/************/
/* ANALYSIS */
/************/

/* Table with judge-level summary statistics */
do $jcode/a/judge_summary.do

/* Balance table to check random case asssignment */
do $jcode/a/tables_balance.do

/* Summary statistics by crime category */
do $jcode/a/summary_stats.do

/* Visual representation of crime category summary statistics */
/* Fig 1 in paper */
shell python $jcode/a/py/make_gender_coefplot.py
shell python $jcode/a/py/make_gender_coefplot2.py
shell python $jcode/a/py/make_religion_coefplot.py
shell python $jcode/a/py/make_religion_coefplot2.py

/* Tables 5, A6, A8: RCT gender results */
do $jcode/a/tables_rct_gender.do

/* Tables 6, A7, A9: RCT religion results */
do $jcode/a/tables_rct_religion.do

/* Table 7, and Figs 2 & 3: Event study tables & figures */
do $jcode/a/event_study_analysis.do

/* Figure 4: Literature coefplot */
shell python $jcode/a/py/make_coefplot_literature.py

/* Appendix: Validation of LSTM muslim classifier */
do $jcode/a/validate_lstm_muslim.do

/* Appendix: Court size distribution */
do $jcode/a/graph_court_size.do

/* Appendix: Sub-sample analysis - crimes against women */
do $jcode/a/women_analysis.do

/* Appendix: Event study - other outcomes */
do $jcode/a/event_study_other_outcomes.do


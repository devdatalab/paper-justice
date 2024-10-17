/**************************************************************************************************/
/* run the last name analysis on the sample with defendant names that may not match any judge name*/
/* ie, on the intermediate dataset saved before match_rate==0 in build_lastname_analysis.do */
/**************************************************************************************************/
tgo //04:20:33 Starting timer 1.
use $tmp/justice_same_names_unmatched, clear

/* PN NEXT STEPS:
- the inverse weighting might put way too much weight on names that we only observe
  one time, which are probably not even real names. As a next step, we could keep
  all the judges, but drop defendants from last name groups that appear less than 100
  times in the whole dataset --- this would probably cut things down quite a bit in terms
  of speed.

*/

/* drop defendant names who appear less than 100 times in the dataset */
// bys dgroup: egen dcount = count(dgroup)
// drop if dcount < 100

/* drop weighty string vars */
drop judge_last_name name def_last_name def_name def_name_clean

/* four regressions for the table. With and without judge FE, loc-month and loc-year fixed effects */
/* unweighted, without and with judge FE */
eststo clear

reghdfe acq same_last_name def_female def_muslim, absorb(dgroup jgroup loc_month acts)
estadd local FE "Court-month"
estadd local judge "No"
estadd local wt "No"
estadd local namefe "Yes"
estimates store m1 

di c(current_time) //05:00:06

// reghdfe acq same_last_name def_female def_muslim, absorb(dgroup jgroup loc_month acts judge)
// estadd local FE "Court-month"
// estadd local judge "Yes"
// estadd local wt "No"
// estadd local namefe "Yes"
// estimates store m2

di c(current_time) //5:32:01

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts)
estadd local FE "Court-month"
estadd local judge "No"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m2

di c(current_time) //7:00:11

// reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts judge)
// estadd local FE "Court-month"
// estadd local judge "Yes"
// estadd local wt "Yes"
// estadd local namefe "Yes"
// estimates store m4 

di c(current_time) //9:48:04

/* two more weighted columns: interact rare name indicator with treatment */
reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts)
estadd local FE "Court-month"
estadd local judge "No"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m3
test same_rare_wt + same_last_name = 0

di c(current_time) //11:26:48

/* repeat with judge FE */
// reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts judge)
// estadd local FE "Court-month"
// estadd local judge "Yes"
// estadd local wt "Yes"
// estadd local namefe "Yes"
// estimates store m6
// test same_rare_wt + same_last_name = 0

di c(current_time) //14:42:16

tstop //10.55 hours


/* repeat all tests with court-year FE */

tgo
eststo clear

reghdfe acq same_last_name def_female def_muslim, absorb(dgroup jgroup loc_year acts)
estadd local FE "Court-year"
estadd local judge "No"
estadd local wt "No"
estadd local namefe "Yes"
estimates store m4

// reghdfe acq same_last_name def_female def_muslim, absorb(dgroup jgroup loc_year acts judge)
// estadd local FE "Court-year"
// estadd local judge "Yes"
// estadd local wt "No"
// estadd local namefe "Yes"
// estimates store m2

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_year acts)
estadd local FE "Court-year"
estadd local judge "No"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m5 

// reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_year acts judge)
// estadd local FE "Court-year"
// estadd local judge "Yes"
// estadd local wt "Yes"
// estadd local namefe "Yes"
// estimates store m4 

reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_year acts)
estadd local FE "Court-year"
estadd local judge "No"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m6
test same_rare_wt + same_last_name = 0

// reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_year acts judge)
// estadd local FE "Court-year"
// estadd local judge "Yes"
// estadd local wt "Yes"
// estadd local namefe "Yes"
// estimates store m6
// test same_rare_wt + same_last_name = 0

esttab m1 m2 m3 m4 m5 m6 using $out/last_names_unmatched.tex, replace se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "wt Inverse Group Weight" "namefe Last Name Fixed Effect") drop(_cons def_female def_muslim) b(3)  

tstop

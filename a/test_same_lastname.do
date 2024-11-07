/******************************/
/* run the last name analysis */
/******************************/
tgo
use $jdata/justice_same_names, clear

/* shrink to fields we actually need */
keep acq same_last_name def_female def_muslim dgroup jgroup loc_month loc_year acts wt judge same_rare_wt

/* four regressions for the table. With and without judge FE, loc-month and loc-year fixed effects */
/* unweighted, without and with judge FE */
eststo clear

reghdfe acq same_last_name def_female def_muslim, absorb(dgroup jgroup loc_month acts)
estadd local FE "Court-month"
estadd local judge "No"
estadd local wt "No"
estadd local namefe "Yes"
estimates store m1 

/* store sample size from regression above in a local */
count if e(sample) == 1
local sample_1: di `r(N)'

/* store bias coefficient in a local */
local last_name_cm: di _b["same_last_name"]

reghdfe acq same_last_name def_female def_muslim, absorb(dgroup jgroup loc_month acts judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local wt "No"
estadd local namefe "Yes"
estimates store m2

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts)
estadd local FE "Court-month"
estadd local judge "No"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m3 

/* store sample size from regression above in a local */
count if e(sample) == 1
local sample_2: di `r(N)'

/* store bias coefficient in a local */
local last_name_cy: di _b["same_last_name"]

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m4 

/* two more weighted columns: interact rare name indicator with treatment */
reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts)
estadd local FE "Court-month"
estadd local judge "No"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m5
test same_rare_wt + same_last_name = 0

/* repeat with judge FE */
reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m6
test same_rare_wt + same_last_name = 0

esttab m1 m2 m3 m4 m5 m6 using $out/last_names.tex, replace se(4) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "judge Judge Fixed Effect" "wt Inverse Group Weight" "namefe Last Name Fixed Effect") drop(_cons def_female def_muslim) b(4)  

/* write stored statistics in the paper stats csv file */
// store_validation_data `sample_1' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Last name bias result - court-month: sample") group("same caste bias")
// store_validation_data `sample_2' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Last name bias result - court-year: sample") group("same caste bias")
// store_validation_data `last_name_cm' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Last name bias result - court-month: coef") group("same caste bias")
// store_validation_data `last_name_cy' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Last name bias result - court-year: coef") group("same caste bias")

// /* generate count statistics described in the text */
// tag judge
// 
// table rare_name same_last_name , c(mean acq n acq)
// table rare_name_wt same_last_name , c(mean acq n acq)
// 
// table rare_name same_last_name if jtag, c(mean acq n acq)
// table rare_name_wt same_last_name if jtag, c(mean acq n acq)
// 
// tstop


/*****************************************************/
/* repeat above analysis with loc_year fixed effects */
/*****************************************************/
use $jdata/justice_same_names, clear

eststo clear

reghdfe acq same_last_name def_female def_muslim, absorb(dgroup jgroup loc_year acts)
estadd local FE "Court-year"
estadd local judge "No"
estadd local wt "No"
estadd local namefe "Yes"
estimates store m1 

reghdfe acq same_last_name def_female def_muslim, absorb(dgroup jgroup loc_year acts judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estadd local wt "No"
estadd local namefe "Yes"
estimates store m2

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_year acts)
estadd local FE "Court-year"
estadd local judge "No"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m3 

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_year acts judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m4 

reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_year acts)
estadd local FE "Court-year"
estadd local judge "No"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m5
test same_rare_wt + same_last_name = 0

reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_year acts judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estadd local wt "Yes"
estadd local namefe "Yes"
estimates store m6
test same_rare_wt + same_last_name = 0

esttab m1 m2 m3 m4 m5 m6 using $out/last_names_loc_year.tex, replace se(4) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "judge Judge Fixed Effect" "wt Inverse Group Weight" "namefe Last Name Fixed Effect") drop(_cons def_female def_muslim) b(4)  

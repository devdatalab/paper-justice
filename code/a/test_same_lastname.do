/******************************/
/* run the last name analysis */
/******************************/
use $jdata/justice_same_names, clear

la var same_last_name "Same last name"

la var acq "Acquitted"

/* four regressions for the table. With and without judge FE, loc-month and loc-year fixed effects */
/* unweighted, without and with judge FE */
eststo clear

/* log timestamp */
set_log_time

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup loc_month acts)
estadd local FE "Court-month"
estadd local judge "No"
estimates store m1 

/* store sample size from regression above in a local */
count if e(sample) == 1
local sample_1: di `r(N)'

/* store bias coefficient in a local */
local last_name_cm: di _b["same_last_name"]

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup loc_month acts judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estimates store m2

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup loc_year acts)
estadd local FE "Court-year"
estadd local judge "No"
estimates store m3 

/* store sample size from regression above in a local */
count if e(sample) == 1
local sample_2: di `r(N)'

/* store bias coefficient in a local */
local last_name_cy: di _b["same_last_name"]

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup loc_year acts judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estimates store m4 

esttab m1 m2 m3 m4 using $out/last_names.tex, replace se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "judge Judge Fixed Effect") drop(_cons def_female def_muslim) b(3)  

/* write stored statistics in the paper stats csv file */
store_validation_data `sample_1' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Last name bias result - court-month: sample") group("same caste bias")
store_validation_data `sample_2' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Last name bias result - court-year: sample") group("same caste bias")
store_validation_data `last_name_cm' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Last name bias result - court-month: coef") group("same caste bias")
store_validation_data `last_name_cy' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Last name bias result - court-year: coef") group("same caste bias")

bias")


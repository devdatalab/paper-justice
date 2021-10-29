cap log close
log using $out/table_victim_analysis.log, replace

/* open analysis dataset */
use $jdata/justice_analysis, clear

/* create a variable that takes value 1 if victim identity */
/* and defendant identity vary */
gen gender_mismatch = (def_female + pet_female) == 1 if !mi(def_female) & !mi(pet_female)
gen religion_mismatch = (def_muslim + pet_muslim) == 1 if !mi(def_muslim) & !mi(pet_muslim)

/* regenerate judge fixed effect which is wrong in this dataset for some reason */
drop judge
egen judge = group(ddl_filing_judge_id)

/* create victim interaction variables */
gen jdmale_mis = judge_def_male * gender_mismatch
gen jmale_mis = judge_male * gender_mismatch
gen dmale_mis = def_male * gender_mismatch
gen jdmus_mis = judge_def_muslim * religion_mismatch
gen jmus_mis = judge_muslim * religion_mismatch
gen dmus_mis = def_muslim * religion_mismatch

/* create crimes against women interactions */
gen jdmale_wc = judge_def_male * women_crime
gen jmale_wc = judge_male * women_crime
gen dmale_wc = def_male * women_crime

/* label variables */
la var gender_mismatch "Gender mismatch"
la var religion_mismatch "Religion mismatch"
la var judge_male "Male judge"
la var judge_muslim "Muslim judge"
la var def_muslim "Muslim defendant"
la var def_male "Male defendant"
la var acq "Acquitted"
label drop muslim

la var jdmale_mis "Male judge and defendant * Mismatch"
la var jmale_mis "Male judge * Mismatch"
la var dmale_mis "Male defendant * Mismatch"
la var jdmus_mis "Muslim judge and defendant * Mismatch"
la var jmus_mis "Muslim judge * Mismatch"
la var dmus_mis "Muslim defendant * Mismatch"
la var jdmale_wc "Male judge and defendant * Crime v. Women"
la var jmale_wc "Male judge * Crime v. Women"
la var dmale_wc "Male defendant * Crime v. Women"
la var women_crime "IPC is Crimes Against Women"

/**********************/
/* Outcome: Acquitted */
/**********************/
global gender_vars judge_male def_male 
global religion_vars judge_muslim def_muslim 

/* we want the bias columns stored in the same variable */
gen bias = judge_def_male

/* label bias coefficients for just this table */
label var bias "Ingroup Bias"
label var jdmale_mis "Ingroup Bias * Victim Gender Mismatch"
label var jdmus_mis "Ingroup Bias * Victim Religion Mismatch"
label var jdmale_wc "Ingroup Bias * Crime Against Women"

save $tmp/victim_tmp, replace

/* store timestamp */
set_log_time

/* 1. gender victim interaction */
reghdfe acquitted bias $gender_vars jdmale_mis jmale_mis dmale_mis gender_mismatch , absorb(loc_month judge acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Gender"
estadd local sample "All"
estimates store m1 

/* store sample & main coef from regression 1 in locals*/
count if e(sample) == 1
local gmis_n = `r(N)'
local gmis: di _b["jdmale_mis"]

/* store sample & main bias effect from reg 1 in paper stats csv */
store_validation_data `gmis_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch gender bias: sample") group("victim mismatch")
store_validation_data `gmis' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch gender bias: coef") group("victim mismatch")  

/* calculate effect on group most likely to see bias */
lincom bias + jdmale_mis

/* 2. religion victim interaction */
/* replace bias with muslim bias variable so it takes same row in the estout table */
replace bias = judge_def_muslim
reghdfe acquitted bias $religion_vars jdmus_mis jmus_mis dmus_mis religion_mismatch , absorb(loc_month judge acts  ) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Religion"
estadd local sample "All"
estimates store m2

/* store sample & main coef from regression 2 in locals*/
count if e(sample) == 1
local rmis_n = `r(N)'
local rmis: di _b["jdmus_mis"]

/* store sample & main bias effect from reg 2 in paper stats csv */
store_validation_data `rmis_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch religion bias: sample") group("victim mismatch")
store_validation_data `rmis' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch religion bias: coef") group("victim mismatch")  

/* calculate effect on group most likely to see bias */
lincom bias + jdmus_mis

/* 3. crimes against women interaction */
/* replace bias with gender bias variable */
replace bias = judge_def_male
reghdfe acquitted bias $gender_vars jdmale_wc jmale_wc dmale_wc women_crime , absorb(loc_month judge acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Gender"
estadd local sample "All"
estimates store m3

/* store sample & main coef from regression 3 in locals*/
count if e(sample) == 1
local wc_n = `r(N)'
local wc: di _b["jdmale_wc"]

/* store sample & main bias effect from reg 3 in paper stats csv */
store_validation_data `wc_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch crimes agnst women: sample") group("victim mismatch")
store_validation_data `wc' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch crimes agnst women: coef") group("victim mismatch")  

/* calculate effect on group most likely to see bias */
lincom bias + jdmale_wc

esttab m1 m2 m3 using $out/victim_inter.tex, replace se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "judge Judge Fixed Effect" "bias Bias" "sample Sample") keep(bias jdmale_mis jdmus_mis jdmale_wc) b(3)  

cap log close



og close




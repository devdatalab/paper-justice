/*********************************************************************************************************/
/* This dofile estimates in-group bias separately for sexual assault cases vs other crimes against women */
/*********************************************************************************************************/

/* open analysis dataset */
use $jdata/justice_analysis, clear

/* create crimes against women interactions, similarly to Table 5 col(3) */
gen jdmale_wc = judge_def_male * women_crime
gen jmale_wc = judge_male * women_crime
gen dmale_wc = def_male * women_crime

/* create interactions for sexual assault cases */
gen jdmale_wsa = judge_def_male * sexual_assault
gen jmale_wsa = judge_male * sexual_assault
gen dmale_wsa = def_male * sexual_assault

/* label variables */
la var judge_male "Male judge"
la var def_male "Male defendant"
la var acq "Acquitted"
la var jdmale_wc "Male judge and defendant * Crime Against Women"
la var jmale_wc "Male judge * Crime Against Women"
la var dmale_wc "Male defendant * Crime Against Women"
la var jdmale_wsa "Male judge and defendant * Sexual Assault Against Women"
la var jmale_wsa "Male judge * Sexual Assault Against Women"
la var dmale_wsa "Male defendant * Sexual Assault Against Women"

/**********************/
/* Outcome: Acquitted */
/**********************/

/* store gender vars in global  */
global gender_vars judge_male def_male 

/* we want the bias columns stored in the same variable */
gen bias = judge_def_male

/* label bias coefficients for this table */
label var bias "Ingroup Bias"
label var jdmale_wc "Ingroup Bias * Other Crimes Against Women"
label var jdmale_wsa "Ingroup Bias * Sexual Assault Against Women"

save $tmp/women_victim_tmp, replace

/**********************************/
/* Regressions take ~ 2 h to run! */
/**********************************/

/* store timestamp */
set_log_time

/* estimate bias interaction for crimes against women category */
/* replace bias with gender bias variable */
replace bias = judge_def_male
reghdfe acquitted bias $gender_vars jdmale_wc jmale_wc dmale_wc women_crime, absorb(loc_month judge acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Gender"
estadd local sample "All"
estimates store m30

/* store sample & main coef from first regression in locals*/
count if e(sample) == 1
local wc_n = `r(N)'
local wc: di _b["jdmale_wc"]

/* store sample & main bias effect in paper stats csv */
store_validation_data `wc_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch crimes agnst women: sample") group("victim mismatch")
store_validation_data `wc' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch crimes agnst women: coef") group("victim mismatch")  

/* calculate effect on group most likely to see bias */
lincom bias + jdmale_wc

/* estimate bias interaction for sexual assault category */
/* replace bias with gender bias variable */
replace bias = judge_def_male
reghdfe acquitted bias $gender_vars jdmale_wsa jmale_wsa dmale_wsa sexual_assault, absorb(loc_month judge acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Gender"
estadd local sample "All"
estimates store m31

/* store sample & main coef from second regression in locals*/
count if e(sample) == 1
local wsa_n = `r(N)'
local wsa: di _b["jdmale_wsa"]

/* store sample & main bias effect in paper stats csv */
store_validation_data `wsa_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch sexual assault against women: sample") group("victim mismatch")
store_validation_data `wsa' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Victim mismatch sexual assault against women: coef") group("victim mismatch")  

/* calculate effect on group most likely to see bias */
lincom bias + jdmale_wsa

/* produce appendix table */
esttab m30 m31 using $out/crimes_against_women.tex, replace se(4) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "judge Judge Fixed Effect" "bias Bias" "sample Sample") keep(bias jdmale_wc jdmale_wsa) b(4)

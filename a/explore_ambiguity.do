/* load justice analysis dataset */
use $jdata/justice_analysis, clear

/* calculate the ambiguity rate in every court */
group state district court
bys sdcgroup: egen amb_court = mean(amb)

/* calculate the ambiguity rate in every charge */
bys acts: egen amb_charge = mean(ambiguous)

/* label variables for table */
la var acquitted "Acquitted"
la var judge_def_male "In-group gender bias"
la var judge_def_nonmuslim "In-group religious bias"

/*********************************************************/
/* explore the distribution of ambiguity rates by charge */
/*********************************************************/
egen acttag = tag(acts)
sum amb_charge if acttag, d
hist amb_charge if acttag, xline(`r(p50)', lc(red)) xline(`r(p75)', lc(blue)) xline(`r(p25)', lc(blue)) ///
    note("The dashed lines show the 25th, 50th and 75th percentile") ///
    xtitle("Ambiguity rate at the court level")
graphout amb_charge

/* explore the distribution of court ambiguity */
egen courttag = tag(state district court)
sum amb_court if courttag, d
hist amb_court if courttag, xline(`r(p50)', lc(red)) xline(`r(p75)', lc(blue)) xline(`r(p25)', lc(blue)) ///
    note("The dashed lines show the 25th, 50th and 75th percentile") ///
    xtitle("Ambiguity rate at the court level")
graphout amb_court

/******************************************************************/
/* repeat main analysis, but in places with lower ambiguity rates */
/******************************************************************/

/* shrink the dataset to accelerate things a bit */
save $tmp/jtmp, replace

use $tmp/jtmp, clear
keep ddl_case_id acq def_female def_muslim amb_charge amb_court loc_month acts judge acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men
save $tmp/jtmp_thin, replace

/* store median charge ambiguity and course ambiguity, by case */
sum amb_charge, d
local median_charge = `r(p50)'
sum amb_court, d
local median_court = `r(p50)'

/* focus on judge fixed effect analyses */
eststo clear

/* 1. gender -- below-median ambiguity courts */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm if amb_charge < `median_charge', absorb(loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estimates store m1

/* 2. gender -- below-median ambiguity charges */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm if amb_court < `median_court', absorb(loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estimates store m2

/* 3-4. religion -- below-median ambiguity courts and charges */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men if amb_charge < `median_charge', absorb(loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estimates store m3

reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men if amb_court < `median_court', absorb(loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estimates store m4

/* caste regressions --- get fields we need from the caste dataset */
merge 1:1 ddl_case_id using $jdata/justice_same_names, keepusing(same_last_name dgroup jgroup wt same_rare_wt)
keep if _merge == 3
drop _merge
save $tmp/jtmp_lastname, replace

la var same_last_name "In-group caste bias"

/* 5-6. caste */
reghdfe acq same_last_name def_female def_muslim if amb_charge < `median_charge', absorb(dgroup jgroup loc_month acts judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local wt "No"
estadd local namefe "Yes"
estimates store m5

reghdfe acq same_last_name def_female def_muslim if amb_court < `median_court', absorb(dgroup jgroup loc_month acts judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local wt "No"
estadd local namefe "Yes"
estimates store m6

esttab m1 m2 m3 m4 m5 m6 using $out/low_ambiguity_rcts.tex, replace se(3) label star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("FE Fixed Effect" "judge Judge Fixed Effect" "namefe Last Name Fixed Effect") ///
    keep(judge_def_male judge_def_nonmuslim same_last_name) b(3)  ///

exit
exit
exit

//estout_default using $tmp/low_ambiguity_rcts.html, order(judge_def_male judge_def_nonmuslim same_last_name)

/* out ofcuriosity, do we get the same positive result for the weighted last name regressions? */
reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt] if amb_charge < `median_charge', absorb(dgroup jgroup loc_month acts)
reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt] if amb_charge < `median_court', absorb(dgroup jgroup loc_month acts)


reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt] if amb_charge < .77, absorb(dgroup loc_month acts)
reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt] if amb_charge > .77 & !mi(amb_charge), absorb(dgroup loc_month acts)

reghdfe acq same_last_name same_rare_wt def_female def_muslim [pw=wt] , absorb(dgroup loc_month acts)




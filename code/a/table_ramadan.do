cap log close
log using $tmp/ramadan_analysis.log, text replace

/* import analysis dataset */
use $jdata/justice_analysis, clear

/* drop all judge vars, since we want the judge on the decision date, not filing date */
drop judge*
drop ddl_judge_id

/* get decision judge info */
ren ddl_decision_judge_id ddl_judge_id
merge m:1 ddl_judge_id using $jdata/judges_clean, keep(match) nogen keepusing(muslim_class female_class)

/* create standard classification variables */
ren muslim_class judge_muslim
ren female_class judge_female
gen judge_male = 1 - judge_female
gen judge_nonmuslim = 1 - judge_muslim

gen judge_def_male = judge_male * def_male
gen judge_def_muslim = judge_muslim * def_muslim
gen judge_def_nonmuslim = judge_nonmuslim * def_nonmuslim
egen judge = group(ddl_judge_id)

/* manually set ramadan dates */
gen ramadan = 0
replace ramadan = 1 if year == 2010 & (month(decision_date) == 08 & day(decision_date) >= 10) | (month(decision_date) == 09 & day(decision_date) <= 09)
replace ramadan = 1 if year == 2011 & (month(decision_date) == 07 & day(decision_date) >= 31) | (month(decision_date) == 08 & day(decision_date) <= 30)
replace ramadan = 1 if year == 2012 & (month(decision_date) == 07 & day(decision_date) >= 19) | (month(decision_date) == 08 & day(decision_date) <= 18)
replace ramadan = 1 if year == 2013 & (month(decision_date) == 07 & day(decision_date) >= 08) | (month(decision_date) == 08 & day(decision_date) <= 07)
replace ramadan = 1 if year == 2014 & (month(decision_date) == 06 & day(decision_date) >= 28) | (month(decision_date) == 07 & day(decision_date) <= 28)
replace ramadan = 1 if year == 2015 & (month(decision_date) == 06 & day(decision_date) >= 17) | (month(decision_date) == 07 & day(decision_date) <= 17)
replace ramadan = 1 if year == 2016 & (month(decision_date) == 06 & day(decision_date) >= 06) | (month(decision_date) == 07 & day(decision_date) <= 05)
replace ramadan = 1 if year == 2017 & (month(decision_date) == 05 & day(decision_date) >= 26) | (month(decision_date) == 06 & day(decision_date) <= 24)
replace ramadan = 1 if year == 2018 & (month(decision_date) == 05 & day(decision_date) >= 15) | (month(decision_date) == 06 & day(decision_date) <= 14)

/* drop judges with missing religion info */
drop if judge_muslim == 9999 | def_muslim == 9999 | judge_nonmuslim == 9999
drop if mi(judge_muslim)

/* create interactions between ramadan and X variables */
gen j_nm_r = judge_nonmuslim * ramadan
gen d_nm_r = def_nonmuslim * ramadan
gen jd_nm_r = judge_def_nonmuslim * ramadan

/* label variabels */
la var judge_nonmuslim "Non-muslim judge"
la var def_nonmuslim "Non-muslim defendant"
la var judge_def_nonmuslim "Own religion bias"
la var ramadan "Ramadan"
la var j_nm_r "Non-muslim judge * Ramadan"
la var d_nm_r "Non-muslim defendant * Ramadan"
la var jd_nm_r "Own religion bias * Ramadan"

/**********************/
/* Outcome: Acquitted */
/**********************/

// /* columns 1 & 2: main religion analysis during ramadan and at other times */
// reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim if ramadan == 0 , absorb(loc_month acts) cluster(judge)
// estadd local FE "Court-month"
// estadd local judge "No"
// estadd local sample "Non-Ramadan"
// estimates store m1
// 
// reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim if ramadan == 1 , absorb(loc_month acts) cluster(judge)
// estadd local FE "Court-year"
// estadd local judge "No"
// estadd local sample "During Ramadan"
// estimates store m2

/* columns 3-5: interact ramadan with all vars. Month, then year FE, then year + judge */
reghdfe acquitted judge_nonmuslim def_nonmuslim  ramadan judge_def_nonmuslim j_nm_r d_nm_r jd_nm_r , absorb(loc_month acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "No"
estadd local sample "Full sample"
estimates store m3

/* log timestamp */
set_log_time

/* store sample from regression above in a local */
count if e(sample) == 1
local ram_cm_n = `r(N)'

/* store ramadan bias effect (court-month FE) in a local */
local ram_cm: di _b["jd_nm_r"]

/* write stored statistics in the paper stats csv */
store_paper_stat `ram_cm_n' using $out/justice_paper_stats.csv, description("Ramandan analysis court-month: sample") group("ramadan")
store_paper_stat `ram_cm' using $out/justice_paper_stats.csv, description("Ramandan analysis court-month: coef") group("ramadan")  

/* add up ramadan interaction and base bias to get bias during ramadan */
lincom judge_def_nonmuslim + jd_nm_r

/* column 4: court-month, judge FE */
reghdfe acquitted judge_nonmuslim def_nonmuslim ramadan judge_def_nonmuslim j_nm_r d_nm_r jd_nm_r , absorb(judge loc_month) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local sample "Full sample"
estimates store m4

/* add up ramadan interaction and base bias to get bias during ramadan */
lincom judge_def_nonmuslim + jd_nm_r

/* column 5: court-year */
reghdfe acquitted judge_nonmuslim def_nonmuslim ramadan judge_def_nonmuslim j_nm_r d_nm_r jd_nm_r , absorb(loc_year acts) cluster(judge)
estadd local FE "Court-year"
estadd local judge "No"
estadd local sample "Full sample"
estimates store m5

/* store sample from regression above in a local */
count if e(sample) == 1
local ram_cy_n = `r(N)'

/* store ramadan bias effect (court-year FE) in a local */
local ram_cy: di _b["jd_nm_r"]

/* write stored statistics in the paper stats csv */
store_paper_stat `ram_cy_n' using $out/justice_paper_stats.csv, description("Ramandan analysis court-year: sample") group("ramadan")
store_paper_stat `ram_cy' using $out/justice_paper_stats.csv, description("Ramandan analysis court-year: coef") group("ramadan")  

/* add up ramadan interaction and base bias to get bias during ramadan */
lincom judge_def_nonmuslim + jd_nm_r

/* column 6: court-year, judge FE */
reghdfe acquitted judge_nonmuslim def_nonmuslim ramadan judge_def_nonmuslim j_nm_r d_nm_r jd_nm_r , absorb(loc_year judge) cluster(judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estadd local sample "Full sample"
estimates store m6

/* add up ramadan interaction and base bias to get bias during ramadan */
lincom judge_def_nonmuslim + jd_nm_r

/* output panel  */
esttab m3 m4 m5 m6 using "$out/ramadan_acq.tex", replace se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "judge Judge fixed effect" "sample Sample") drop(_cons j_nm_r d_nm_r) b(3) noomitted

cap log close


/* import analysis dataset */
use $jdata/justice_analysis, clear

/**********************************************/
/* Store some basic statistics for validation */
/**********************************************/

/* store time stamp */
set_log_time

/* run main regression to tag sample */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
gen sample = e(sample) == 1

/* store sample count in stats csv */
count if sample == 1
local sample: di %5.3f `r(N)'
store_paper_stat `sample' using $out/justice_paper_stats.csv, description("Sample: Total obs in analysis dataset") group("descriptive")

/* store summary statistic in stats csv: avg acquittal rate */
sum acq if sample == 1
local acq_mean: di %5.3f `r(mean)'
store_paper_stat `acq_mean' using $out/justice_paper_stats.csv, description("Mean acquittal rate in analysis sample") group("descriptive")

/* store summary statistic in stats csv: avg conviction rate */
/* note that we have non-conviction as outcome variable */
/* conviction is the exact opposite (1-non-conviction) */
gen conv = 1 - non_conv
sum conv if sample == 1
local conv_mean: di %5.3f `r(mean)'
drop conv
store_paper_stat `conv_mean' using $out/justice_paper_stats.csv, description("Mean conviction rate in analysis sample") group("descriptive")

/* tag number of obs for which we have classified gender */
count if !mi(def_female)
local g_sample: di %5.3f `r(N)'

/* tag number of obs for which we have classified religion */
count if !mi(def_muslim)
local r_sample: di %5.3f `r(N)'

/* store defendant gender and religious shares in locals */
count if def_muslim == 1
local share_def_mus: di %5.3f `r(N)'/`r_sample'
count if def_muslim == 0
local share_def_nm: di %5.3f `r(N)'/`r_sample'
count if def_female == 1
local share_def_fem: di %5.3f `r(N)'/`g_sample'
count if def_female == 0
local share_def_mal: di %5.3f `r(N)'/`g_sample'

/* store defendant demographic shares in paper stats csv */
store_paper_stat `share_def_mus' using $out/justice_paper_stats.csv, description("Defendant share: Muslim") group("descriptive")
store_paper_stat `share_def_nm' using $out/justice_paper_stats.csv, description("Defendant share: non-Muslim") group("descriptive")
store_paper_stat `share_def_fem' using $out/justice_paper_stats.csv, description("Defendant share: female") group("descriptive")
store_paper_stat `share_def_mal' using $out/justice_paper_stats.csv, description("Defendant share: male") group("descriptive")

/**********************/
/* Outcome: Acquitted */
/**********************/

/* column 1 */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
store_gender, name("col1") outcome("acquitted") label("Acquittal rate")

/* column 2 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
store_gender, name("col2") outcome("acquitted") label("Acquittal rate")

/* column 3 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
store_gender, name("col3") outcome("acquitted") label("Acquittal rate")

/* store analysis sample count in local */
count if e(sample) == 1
local gb_cm_n = `r(N)'

/* store gender bias effect from column 3 in local */
local gb_cm: di _b["judge_def_male"]
store_paper_stat `gb_cm' using $out/justice_paper_stats.csv, description("Gender bias acquittal - court-month: coef") group("main bias results")  

/* store sample from column 3 in local */
store_paper_stat `gb_cm_n' using $out/justice_paper_stats.csv, description("Gender bias acquittal - court-month: sample") group("main bias results")  

/* column 4 */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("acquitted") label("Acquittal rate")

/* column 5 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("acquitted") label("Acquittal rate")

/* column 6 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("acquitted") label("Acquittal rate")

/* store analysis sample count in local */
count if e(sample) == 1
local gb_cy_n = `r(N)'

/* store bias effect from column 6 in local */
local gb_cy: di _b["judge_def_male"]
store_paper_stat `gb_cy' using $out/justice_paper_stats.csv, description("Gender bias acquittal - court-year: coef") group("main bias results")  

/* store sample from column 6 in local */
store_paper_stat `gb_cy_n' using $out/justice_paper_stats.csv, description("Gender bias acquittal - court-year: sample") group("main bias results")  

/* write regression table */
table_from_tpl, t($out/g_template.tex) r($tmp/gender_acquitted.csv) o($out/gender_acquitted.tex)

/*************************/
/* Outcome: Any decision */
/*************************/

/* column 1 */
reghdfe decision judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
store_gender, name("col1") outcome("decision") label("Decision within six months of filing")

/* column 2 */
reghdfe decision judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
store_gender, name("col2") outcome("decision") label("Decision within six months of filing")

/* column 3 */
reghdfe decision judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
store_gender, name("col3") outcome("decision") label("Decision within six months of filing")

/* store sample from column 3 in local */
count if e(sample) == 1
local gb_cm_n = `r(N)'

/* store bias effect for stats csv*/
local gb_cm: di _b["judge_def_male"]
store_paper_stat `gb_cm' using $out/justice_paper_stats.csv, description("Gender bias decision - court-month: coef") group("main bias results")  

/* store sample for stats csv */
store_paper_stat `gb_cm_n' using $out/justice_paper_stats.csv, description("Gender bias decision - court-month: sample") group("main bias results")  

/* column 4 */
reghdfe decision judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("decision") label("Decision within six months of filing")

/* column 5 */
reghdfe decision judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("decision") label("Decision within six months of filing")

/* column 6 */
reghdfe decision judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("decision") label("Decision within six months of filing")

/* store sample from column 6 in a local */
count if e(sample) == 1
local gb_cy_n = `r(N)'

/* store bias effect from column 6 in local*/
local gb_cy: di _b["judge_def_male"]

/* write bias effect from column 6 in stats csv */
store_paper_stat `gb_cy' using $out/justice_paper_stats.csv, description("Gender bias decision - court-year: coef") group("main bias results")  

/* write sample from column 6 in stats csv */
store_paper_stat `gb_cy_n' using $out/justice_paper_stats.csv, description("Gender bias decision - court-year: sample") group("main bias results")  

/* write regression table */
table_from_tpl, t($out/g_template.tex) r($tmp/gender_decision.csv) o($out/gender_decision.tex)

/**************************/
/* Outcome: Not convicted */
/**************************/

/* column 1 */
reghdfe non_convicted judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
store_gender, name("col1") outcome("non_convicted") label("Not convicted")

/* column 2 */
reghdfe non_convicted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
store_gender, name("col2") outcome("non_convicted") label("Not convicted")

/* column 3 */
reghdfe non_convicted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
store_gender, name("col3") outcome("non_convicted") label("Not convicted")

/* column 4 */
reghdfe non_convicted judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("non_convicted") label("Not convicted")

/* column 5 */
reghdfe non_convicted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("non_convicted") label("Not convicted")

/* column 6 */
reghdfe non_convicted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("non_convicted") label("Not convicted")

table_from_tpl, t($out/g_template.tex) r($tmp/gender_non_convicted.csv) o($out/gender_non_convicted.tex)

/***************************/
/* Drop ambiguous outcomes */
/***************************/

drop if ambiguous == 1

/* Outcome: Acquitted */

/* column 1 */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
store_gender, name("col1") outcome("acquitted") label("Acquittal rate")

/* column 2 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
store_gender, name("col2") outcome("acquitted") label("Acquittal rate")

/* column 3 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
store_gender, name("col3") outcome("acquitted") label("Acquittal rate")

/* column 4 */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("acquitted") label("Acquittal rate")

/* column 5 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("acquitted") label("Acquittal rate")

/* column 6 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("acquitted") label("Acquittal rate")

table_from_tpl, t($out/g_template.tex) r($tmp/gender_acquitted.csv) o($out/gender_acquitted_amb.tex)

/*****************************/
/* Keep only years 2014-2018 */
/*****************************/

use $jdata/justice_analysis, clear

keep if year >= 2014

/* Outcome: Acquitted */

/* column 1 */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
store_gender, name("col1") outcome("acquitted") label("Acquittal rate")

/* column 2 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
store_gender, name("col2") outcome("acquitted") label("Acquittal rate")

/* column 3 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
store_gender, name("col3") outcome("acquitted") label("Acquittal rate")

/* column 4 */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("acquitted") label("Acquittal rate")

/* column 5 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("acquitted") label("Acquittal rate")

/* column 6 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("acquitted") label("Acquittal rate")

table_from_tpl, t($out/g_template.tex) r($tmp/gender_acquitted.csv) o($out/gender_acquitted_high_match.tex)





 /* import analysis dataset */
use $jdata/justice_analysis, clear

/**********************/
/* Outcome: Acquitted */
/**********************/

/* store timestamp */
set_log_time

/* column 1 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
store_religion, name("col1") outcome("acquitted") label("Acquittal rate")

/* column 2 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
store_religion, name("col2") outcome("acquitted") label("Acquittal rate")

/* column 3 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
store_religion, name("col3") outcome("acquitted") label("Acquittal rate")

/* store sample from column 3 in local */
count if e(sample) == 1
local rb_cm_n = `r(N)'

/* store bias effect from column 3 in local*/
local rb_cm: di _b["judge_def_nonmuslim"]
store_validation_data `rb_cm' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Religion bias acquittal - court-month: coef") group("main bias results")  

/* store sample */
store_validation_data `rb_cm_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Religion bias acquittal - court-month: sample") group("main bias results")  

/* column 4 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_year acts) cluster(judge)
store_religion, name("col4") outcome("acquitted") label("Acquittal rate")

/* column 5 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts) cluster(judge)
store_religion, name("col5") outcome("acquitted") label("Acquittal rate")

/* column 6 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
store_religion, name("col6") outcome("acquitted") label("Acquittal rate")

/* store sample from column 6 in local */
count if e(sample) == 1
local rb_cy_n = `r(N)'

/* store bias effect from column 6 in local*/
local rb_cy: di _b["judge_def_nonmuslim"]

/* write bias effect from column 6 in stats csv */
store_validation_data `rb_cy' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Religion bias acquittal - court-year: coef") group("main bias results")  

/* store sample from column 6 in stats csv */
store_validation_data `rb_cy_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Religion bias acquittal - court-year: sample") group("main bias results")  

/* write regression table */
table_from_tpl, t($jcode/a/tpl/r_tpl.tex) r($tmp/religion_acquitted.csv) o($out/religion_acquitted.tex)

/*************************/
/* Outcome: Any decision */
/*************************/

/* column 1 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
store_religion, name("col1") outcome("decision") label("Decision within six months of filing")

/* column 2 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
store_religion, name("col2") outcome("decision") label("Decision within six months of filing")

/* column 3 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
store_religion, name("col3") outcome("decision") label("Decision within six months of filing")

/* store sample from column 3 in local */
count if e(sample) == 1
local rb_cm_n = `r(N)'

/* store bias effect from column 3 in local*/
local rb_cm: di _b["judge_def_nonmuslim"]

/* write sample from col 3 in stats csv */
store_validation_data `rb_cm' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Religion bias decision - court-month: coef") group("main bias results")  

/* write sample from col 3 in stats csv */
store_validation_data `rb_cm_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Religion bias decision - court-month: sample") group("main bias results")  

/* column 4 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_year acts) cluster(judge)
store_religion, name("col4") outcome("decision") label("Decision within six months of filing")

/* column 5 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts) cluster(judge)
store_religion, name("col5") outcome("decision") label("Decision within six months of filing")

/* column 6 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
store_religion, name("col6") outcome("decision") label("Decision within six months of filing")

/* store sample from col 6 in local */
count if e(sample) == 1
local rb_cy_n = `r(N)'

/* store bias effect from col 6 in local */
local rb_cy: di _b["judge_def_nonmuslim"]

/* write bias coef from col 6 in stats csv */
store_validation_data `rb_cy' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Religion bias decision - court-year: coef") group("main bias results")  

/* store sample from col 6 in stats csv */
store_validation_data `rb_cy_n' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Religion bias decision - court-year: sample") group("main bias results")  

/* write regression table */
table_from_tpl, t($jcode/a/tpl/r_tpl.tex) r($tmp/religion_decision.csv) o($out/religion_decision.tex)

/**************************/
/* Outcome: Not convicted */
/**************************/

/* column 1 */
reghdfe non_convicted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
store_religion, name("col1") outcome("non_convicted") label("Not convicted")

/* column 2 */
reghdfe non_convicted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
store_religion, name("col2") outcome("non_convicted") label("Not convicted")

/* column 3 */
reghdfe non_convicted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
store_religion, name("col3") outcome("non_convicted") label("Not convicted")

/* column 4 */
reghdfe non_convicted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_year acts) cluster(judge)
store_religion, name("col4") outcome("non_convicted") label("Not convicted")

/* column 5 */
reghdfe non_convicted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts) cluster(judge)
store_religion, name("col5") outcome("non_convicted") label("Not convicted")

/* column 6 */
reghdfe non_convicted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
store_religion, name("col6") outcome("non_convicted") label("Not convicted")

table_from_tpl, t($jcode/a/tpl/r_tpl.tex) r($tmp/religion_non_convicted.csv) o($out/religion_non_convicted.tex)

/* Outcome: Acquitted */
drop if ambiguous == 1

/* column 1 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
store_religion, name("col1") outcome("acquitted") label("Acquittal rate")

/* column 2 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
store_religion, name("col2") outcome("acquitted") label("Acquittal rate")

/* column 3 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
store_religion, name("col3") outcome("acquitted") label("Acquittal rate")

/* column 4 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_year acts) cluster(judge)
store_religion, name("col4") outcome("acquitted") label("Acquittal rate")

/* column 5 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts) cluster(judge)
store_religion, name("col5") outcome("acquitted") label("Acquittal rate")

/* column 6 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
store_religion, name("col6") outcome("acquitted") label("Acquittal rate")

table_from_tpl, t($jcode/a/tpl/r_tpl.tex) r($tmp/religion_acquitted.csv) o($out/religion_acquitted_amb.tex)

/***************************/
/* Run for years 2014-2018 */
/***************************/

use $jdata/justice_analysis, clear

keep if year >= 2014

/* column 1 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
store_religion, name("col1") outcome("acquitted") label("Acquittal rate")

/* column 2 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
store_religion, name("col2") outcome("acquitted") label("Acquittal rate")

/* column 3 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
store_religion, name("col3") outcome("acquitted") label("Acquittal rate")

/* column 4 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_year acts) cluster(judge)
store_religion, name("col4") outcome("acquitted") label("Acquittal rate")

/* column 5 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts) cluster(judge)
store_religion, name("col5") outcome("acquitted") label("Acquittal rate")

/* column 6 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
store_religion, name("col6") outcome("acquitted") label("Acquittal rate")

table_from_tpl, t($jcode/a/tpl/r_tpl.tex) r($tmp/religion_acquitted.csv) o($out/religion_acquitted_high_match.tex)




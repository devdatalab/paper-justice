/****************************************************************************************/
/* this dofile creates tables testing bias in the presence of religious violence events */
/****************************************************************************************/

/***************************************************/
/* merge ACLED data with justice analysis dataset  */
/**************************************************/

/* open analysis data */
use $jdata/justice_analysis, clear

/* merge with riot data */
merge 1:1 ddl_case_id using $jdata/acled_religious_violence

/*************************/
/* run regressions here  */
/*************************/

/* generate and label interaction terms needed for regressions */
forvalues i = 1/4 {

  /* assume not appearing in riots dataset means no riot in the month */
  replace week_after_riot`i' = 0 if mi(week_after_riot`i')
  replace month_after_riot`i' = 0 if mi(month_after_riot`i')
  
  la var week_after_riot`i' "Week after violence type `i'"
  la var month_after_riot`i' "Month after violence type `i'"

  gen bias_wa`i' = judge_def_nonmuslim * week_after_riot`i'
  la var bias_wa`i' "Own religion bias * week after violence type `i'"

  gen bias_ma`i' = judge_def_nonmuslim * month_after_riot`i'
  la var bias_ma`i' "Own religion bias * month after violence type `i'"

  gen j_nm_wa`i' = judge_nonmuslim * week_after_riot`i'
  la var j_nm_wa`i' "Non-Muslim judge * week after violence type `i'"

  gen j_nm_ma`i' = judge_nonmuslim * month_after_riot`i'
  la var j_nm_ma`i' "Non-Muslim judge * month after violence type `i'"

  gen def_nm_wa`i' = def_nonmuslim * week_after_riot`i'
  la var def_nm_wa`i' "Non-Muslim defendant* week after violence type `i'"

  gen def_nm_ma`i' = def_nonmuslim * month_after_riot`i'
  la var def_nm_ma`i' "Non-Muslim defendant * month after violence type `i'"
}

/* keep only districts where there was at least one event ever */
forval i = 1/4 {
  bys state district: egen sample`i' = max(month_after_riot`i')
}  

/* drop years where we don't have ACLED data */
keep if inrange(year, 2016, 2018)
//save $tmp/justice_riots, replace
save $jdata/justice_riots, replace

/* WEEK AFTER court-month FE */

/* Religion main spec: table 3 column 1 religious_riot1 */
reghdfe acquitted judge_nonmuslim def_nonmuslim week_after_riot1 judge_def_nonmuslim j_nm_wa1 def_nm_wa1 bias_wa1 if sample1 == 1, absorb(loc_month acts) cluster(judge)
eststo w1
estadd local FE "court-month"

/* Religion main spec: table 3 column 2 religious_riot2 */
reghdfe acquitted judge_nonmuslim def_nonmuslim week_after_riot2 judge_def_nonmuslim j_nm_wa2 def_nm_wa2 bias_wa2 if sample2 == 1, absorb(loc_month acts) cluster(judge)
eststo w2
estadd local FE "court-month"

/* Religion main spec: table 3 column 3 religious_riot3 */
reghdfe acquitted judge_nonmuslim def_nonmuslim week_after_riot3 judge_def_nonmuslim j_nm_wa3 def_nm_wa3 bias_wa3 if sample3 == 1, absorb(loc_month acts) cluster(judge)
eststo w3
estadd local FE "court-month"

/* Religion main spec: table 3 column 4 religious_riot4 */
reghdfe acquitted judge_nonmuslim def_nonmuslim week_after_riot4 judge_def_nonmuslim j_nm_wa4 def_nm_wa4 bias_wa4 if sample4 == 1, absorb(loc_month acts) cluster(judge)
eststo w4
estadd local FE "court-month"

esttab w1 w2 w3 w4 using "$out/week_after_riots.tex", replace label b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) s(FE N, label("Fixed Effect" "Observations") fmt(0 0) ) drop(_cons) mtitles("Acquitted" "Acquitted" "Acquitted" "Acquitted") booktabs 

/* MONTH AFTER court-month FE */

/* Religion main spec: table 3 column 1 religious_riot1 */
reghdfe acquitted judge_nonmuslim def_nonmuslim month_after_riot1 judge_def_nonmuslim j_nm_ma1 def_nm_ma1 bias_ma1 if sample1 == 1, absorb(loc_month acts) cluster(judge)
eststo m1
estadd local FE "court-month"

/* Religion main spec: table 3 column 2 religious_riot2 */
reghdfe acquitted judge_nonmuslim def_nonmuslim month_after_riot2 judge_def_nonmuslim j_nm_ma2 def_nm_ma2 bias_ma2 if sample2 == 1, absorb(loc_month acts) cluster(judge)
eststo m2
estadd local FE "court-month"

/* Religion main spec: table 3 column 3 religious_riot3 */
reghdfe acquitted judge_nonmuslim def_nonmuslim month_after_riot3 judge_def_nonmuslim j_nm_ma3 def_nm_ma3 bias_ma3 if sample3 == 1, absorb(loc_month acts) cluster(judge)
eststo m3
estadd local FE "court-month"

/* Religion main spec: table 3 column 4 religious_riot4 */
reghdfe acquitted judge_nonmuslim def_nonmuslim month_after_riot4 judge_def_nonmuslim j_nm_ma4 def_nm_ma4 bias_ma4 if sample4 == 1, absorb(loc_month acts) cluster(judge)
eststo m4
estadd local FE "court-month"

/* generate the referee table */
esttab m1 m2 m3 m4 using "$out/month_after_riots.tex", replace label b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) s(FE N, label("Fixed Effect" "Observations") fmt(0 0) ) drop(_cons) mtitles("Acquitted" "Acquitted" "Acquitted" "Acquitted") booktabs 





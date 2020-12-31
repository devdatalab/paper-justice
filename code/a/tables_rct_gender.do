/* PROGRAM TO STORE RESULTS FROM REGRESSIONS FOR STATA-TEX */
cap prog drop store_gender
prog def store_gender

  /* syntax */
  syntax, name(string) outcome(string) label(string)
  local o = "`outcome'"
  local col = "`name'"
  local lab = "`label'"
  
  /* store N */
  local obs `e(N)'

  /* store control mean */
  sum `o' if def_male == 0 & judge_male == 0 & e(sample) == 1
  local cont: di %9.3f `r(mean)'
  local cont_est "`cont'"     

  /* store effect of male judge on female defendant */
  local jfm: di %9.3f _b["judge_male"]
  local se: di %9.3f _se["judge_male"]
  local jfmse: di %9.3f _se["judge_male"]
  test judge_male = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local jfm_est "`jfm'`r(stars)'"
  local jfm_ci: di %5.2f invttail(e(df_r),0.025)*_se["judge_male"]
  
  /* store effect of male judge on male defendant */
  local jff: di %9.3f (_b["judge_male"] + _b["judge_def_male"])
  lincom judge_male + judge_def_male 
  local se: di %9.3f `r(se)'
  local jffse: di %9.3f `r(se)'
  test judge_male + judge_def_male = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local jff_est "`jff'`r(stars)'"
  lincom judge_male + judge_def_male
  local jff_ci: di %5.2f invttail(e(df_r),0.025)*(_se["judge_male"] + _se["judge_def_male"])
  
  /* store marginal effect of male judge on male defendant */
  local int: di %9.3f (_b["judge_def_male"])
  local se: di %9.3f _se["judge_def_male"]
  local intse: di %9.3f _se["judge_def_male"]
  test judge_def_male = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local int_est "`int'`r(stars)'"
  local int_ci: di %5.2f invttail(e(df_r),0.025)*_se["judge_def_male"]

  /* display results */
  di  %20s "`jfm_est'" %20s "`jff_est'" %25s "`int_est'" %15s "`col'"
  
  local demo "Male"
  local nondemo "Female"
  local identity "gender"
  
  /* store results into csv */
  insert_into_file using $tmp/gender_`o'.csv, key(o) value("`o'") 
  insert_into_file using $tmp/gender_`o'.csv, key(label) value("`lab'") 
  insert_into_file using $tmp/gender_`o'.csv, key(demo) value("`demo'") 
  insert_into_file using $tmp/gender_`o'.csv, key(nondemo) value("`nondemo'") 
  insert_into_file using $tmp/gender_`o'.csv, key(jfm_`col') value("`jfm_est'") format(%025s)
  insert_into_file using $tmp/gender_`o'.csv, key(jff_`col') value("`jff_est'") format(%025s)
  insert_into_file using $tmp/gender_`o'.csv, key(cmint_`col') value("`int_est'") format(%025s)
  insert_into_file using $tmp/gender_`o'.csv, key(sefjm_`col') value("`jfmse'") format(%025s)
  insert_into_file using $tmp/gender_`o'.csv, key(sefjf_`col') value("`jffse'") format(%025s)
  insert_into_file using $tmp/gender_`o'.csv, key(seint_`col') value("`intse'") format(%025s)
  insert_into_file using $tmp/gender_`o'.csv, key(cons_`col') value("`cont_est'") format(%25s)
  insert_into_file using $tmp/gender_`o'.csv, key(N_`col') value("`obs'") format(%25s)
  insert_into_file using $tmp/gender_`o'.csv, key(id) value("`identity'") format(%25s)

end

/**********************************END PROGRAM STORE_GENDER*******************************/

/* import analysis dataset */
use $jdata/justice_analysis, clear

/* generate judge male defendant muslim interaction */
gen judge_men_def_nm = judge_male * def_nonmuslim

/* label variable */
la var judge_men_def_nm "Male judge with non-Muslim defendant"

/* drop bail obs */
drop if bail == 1

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

/* column 4 */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("acquitted") label("Acquittal rate")

/* column 5 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("acquitted") label("Acquittal rate")

/* column 6 */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("acquitted") label("Acquittal rate")

table_from_tpl, t($out/g_template.tex) r($tmp/gender_acquitted.csv) o($out/gender_acquitted.tex)

/*************************/
/* Outcome: Any decision */
/*************************/

/* column 1 */
reghdfe decision judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
store_gender, name("col1") outcome("decision") label("Any decision at all")

/* column 2 */
reghdfe decision judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
store_gender, name("col2") outcome("decision") label("Any decision at all")

/* column 3 */
reghdfe decision judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
store_gender, name("col3") outcome("decision") label("Any decision at all")

/* column 4 */
reghdfe decision judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("decision") label("Any decision at all")

/* column 5 */
reghdfe decision judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("decision") label("Any decision at all")

/* column 6 */
reghdfe decision judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("decision") label("Any decision at all")

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

drop if negative == . 

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

/* PROGRAM TO STORE RESULTS FROM REGRESSIONS FOR STATA-TEX */
cap prog drop store_religion
prog def store_religion
  {
    
  /* syntax */
  syntax, name(string) outcome(string) label(string)
  local o = "`outcome'"
  local col = "`name'"
  local lab = "`label'"
  
  /* store N */
  local obs `e(N)'

  /* store control mean */
  sum `o' if def_nonmuslim == 0 & judge_nonmuslim == 0 & e(sample) == 1
  local cont: di %9.3f `r(mean)'
  local cont_est "`cont'"     

  /* store effect of nonmuslim judge on muslim defendant */
  local jfm: di %9.3f _b["judge_nonmuslim"]
  local se: di %9.3f _se["judge_nonmuslim"]
  local jfmse: di %9.3f _se["judge_nonmuslim"]
  test judge_nonmuslim = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local jfm_est "`jfm'`r(stars)'"
  local jfm_ci: di %5.2f invttail(e(df_r),0.025)*_se["judge_nonmuslim"]
  
  /* store effect of nonmuslim judge on nonmuslim defendant */
  local jff: di %9.3f (_b["judge_nonmuslim"] + _b["judge_def_nonmuslim"])
  lincom judge_nonmuslim + judge_def_nonmuslim 
  local se: di %9.3f `r(se)'
  local jffse: di %9.3f `r(se)'
  test judge_nonmuslim + judge_def_nonmuslim = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local jff_est "`jff'`r(stars)'"
  lincom judge_nonmuslim + judge_def_nonmuslim
  local jff_ci: di %5.2f invttail(e(df_r),0.025)*(_se["judge_nonmuslim"] + _se["judge_def_nonmuslim"])
  
  /* store marginal effect of nonmuslim judge on nonmuslim defendant */
  local int: di %9.3f (_b["judge_def_nonmuslim"])
  local se: di %9.3f _se["judge_def_nonmuslim"]
  local intse: di %9.3f _se["judge_def_nonmuslim"]
  test judge_def_nonmuslim = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local int_est "`int'`r(stars)'"
  local int_ci: di %5.2f invttail(e(df_r),0.025)*_se["judge_def_nonmuslim"]

  /* display results */
  di  %20s "`jfm_est'" %20s "`jff_est'" %25s "`int_est'" %15s "`col'"
  
  local demo "Non-muslim"
  local nondemo "Muslim"
  local identity "religion"
  
  /* store results into csv */
  insert_into_file using $tmp/religion_`o'.csv, key(o) value("`o'") 
  insert_into_file using $tmp/religion_`o'.csv, key(label) value("`lab'") 
  insert_into_file using $tmp/religion_`o'.csv, key(demo) value("`demo'") 
  insert_into_file using $tmp/religion_`o'.csv, key(nondemo) value("`nondemo'") 
  insert_into_file using $tmp/religion_`o'.csv, key(jfm_`col') value("`jfm_est'") format(%025s)
  insert_into_file using $tmp/religion_`o'.csv, key(jff_`col') value("`jff_est'") format(%025s)
  insert_into_file using $tmp/religion_`o'.csv, key(cmint_`col') value("`int_est'") format(%025s)
  insert_into_file using $tmp/religion_`o'.csv, key(sefjm_`col') value("`jfmse'") format(%025s)
  insert_into_file using $tmp/religion_`o'.csv, key(sefjf_`col') value("`jffse'") format(%025s)
  insert_into_file using $tmp/religion_`o'.csv, key(seint_`col') value("`intse'") format(%025s)
  insert_into_file using $tmp/religion_`o'.csv, key(cons_`col') value("`cont_est'") format(%25s)
  insert_into_file using $tmp/religion_`o'.csv, key(N_`col') value("`obs'") format(%25s)
  insert_into_file using $tmp/religion_`o'.csv, key(id) value("`identity'") format(%25s)
  }
  
end

/**********************************END PROGRAM STORE_RELIGION*******************************/

/* import analysis dataset */
use $jdata/justice_analysis, clear

/* generate judge nonmuslim defendant male interaction */
gen judge_nm_def_men = judge_nonmuslim * def_male

/* label variable */
la var judge_nm_def_men "Non-Muslim judge with male defendant"

/* drop bail obs */
drop if bail == 1

/**********************/
/* Outcome: Acquitted */
/**********************/

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

table_from_tpl, t($out/r_template.tex) r($tmp/religion_acquitted.csv) o($out/religion_acquitted.tex)

/*************************/
/* Outcome: Any decision */
/*************************/

/* column 1 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
store_religion, name("col1") outcome("decision") label("Any decision at all")

/* column 2 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
store_religion, name("col2") outcome("decision") label("Any decision at all")

/* column 3 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
store_religion, name("col3") outcome("decision") label("Any decision at all")

/* column 4 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_year acts) cluster(judge)
store_religion, name("col4") outcome("decision") label("Any decision at all")

/* column 5 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts) cluster(judge)
store_religion, name("col5") outcome("decision") label("Any decision at all")

/* column 6 */
reghdfe decision judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
store_religion, name("col6") outcome("decision") label("Any decision at all")

table_from_tpl, t($out/r_template.tex) r($tmp/religion_decision.csv) o($out/religion_decision.tex)

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

table_from_tpl, t($out/r_template.tex) r($tmp/religion_non_convicted.csv) o($out/religion_non_convicted.tex)

/* Outcome: Acquitted */
drop if negative == .

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

table_from_tpl, t($out/r_template.tex) r($tmp/religion_acquitted.csv) o($out/religion_acquitted_amb.tex)

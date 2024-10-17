/**********************************************/
/* Run the column 1 regression for each state */
/**********************************************/

/* store timestamp */
tgo //5.71 min

/* open the justice analysis dataset */
use $jdata/justice_analysis, clear

/* get the pc11 state ids so we can get state names. Note we need to rename state and state_code --- this is an error
   in the build (since state_code doesn't match the key), but it's not a big deal and costly
   to trace through and fix. */
drop state_code
ren state state_code

/* merge with casses_state_key to get pc11 state ids */
merge m:1 state_code year using $jdata/keys/cases_state_key, keepusing(pc11_state_id) keep(match master)
assert _merge == 3
drop _merge

/* get the state names for the table */
get_state_names, y(11)
replace pc11_state_name = proper(pc11_state_name)

/* drop states with less than 10k observations */
bysort state_code: egen state_total = count(state_code)
drop if state_total < 10000

/* drop states with less than X minority def*judge observations */
gen religion_sample = 1
gen gender_sample   = 1

/* loop over all values of pc11_state_name  */
levelsof pc11_state_name , local(states)
qui foreach state in `states' {
  count if pc11_state_name == "`state'" & def_muslim == 1 & judge_muslim == 1

  /* set the interaction to missing if sample is small -- don't drop, since we may
     use this state for gender. */
  replace religion_sample = 0 if `r(N)' < 200 & pc11_state_name == "`state'"

  /* repeat for gender */
  count if pc11_state_name == "`state'" & def_male == 1 & judge_male == 1
  replace gender_sample = 0 if `r(N)' < 200 & pc11_state_name == "`state'"
}

save $tmp/justice_statewise, replace



/* Run the in-group bias regression for each state */

/**********************/
/* Outcome: Acquitted */
/**********************/

/* clear the estimates file */
cap erase $tmp/statewise_religion.csv
cap erase $tmp/statewise_gender.csv

/* column 1 */

/* loop through all states */
levelsof pc11_state_name, local(states) 
local x 0
foreach i of local states {
  
  /* update the state counter */
  local x = `x' + 1

  /* check if we have enough interaction sample to run this regression */
  sum religion_sample if pc11_state_name == "`i'"
  if `r(mean)' == 0 continue
  
  /* run a regression to see if there is in group bias in each state */
  reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim if pc11_state_name == "`i'", absorb(loc_month acts) cluster(judge)
  
  /* store the coefficients */
  store_est_tpl using $tmp/statewise_religion.csv, coef(judge_nonmuslim) name(`x'_jnm) all
  store_est_tpl using $tmp/statewise_religion.csv, coef(def_nonmuslim) name(`x'_dnm) all
  store_est_tpl using $tmp/statewise_religion.csv, coef(judge_def_nonmuslim) name(`x'_jdnm) all  
  append_to_file using $tmp/statewise_religion.csv, s("state_`x', `i'")
  
}

/* output tables with around 12 states in each to tex */
table_from_tpl, t($jcode/tex/statewise_tpl_1.tex) r($tmp/statewise_religion.csv) o($out/output_statewise_1.tex)
table_from_tpl, t($jcode/tex/statewise_tpl_2.tex) r($tmp/statewise_religion.csv) o($out/output_statewise_2.tex)

/* repeat for gender */
levelsof pc11_state_name, local(states) 
local x 0
foreach i of local states {
  
  /* increment the counter */
  local x = `x' + 1

  /* check if we have enough interaction sample to run this regression */
  sum gender_sample if pc11_state_name == "`i'"
  if `r(mean)' == 0 continue
  
  /* run a regression to see if there is in group bias in each state */
  reghdfe acquitted judge_male def_male judge_def_male if pc11_state_name == "`i'", absorb(loc_month acts) cluster(judge)
  
  /* store the coefficients */
  store_est_tpl using $tmp/statewise_gender.csv, coef(judge_male) name(`x'_jnm) all
  store_est_tpl using $tmp/statewise_gender.csv, coef(def_male) name(`x'_dnm) all
  store_est_tpl using $tmp/statewise_gender.csv, coef(judge_def_male) name(`x'_jdnm) all  
  append_to_file using $tmp/statewise_gender.csv, s("state_`x', `i'")
  
}

/* output tables with around 12 states in each to tex */
table_from_tpl, t($jcode/tex/statewise_gender_tpl_1.tex) r($tmp/statewise_gender.csv) o($out/output_statewise_gender_1.tex)
table_from_tpl, t($jcode/tex/statewise_gender_tpl_2.tex) r($tmp/statewise_gender.csv) o($out/output_statewise_gender_2.tex)

/* show timestamp */
tstop

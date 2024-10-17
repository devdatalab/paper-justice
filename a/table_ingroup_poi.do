/***********************************************************************************************/
/* This dofile replicates the analysis from a/test_same_lastname.do on the justice_poi dataset */
/***********************************************************************************************/

/*****************************/
/* PREPARE DATA FOR ANALYSIS */
/*****************************/

/* open dataset that has: def/judge last names, def/judge jati info, FEs and acq vars */
use $jdata/names/justice_poi_names, clear

/* keep only subsample for which we observe both judge and def jati */
keep if judge_merge == 3 & def_merge == 3

/* define label for jatis */
lab define jati_label 1 "SC" 2 "ST" 3 "brahman" 4 "kshatriya" 5 "vaisya" 6 "sudra"

/* sanity checks that no key vars are missing */
foreach a in judge def {
  
  assert !missing(`a'_last_name, `a'_last_name, sc_`a', st_`a', brahm_`a', kshat_`a', vaish_`a', shudr_`a')

  /* Create categorical var capturing jatis for def/judge */
  /* encoding jatis like so: SC = 1, ST = 2, brahman = 3, kshatriya = 4, vaisya = 5, sudra = 6 */
  gen `a'_jati     = 1 if sc_`a' == 1
  replace `a'_jati = 2 if st_`a' == 1
  replace `a'_jati = 3 if brahm_`a' == 1
  replace `a'_jati = 4 if kshat_`a' == 1
  replace `a'_jati = 5 if vaish_`a' == 1
  replace `a'_jati = 6 if shudr_`a' == 1

  /* add label values to var */
  lab val `a'_jati jati_label
  
  /* note that we actually have a smaller sample for which we have jati info for judge/def because for some obs all  jati indicators = 0 so we cannot infer anything about them */
  drop if `a'_jati == .
  
}

/* OPTIONAL DROP: drop all last names with strlen(last_name) <= 2
 (we do this for main analysis (Table 6 in paper) and even though the analysis on this
dofile doesn't concern last names, we've relied on names for the poi merge and
merge on 1 or 2 letters is less reliable  */
drop if (strlen(def_last_name) <= 2) | (strlen(judge_last_name) <= 2) 

/* count how many defendants are the same jati as their judge */
count if def_jati == judge_jati
gen same_jati = judge_jati == def_jati
/* 34% */

/* need a last name fixed effect since some names are more likely to appear as judges */
group def_jati
tag def_last_name

/* count the number of defendant appearances of each jati */
bys dgroup: egen jati_count = count(dgroup)

/* count the match rate for each last name */
bys dgroup: egen match_rate = mean(same_jati)

/* tag judge jatis */
egen judge_jati_tag = tag(judge_jati)

/* group judge jatis */
egen int jgroup = group(judge_jati)

/* Create inverse group size weight -- so we can equally weight each group */
gen wt = 1 / jati_count

/* label new variables */
label var wt "Inverse group weight"
label var same_jati "Same social group"
label var acq "Acquitted"

/* save dataset in working */
save $jdata/justice_poi_jatis, replace

/************/
/* ANALYSIS */ 
/************/

/* Equivalent of Table 6 in the paper. With and without judge FE, loc-month and loc-year fixed effects */
/* unweighted, without and with judge FE */
eststo clear

/* log timestamp */
set_log_time

reghdfe acq same_jati def_female def_muslim, absorb(dgroup jgroup loc_month acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "No"
estadd local wt "No"
estadd local jatife "Yes"
estimates store m1 

/* store sample size from regression above in a local */
count if e(sample) == 1
local sample_1: di `r(N)'

/* store bias coefficient in a local */
local jati_cm: di _b["same_jati"]

reghdfe acq same_jati def_female def_muslim, absorb(dgroup jgroup loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local wt "No"
estadd local jatife "Yes"
estimates store m2

reghdfe acq same_jati def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "No"
estadd local wt "Yes"
estadd local jatife "Yes"
estimates store m3 

/* store sample size from regression above in a local */
count if e(sample) == 1
local sample_2: di `r(N)'

/* store bias coefficient in a local */
local jati_cy: di _b["same_jati"]

reghdfe acq same_jati def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local wt "Yes"
estadd local jatife "Yes"
estimates store m4 

esttab m1 m2 m3 m4  using $out/table_ingroup_poi.tex, replace se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "judge Judge Fixed Effect" "wt Inverse Group Weight" "jatife Group Fixed Effect") drop(_cons def_female def_muslim) b(3)  

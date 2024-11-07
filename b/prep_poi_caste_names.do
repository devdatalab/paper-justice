/************************************************************************************/
/* Using Col 1 Table 2 sample to merge to estimate the merge quality with POI data  */
/************************************************************************************/

/***********************************************/
/* NB: This dofile takes MULTIPLE HOURS to run */
/***********************************************/

/* import analysis dataset */
use $jdata/justice_analysis, clear

/* store time stamp */
set_log_time

/* run main regression to tag sample */
reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
gen sample = e(sample) == 1

/* keep 5.2m obs sample */
keep if e(sample)

/* bring in defendants names */
merge 1:1 ddl_case_id using $jdata/cases_all_years, keepusing(def_name) keep(master match) nogen

/* extract lastname  */
gen def_last_name = word(def_name, -1)

/* make all def last names lowercase */
replace def_last_name = lower(def_last_name)

/* clean defendant last name */
replace def_last_name = "" if inlist(def_last_name, "state", "p.s.", "maharashtra")

/* drop existing defendant name variable */
drop name

/* bring in judge names */
merge m:1 ddl_judge_id using $jdata/judges_clean, keepusing(name) keep(master match) nogen
ren name judge_full_name

/* extract judge last name */
gen judge_last_name = word(judge_full_name, -1)

/* remove trailing -# from defendant names */
forval i = 1/9 {
  replace def_last_name = subinstr(def_last_name, "-`i'", "", .)
}

/* clean names */
fix_names def_last_name
fix_names judge_last_name

/* add state names  */
ren (state_code state) (state state_code)
merge m:1 state_code year using $jdata/keys/cases_state_key, nogen keep(match)

/* save sample of interest with added vars of interest */
save $tmp/justice_paper_sample_names, replace

/******************************/
/* masala merge with POI data */
/******************************/

/* drop the obs with state ids that don't appear in the POI data (because merge will fail and code will crash) */
drop if inlist(pc11_state_id, "05", "20", "22")

/* start with defendant's last name */
gen lastname = def_last_name

/* gen var containing only first letter to masala-merge within that group later */
gen first_letter = substr(lastname, 1,1)

/* keep vars state-name pairs  */
keep pc11_state_id lastname first_letter

/* drop duplicates */
duplicates drop

/* loop over each state to reduce running time of masala merge */
levelsof pc11_state_id, local(states)

/* billy ignore start  */
foreach s in `states' {

  preserve
  
  keep if pc11_state_id == "`s'"

  /* create master id for masala merge */
  gen idm = _n
  tostring idm, replace

  /* merge on names */
  masala_merge pc11_state_id first_letter using $tmp/poi_name_jatis, s1(lastname) idmaster(idm) idusing(idu) method(levonly)

  /* keep matches only */
  keep if _merge == 3
  drop _merge
  
  /* switch back to defendant last name */
  ren lastname_master def_last_name

  /* save judges for whom we've identified jatis */
  save $tmp/def_`s'_names_poi.dta, replace

  restore
  
}

/* billy ignore end */

/* next, do judge names */
use $tmp/justice_paper_sample_names, clear

/* drop the obs with state ids that don't appear in the POI data (because merge will fail and code will crash) */
drop if inlist(pc11_state_id, "05", "20", "22")

/* repeat steps for judge's last name */
gen lastname = judge_last_name

/* gen var containing only first letter to masala-merge within that group later */
gen first_letter = substr(lastname, 1, 1)

/* keep vars state-name pairs  */
keep pc11_state_id lastname first_letter

/* loop over each state */
levelsof pc11_state_id, local(states)

/* billy ignore start */

foreach s in `states' {

  preserve
  
  keep if pc11_state_id == "`s'"

  /* drop duplicates */
  duplicates drop
  
  /* create using id for masala merge */
  gen idm = _n
  tostring idm, replace

  masala_merge pc11_state_id first_letter using $tmp/poi_name_jatis, ///
      s1(lastname) idmaster(idm) idusing(idu) method(levonly)

  /* keep matches only */
  keep if _merge == 3
  drop _merge

  /* switch back to judge last name */
  ren lastname_master judge_last_name

  /* save judges for whom we've identified jatis */
  save $tmp/judge_`s'_names_poi.dta, emptyok replace

  restore

}

/* billy ignore end */

/*******************************************/
/* APPEND ALL STATES FOR DEFENDANTS/JUDGES */
/*******************************************/

/* create global with only states that show up in the intersection of POI and Justice data */
global states 02 03 04 06 07 08 09 10 11 14 15 16 17 18 19 21 23 24 27 28 29 30 32 33

/* append all states */
foreach a in def judge {

  /* billy ignore start */
  use $tmp/`a'_01_names_poi, clear
  
  foreach s in $states {

    append using $tmp/`a'_`s'_names_poi
    /* billy ignore end */
      
    save $tmp/`a'_names_poi, replace

  }
}

/* open justice data  */
use $tmp/justice_paper_sample_names, clear

/* merge in both judges and defendants */
merge m:1 pc11_state_name judge_last_name using $tmp/judge_names_poi, keep(master match) gen(judge_merge) keepusing(sc st brahm kshat vaish shudr match_source masala_dist community_name)

/* rename SC/ST/jatis to specify they come from the judge merge */
ren (sc st brahm kshat vaish shudr) (sc_judge st_judge brahm_judge kshat_judge vaish_judge shudr_judge)
ren (match_source masala_dist community_name) (j_match_source j_masala_dist j_community_name)

merge m:1 pc11_state_name def_last_name using $tmp/def_names_poi, keep(master match) gen(def_merge) keepusing(sc st brahm kshat vaish shudr match_source masala_dist community_name)

/* rename jatis for defendants */
ren (sc st brahm kshat vaish shudr) (sc_def st_def brahm_def kshat_def vaish_def shudr_def)

/* save final dataset */
save $jdata/names/justice_poi_names, replace

/**************************/
/* Estimate merge quality */
/**************************/

/* JUDGES */

/* total nr of judges in our dataset */
distinct ddl_judge_id if !missing(judge_last_name)
/* nr of distinct judges = 34,242 */

/* nr of judges whose names we can match to POI jatis */
distinct ddl_judge_id if judge_merge == 3 
/* nr of matched judges = 11,552  */
/* percentage of matched judges = 34% */

/* count of cases with known judges */
count if !missing(judge_last_name)
/* nr cases where we have judge lastname info is 5,222,309 */

/* count how many of those cases we match judges for */
count if judge_merge == 3
/* nr of cases for which we identity judge community is 1,646,787  */
/* percent of cases with judge-community info = 32% */

/* DEFENDANTS ~= CASES (we don't have a unique defendant id var, and only 162/5,223,433 missing defendant lastname obs) */

/* count nr of defendants/cases for whom we have last names */
count if !missing(def_last_name)
/* nr of cases for which we have def lastname = 5,223,271 */

/* count nr of defendnats/cases we merge with POI data */
count if def_merge == 3
/* nr of matched defendants = 1,082,815 */
/* percentage of matched defendants = 21% */

/* BOTH JUDGES AND DEFENDANT MATCHES */
count if !missing(def_last_name, judge_last_name)
/* there are 5,222,147 cases for which we have info on both def and judge last name */

count if judge_merge == 3 &  def_merge == 3 
/* nr of obs = 425,551 */
/* percentage of cases for which we match both judges and defendants to jatis = 8%  */

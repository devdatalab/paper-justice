/* This do file creates district level court counts */
/* for the RCT analysis and event study analysis samples */

/****************************************/
/* Generate court count for RCT Sample  */
/****************************************/

/* bring in analysis dataset */
use $jdata/justice_analysis, clear

/* run fixed effects regression */
reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)  

/* keep sample for district collapse */
keep if e(sample)

/* generate case identifier */
gen count = 1

/* collapse at district level to get case count at court-district level */
collapse (count) count, by(court_no state district) 

/* generate identifier for courts in district */
gen court_count = 1

/* collapse count for district courts */
collapse (count) court_count, by(state district) 

/* rename vars to prep for merge with court-district key */
ren state state_code
ren district dist_code

/* save */
save $tmp/justice_rct.dta, replace

/* also save court-district key in temp */
use $jdata/keys/pc11_court_district_key, clear
save $tmp/pc11_court_district_key, replace

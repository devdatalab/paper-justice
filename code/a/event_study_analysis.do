/* bring in analysis data */
use $jdata/justice_event_analysis, clear

/* drop bail obs */
drop if bail == 1

/* shorten dataset */
drop type_name disp_name_raw disp_name cino court act offense*

/* threshold of interval with single transition */
global threshold 175
global ts 25wk

/* require the court on the other side of this transition to be stable for at least 30 days */
/* note: this cuts out about 65% of the data. */
drop if nextprev_trans_time < 30

/* current judge needs to be in office for at least 30 days as well */
drop if current_judge_tenure < 30

/* drop places that are so far from the transition that they'll never be used (+/- 200 days) */
keep if inrange(time_to, -200, 200)

/* define a large change to be at least a 50% change in the judge female share */
global limit .5

/* define a transition that increases female share by more than 50% */
gen mf_trans = (f_transition >= $limit) 

/* define a transiton that increases male shaee by more than 50% */
gen fm_trans = (f_transition <= -$limit) 

/* define same vars for muslims */
gen mn_trans = (mus_transition <= -$limit)
gen nm_trans = (mus_transition >= $limit)

/* create regression variables */

/* create a variable that take the value of time_to_transition,
  but only on the right side of the RD */
gen time_right = time_to * (time_to >= 0)

/* create the treatment indicator for having your case decided AFTER the transition */
gen treatment  = (time_to >= 0)

/* create a fixed effect and tag for a given transition */
egen trans_group = group(transitiondate loc)
tag trans_group

/* count the number of cases associated with each transition */
bys trans_group: egen trans_case_count = count(transitiondate)

/* create a constant var so we can use areg and reghdfe w/out other f.e.s */
gen x = 1

/* save shortened event study dataset */
save $tmp/jshort, replace

/* create dataset for analysis of female judges */
drop if mi(def_female)

/* drop unused muslim variables */
drop *mus*

/* create good/bad transition type indicator  */
gen good_trans = (mf_trans == 1 & def_female == 1) | (fm_trans == 1 & def_female == 0)
gen bad_trans =  (mf_trans == 1 & def_female == 0) | (fm_trans == 1 & def_female == 1)

/* interact transition type with treatment and all RD vars */
foreach type in good bad {
  gen treatment_`type' = treatment * `type'_trans
  gen time_to_`type' = time_to_transition * `type'_trans
  gen time_right_`type' = time_right * `type'_trans
  global `type'_trans_vars treatment_`type' time_to_`type' time_right_`type'
}

/* sample is null transitions or small judge transitions */
gen sample = f_transition == 0 | good_trans == 1 | bad_trans == 1
assert inrange(f_transition, -.49, .49) & f_transition != 0 if sample != 1

save $tmp/jshort_female, replace

/* follow the same steps to create muslim judge analysis dataset */
use $tmp/jshort, clear

/* create dataset for analysis of female judges */
drop if mi(def_muslim)

/* drop unused muslim variables */
drop *female* f_transition mf_trans fm_trans

/* create good/bad transition type indicator  */
gen good_trans = (nm_trans == 1 & def_muslim == 1) | (mn_trans == 1 & def_muslim == 0)
gen bad_trans =  (nm_trans == 1 & def_muslim == 0) | (mn_trans == 1 & def_muslim == 1)

/* interact transition type with treatment and all RD vars */
foreach type in good bad {
  gen treatment_`type' = treatment * `type'_trans
  gen time_to_`type' = time_to_transition * `type'_trans
  gen time_right_`type' = time_right * `type'_trans
  global `type'_trans_vars treatment_`type' time_to_`type' time_right_`type'
}

/* sample is null transitions or small judge transitions */
gen sample = mus_transition == 0 | good_trans == 1 | bad_trans == 1
assert inrange(mus_transition, -.49, .49) & mus_transition != 0 if sample != 1

save $tmp/jshort_muslim, replace

/* lay out event study graph specifications */
global graphspec msize(vsmall) bins(40) xtitle("Days to/from Transition", size(medium))

/*************************************/
/* events study results: male/female */
/*************************************/

use $tmp/jshort_female, replace

/* set table labels global */
global labels varlabels(_cons "Mean acquittal" treatment "Constant composition judge transition" treatment_good "Pro-defendant transition" treatment_bad "Against-defendant transition" delay "Days since filing date" )

/* set model group labels */
global groups mgroups("Gender composition changes" "Religion composition changes", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(})  span erepeat(\cmidrule(lr){@span})) 

/* set global of outcomes we want to loop over */
global outcomes acq non_convicted 

/* open loop */
foreach i in $outcomes{

  /* run master regression combining good, bad, and null transitions */
  reghdfe `i' $good_trans_vars $bad_trans_vars treatment time_to_transition time_right delay if sample == 1 & inrange(time_to_transition, -25, 25), absorb(loc_month acts) cluster(trans_group)

  /* count number of transitions */
  count if e(sample) & ttag

  /* add no of transitions as scalar */
  estadd local no `r(N)'
  
  /* add mean of outcome variable as scalar */
  sum `i'
  local mean: di %6.3f (`r(mean)')
  estadd local m_`i' "`mean'"

  /* add fixed effect as scalar */
  estadd local FE "Court-month"
  
  /* store results */
  estimates store g_event_lm_`i'

  /* run master regression combining good, bad, and null transitions */
  reghdfe `i' $good_trans_vars $bad_trans_vars treatment time_to_transition time_right delay if sample == 1 & inrange(time_to_transition, -25, 25), absorb(loc_year acts) cluster(trans_group)

  /* count transitions */
  count if e(sample) & ttag

  /* add no of transitions as scalar */
  estadd local no `r(N)'

  /* add mean of outcome variable as scalar */
  sum `i'
  local mean: di %6.3f (`r(mean)')
  estadd local m_`i' "`mean'"

  /* add fixed effect as scalar */
  estadd local FE "Court-year"

  /* store results */
  estimates store g_event_ly_`i'
}
 
/* paper graphs:
1. first stage
2. female defendants
3. male defendants
4. null transition
*/

/* 1. first stage */
rd female_judge_share time_to_transition if mf_trans == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_mf_fs) title("Judge composition becomes more female", size(medium)) ytitle("Female Judge Share", size(medium)) cluster(trans_group) 

/* 2. female defendants--acquittal */
rd acq time_to_transition if mf_trans == 1 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mf_female_125) title("A: Judge composition becomes more female", size(medium)) ytitle("Acquittal, female defendants", size(medium)) cluster(trans_group) 

/* 3. male defendants */
rd acq time_to_transition if mf_trans == 1 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mf_male_125) title("B: Judge composition becomes more female", size(medium)) ytitle("Acquittal, male defendants", size(medium)) cluster(trans_group) 

/* 4. female defendants -- female-male transition */
rd acq time_to_transition if fm_trans == 1 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(fm_female_125) title("C: Judge composition becomes more male", size(medium)) ytitle("Acquittal, female defendants", size(medium)) cluster(trans_group) 

/* 5. male defendants -- female-male transition */
rd acq time_to_transition if fm_trans == 1 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(fm_male_125) title("D: Judge composition becomes more male", size(medium)) ytitle("Acquittal, male defendants", size(medium)) cluster(trans_group) 

/* 6. null transitions - female */
rd acq time_to_transition if mf_trans == 0 & fm_trans == 0 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_f) title("E: Composition-neutral judge change", size(medium)) ytitle("Acquittal, female defendants", size(medium)) cluster(trans_group) 

/* 7. null transitions -  male*/
rd acq time_to_transition if mf_trans == 0 & fm_trans == 0 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_m) title("F: Composition-neutral judge change", size(medium)) ytitle("Acquittal, male defendants", size(medium)) cluster(trans_group) 

// /* robustness: review every type of [-25, 25] regression */
// foreach transtype in mf_good mf_bad fm_good fm_bad null_f null_m {
//   disp_nice "Transition: `transtype'"
//   foreach fe in x loc "loc acts" {
//     local ifmf_good mf_trans == 1 & def_female == 1
//     local ifmf_bad  mf_trans == 1 & def_female == 0
//     local iffm_good fm_trans == 1 & def_female == 1
//     local iffm_bad  fm_trans == 1 & def_female == 0
//     local ifnull_m  fm_trans == 0 & mf_trans == 0 & def_female == 0
//     local ifnull_f  fm_trans == 0 & mf_trans == 0 & def_female == 1
//     foreach y in non_con acq { 
//       quireg `y' treatment time_to time_right if `if`transtype'' & inrange(time_to, -25, 25), robust cluster(trans_group) absorb(`fe') title("`y'-`fe'")
//     }
//   }
// }
// /* conclusion: all zeroes when clusters are correctly accounted for */

/******************************************/
/* events study results: muslim/nonmuslim */
/******************************************/
use $tmp/jshort_muslim, replace

/* open loop */
foreach i in $outcomes {

  /* run master regression combining good, bad, and null transitions */
  reghdfe `i' $good_trans_vars $bad_trans_vars treatment time_to_transition time_right delay if sample == 1 & inrange(time_to_transition, -25, 25), absorb(loc_month acts) cluster(trans_group)

  /* count number of transitions */
  count if e(sample) & ttag

  /* add no of transitions as scalar */
  estadd local no `r(N)'
  
  /* add mean of outcome variable  as scalar */
  sum `i'  
  local mean: di %6.3f `r(mean)'
  estadd local m_`i' `mean'

  /* add fixed effect as scalar */
  estadd local FE "Court-month"

  /* store results */
  estimates store r_event_lm_`i'

  /* run court-year regression */
  reghdfe `i' $good_trans_vars $bad_trans_vars treatment time_to_transition time_right delay if sample == 1 & inrange(time_to_transition, -25, 25), absorb(loc_year acts) cluster(trans_group)

  /* count number of transitions */
  count if e(sample) & ttag

  /* add no of transitions as scalar */
  estadd local no `r(N)'
  
  /* add mean of outcome variable  as scalar */
  sum `i'
  local mean: di %6.3f (`r(mean)')
  estadd local m_`i' "`mean'"

  /* add fixed effect as scalar */
  estadd local FE "Court-year"

  /* store results */
  estimates store r_event_ly_`i'
}

/* paper graphs:
1. first stage
2. muslim defendants
3. male defendants
*/

/* 1. first stage */
rd mus_judge_share time_to_transition if nm_trans == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_nm_fs) title("Judge composition becomes more Muslim", size(medium)) ytitle("Muslim Judge Share", size(medium)) cluster(trans_group) 

/* 2. muslim defendants--acquittal */
rd acq time_to_transition if nm_trans == 1 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(nm_muslim_125) title("A: Judge composition becomes more Muslim", size(medium)) ytitle("Acquittal, Muslim defendants", size(medium)) cluster(trans_group) 

/* 3. non-muslim defendants */
rd acq time_to_transition if nm_trans == 1 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(nm_nonmus_125) title("B: Judge composition becomes more Muslim", size(medium)) ytitle("Acquittal, non-Muslim defendants", size(medium)) cluster(trans_group) 

/* 4. muslim defendants - muslim to nonmuslim trans */
rd acq time_to_transition if mn_trans == 1 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mn_muslim_125) title("C: Judge composition becomes more non-Muslim", size(medium)) ytitle("Acquittal, Muslim defendants", size(medium)) cluster(trans_group) 

/* 5. muslim defendants - muslim to nonmuslim trans */
rd acq time_to_transition if mn_trans == 1 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mn_nonmus_125) title("D: Judge composition becomes more non-Muslim", size(medium)) ytitle("Acquittal, non-Muslim defendants", size(medium)) cluster(trans_group) 

/* 4. null transitions */
rd acq time_to_transition if nm_trans == 0 & mn_trans == 0 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_mus) title("E: Composition-neutral judge change", size(medium)) ytitle("Acquittal, Muslim defendants", size(medium)) cluster(trans_group) 

/* 5. null transition non-mus */
rd acq time_to_transition if nm_trans == 0 & mn_trans == 0 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_nm) title("F: Composition-neutral judge change", size(medium)) ytitle("Acquittal, non-Muslim defendants", size(medium)) cluster(trans_group) 


// /* robustness: review every type of [-25, 25] regression */
// foreach transtype in nm_good nm_bad mn_good mn_bad null_m null_n {
//   disp_nice "Transition: `transtype'"
//   foreach fe in x loc "loc acts" {
//     local ifnm_good nm_trans == 1 & def_muslim == 1
//     local ifnm_bad  nm_trans == 1 & def_muslim == 0
//     local ifmn_good mn_trans == 1 & def_muslim == 1
//     local ifmn_bad  mn_trans == 1 & def_muslim == 0
//     local ifnull_n  mn_trans == 0 & nm_trans == 0 & def_muslim == 0
//     local ifnull_m  mn_trans == 0 & nm_trans == 0 & def_muslim == 1
//     foreach y in non_con acq { 
//       quireg `y' treatment time_to_transition time_right if `if`transtype'' & inrange(time_to_transition, -25, 25), robust cluster(trans_group) absorb(`fe') title("`y'-`fe'")
//     }
//   }
// }
// /* conclusion: all zeroes when clusters are correctly accounted for */

/*******************************/
/* A combined regression table */
/*******************************/

/* table for acquitted as outcome */
esttab g_event_lm_acq g_event_ly_acq r_event_lm_acq r_event_ly_acq using "$out/event_main.tex", replace se label star(* 0.10 ** 0.05 *** 0.01) keep(treatment_good treatment_bad treatment) $labels $groups scalars( "no No. of transitions" "m_acq Mean Acquittal rate" "FE Fixed effect") b(3) se(3)

/* table for non convicted as outcome */
esttab g_event_lm_non_convicted g_event_ly_non_convicted r_event_lm_non_convicted r_event_ly_non_convicted using "$out/event_non_convicted.tex", replace se label star(* 0.10 ** 0.05 *** 0.01) keep(treatment_good treatment_bad treatment) $labels $groups scalars( "no No. of transitions" "m_non_convicted Mean non-convicted"  "FE Fixed effect") b(3) se(3)

/*********************/
/* First stage panel */
/*********************/
graph combine event_mf_fs event_nm_fs
graphout firststage, pdf

/****************************/
/* Gender event study graph */
/****************************/
graph combine mf_female_125 mf_male_125, ycommon
graphout mf_event_fig, pdf

graph combine fm_female_125 fm_male_125, ycommon
graphout fm_event_fig, pdf

graph combine event_null_f event_null_m, ycommon
graphout g_null_event_fig, pdf

/******************************/
/* Religion event study graph */
/******************************/
graph combine nm_muslim_125 nm_nonmus_125, ycommon
graphout nm_event_fig, pdf

graph combine mn_muslim_125 mn_nonmus_125, ycommon
graphout mn_event_fig, pdf

graph combine event_null_mus event_null_nm, ycommon
graphout r_null_event_fig, pdf

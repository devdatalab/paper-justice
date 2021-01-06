/* load analysis dataset */
use $jdata/justice_analysis, clear

/* drop bail outcomes */
drop if bail == 1

/* generate sample for gender randomization test using acquitted or decision as outcomes */
foreach outcome in acq decision{

/* gender - court month FE sample */
  qui reghdfe `outcome' judge_female def_female judge_def_female def_muslim, absorb(loc_month acts) cluster(judge)
  gen lmg_sample_`outcome' = 1 if e(sample) == 1

/* gender - court year FE sample */
  qui reghdfe `outcome' judge_female def_female judge_def_female def_muslim, absorb(loc_year acts) cluster(judge)
  gen lyg_sample_`outcome' = 1 if e(sample) == 1

/* religion - court month FE sample */
  qui reghdfe `outcome' judge_muslim def_female judge_def_muslim def_muslim, absorb(loc_month acts) cluster(judge)
  gen lmr_sample_`outcome' = 1 if e(sample) == 1

/* religion - court year FE sample */
  qui reghdfe `outcome' judge_muslim def_female judge_def_muslim def_muslim, absorb(loc_year acts) cluster(judge)
  gen lyr_sample_`outcome' = 1 if e(sample) == 1

}

/*******************************/
/* Panel A of regression table */
/*******************************/

reghdfe judge_female def_female def_muslim  if lmg_sample_acq == 1, absorb(loc_month acts) cluster(judge)

estadd local FE "Court-month"
estimates store m1

reghdfe judge_female def_female def_muslim  if lyg_sample_acq == 1, absorb(loc_year acts) cluster(judge)

estadd local FE "Court-year"
estimates store m2

reghdfe judge_muslim def_female def_muslim  if lmr_sample_acq == 1, absorb(loc_month acts) cluster(judge)

estadd local FE "Court-month"
estimates store m3

reghdfe judge_muslim def_female def_muslim  if lyr_sample_acq == 1, absorb(loc_year acts) cluster(judge)

estadd local FE "Court-year"
estimates store m4

/* output panel  */
esttab m1 m2 m3 m4 using "$tmp/random_acq.tex", replace se label star(* 0.10 ** 0.05 *** 0.01) drop(_cons) scalars("FE Fixed Effect")


/*******************************/
/* Panel B of regression table */
/*******************************/

reghdfe judge_female def_female def_muslim  if lmg_sample_decision == 1, absorb(loc_month acts) cluster(judge)

estadd local FE "Court-month"
estimates store m5

reghdfe judge_female def_female def_muslim  if lyg_sample_decision == 1, absorb(loc_year acts) cluster(judge)

estadd local FE "Court-year"
estimates store m6

reghdfe judge_muslim def_female def_muslim  if lmr_sample_decision == 1, absorb(loc_month acts) cluster(judge)

estadd local FE "Court-month"
estimates store m7

reghdfe judge_muslim def_female def_muslim  if lyr_sample_decision == 1, absorb(loc_year acts) cluster(judge)

estadd local FE "Court-year"
estimates store m8

/* output panel  */
esttab m5 m6 m7 m8 using "$tmp/random_decision.tex", replace se label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect") drop(_cons)

/************************************************/
/* Combine both regressions into a single panel */
/************************************************/

/* run panel combine */
panelcombine, use($tmp/random_acq.tex $tmp/random_decision.tex)  columncount(4) paneltitles("Sample with clear acquitted/convicted outcomes" "Sample including observations with no decision") save($out/randomization_combined.tex) cleanup

/* load analysis dataset */
use $jdata/justice_analysis, clear

/* generate sample for gender randomization test using acquitted or decision as outcomes */
/* Warning: the block below takes at least 20-25 mins to run */
foreach outcome in acq { //decision{

/* gender - court month FE sample */
  qui reghdfe `outcome' judge_def_male, absorb(loc_month acts judge) cluster(judge)
  gen lmg_sample_`outcome' = 1 if e(sample) == 1

  /* gender - court year FE sample */
  qui reghdfe `outcome' judge_def_male, absorb(loc_year acts judge) cluster(judge)
  gen lyg_sample_`outcome' = 1 if e(sample) == 1

/* religion - court month FE sample */
  qui reghdfe `outcome' judge_def_nonmuslim, absorb(loc_month acts judge) cluster(judge)
  gen lmr_sample_`outcome' = 1 if e(sample) == 1

/* religion - court year FE sample */
  qui reghdfe `outcome' judge_def_nonmuslim , absorb(loc_year acts judge) cluster(judge)
  gen lyr_sample_`outcome' = 1 if e(sample) == 1

}

/*******************************/
/* Panel A of regression table */
/*******************************/

/* record timestamp before running regressions */
set_log_time

/* balance test 1: female defendant not more likely to get female judge, month FE */
reghdfe judge_female def_female def_muslim  if lmg_sample_acq == 1, absorb(loc_month acts) cluster(judge)
  
/* store sample size from the regression above*/
count if e(sample) == 1
local balance_count: di `r(N)'

/* write out balance test sample to a csv */  
store_paper_stat `balance_count' using $out/justice_paper_stats.csv, description("Balance: Sample size (Col (1) only)") group("balance")

/* store balance test 1 coefficients in stats csv */
local ff_coef_cm: di _b["def_female"]
store_paper_stat `ff_coef_cm' using $out/justice_paper_stats.csv, description("Balance: female judge X female def - court-month") group("balance")  
local fm_coef_cm: di _b["def_muslim"]
store_paper_stat `fm_coef_cm' using $out/justice_paper_stats.csv, description("Balance: female judge X muslim def - court-month") group("balance")  

/* store estimates for regression table */ 
estadd local FE "Court-month"
estimates store m1

/* balance test 2: female defendant not more likely to get female judge, year FE */  
reghdfe judge_female def_female def_muslim  if lyg_sample_acq == 1, absorb(loc_year acts) cluster(judge)

/* store estimates for regression table */  
estadd local FE "Court-year"
estimates store m2

/* store balance test 2 coefficients in stats csv */
local ff_coef_cy: di _b["def_female"]
store_paper_stat `ff_coef_cy' using $out/justice_paper_stats.csv, description("Balance: female judge X female def - court-year") group("balance")  
local fm_coef_cy: di _b["def_muslim"]
store_paper_stat `fm_coef_cy' using $out/justice_paper_stats.csv, description("Balance: female judge X muslim def - court-year") group("balance")  
  
/* balance test 3: muslim defendant not more likely to get muslim judge, month FE */
reghdfe judge_muslim def_female def_muslim  if lmr_sample_acq == 1, absorb(loc_month acts) cluster(judge)

/* store coefficients in stats csv */
local mm_coef_cm: di _b["def_muslim"]
store_paper_stat `mm_coef_cm' using $out/justice_paper_stats.csv, description("Balance: muslim judge X muslim def - court-month") group("balance")  
local mf_coef_cm: di _b["def_female"]
store_paper_stat `mf_coef_cm' using $out/justice_paper_stats.csv, description("Balance: muslim judge X female def - court-month") group("balance")  

/* store results for regression table */  
estadd local FE "Court-month"
estimates store m3

/* balance test 4: muslim defendant not more likely to get muslim judge,year FE */
reghdfe judge_muslim def_female def_muslim  if lyr_sample_acq == 1, absorb(loc_year acts) cluster(judge)

/* store coefficients in stats csv */
local mm_coef_cy: di _b["def_muslim"]
store_paper_stat `mm_coef_cy' using $out/justice_paper_stats.csv, description("Balance: muslim judge X muslim def - court-year") group("balance")  
local mf_coef_cy: di _b["def_female"]
store_paper_stat `mf_coef_cy' using $out/justice_paper_stats.csv, description("Balance: muslim judge X female def - court-year") group("balance")  

/* store results for regression table */  
estadd local FE "Court-year"
estimates store m4

/* output panel  */
esttab m1 m2 m3 m4 using "$out/random_acq.tex", replace se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect") drop(_cons) b(3)


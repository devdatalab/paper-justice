/***************************************************/
/* Main balance table for subset with lawyer names */
/***************************************************/

/* load cases where we have lawyer identities */
use $jdata/lawyer_name_analysis if inlist(def_adv_nonmuslim, 0, 1) & inlist(pet_adv_nonmuslim, 0, 1) & inlist(def_adv_male, 0, 1) & inlist(pet_adv_male, 0, 1), clear

/* there are 150k cases where we have pet adv identities even though the name is missing */
count if pet_adv=="" & inlist(pet_adv_nonmuslim,0,1) & inlist(pet_adv_female,0,1)

/* there are 15k cases where we have def adv identities even though the name is missing */
count if def_adv=="" & inlist(def_adv_nonmuslim,0,1) & inlist(def_adv_female,0,1)

// how does this make sense?

/* balance test 1: female defendant not more likely to get female judge, month FE */
reghdfe judge_female def_female def_muslim, absorb(loc_month acts) cluster(judge)
  
/* store estimates for regression table */ 
estadd local FE "Court-month"
estimates store m1

/* balance test 2: female defendant not more likely to get female judge, year FE */  
reghdfe judge_female def_female def_muslim, absorb(loc_year acts) cluster(judge)

/* store estimates for regression table */  
estadd local FE "Court-year"
estimates store m2
  
/* balance test 3: muslim defendant not more likely to get muslim judge, month FE */
reghdfe judge_muslim def_female def_muslim, absorb(loc_month acts) cluster(judge)

/* store results for regression table */  
estadd local FE "Court-month"
estimates store m3

/* balance test 4: muslim defendant not more likely to get muslim judge,year FE */
reghdfe judge_muslim def_female def_muslim, absorb(loc_year acts) cluster(judge)

/* store results for regression table */  
estadd local FE "Court-year"
estimates store m4

/* output panel  */
esttab m1 m2 m3 m4 using "$out/balance_lawyers.tex", replace b(4) se(4) label  s(FE N, label("Fixed Effect" "Observations") fmt(0 0)) drop(_cons) nonotes nostar

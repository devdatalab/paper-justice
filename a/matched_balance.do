/* load full justice data with matched & unmatched obs */
use  $jdata/cases_all_years, clear

/* drop bail cases */
gen sample = 1 if bail != 1

/* remove minority of plea bargained outcomes which didn't make it to trial */
merge m:1 year disp_name using $jdata/keys/disp_name_key, keepusing(disp_name_s) keep(match master) nogen
drop if disp_name_s == "plea bargaining"
drop disp_name_s

/* vars we need */
/* 1. outcome */
/* 2. sentence severity */
/* 3. north/south geo */
/* 4. district urbanization data */
/* 5. defendant religion */
/* 6. defendant gender */

/* create geo vars */
gen south = inlist(state_name, "Karnataka", "Kerala", "Andhra Pradesh", "Telangana", "Tamil Nadu")
gen west = inlist(state_name, "Maharashtra", "Diu and Daman", "DNH at Silvasa", "Gujarat", "Goa")
gen east = inlist(state_name, "West Bengal", "Orissa", "Assam", "Meghalaya", "Mizoram", "Manipur", "Sikkim", "Tripura")
gen north = south == 0 & west == 0 & east == 0

/* bring in sentence length for subset of cases we have them for */
gen section_ipc = section if act == "The Indian Penal Code"
merge m:1 section_ipc using $jdata/keys/ipc_section_key, keepusing(prison_ipc_mean) nogen keep(master match)

/* get pc11 district IDs */
drop state_code
ren state state_code
merge m:1 state_code district_name using $jdata/keys/pc11_court_district_key, keep(master match) nogen

/* district level urbanization rates */
merge m:1 pc11_state_id pc11_district_id using ~/iec/covid/demography/pc11/dem_district_pc11, keep(master match) nogen keepusing(pc11_urb_share)

/* create defendant demo variables */
create_demo_dummy

/* generate conviction */
gen conv = 1 - non_conv

/* relabel match values */
la define m 1 "Unmatched sample" 0 "Matched sample", modify
la val judge_merge m

/* label other variables */
la var acq "Aquitted"
la var conv "Convicted"
la var prison_ipc_mean "Typical prison sentence"
la var north "North"
la var south "South"
la var east "East"
la var west "West"
la var pc11_urb_share "Urban population share in district"
la var def_male "Male defendant share"
la var def_nonmuslim "Non-Muslim defendant share"
la var decision "Decision within 6 months"

/* recode judge merge variable */
replace judge_merge = 0 if judge_merge == 3

/* we now have all variables to make the balance table */
/* create the balance table */
iebaltab acq conv prison_ipc_mean north pc11_urb_share decision def_male ///
    def_nonmuslim if sample == 1, grpvar(judge_merge) ///
    savetex($out/match_balance.tex) replace rowvarlabels

/* generate treatment variable for reweighting */
/* this takes value 1 for matched sample */
gen treatment = 1 - judge_merge

/* generate weights to balance matched sample */
ebalance treatment north pc11_urb_share def_male def_nonmuslim  ///
    , targets(1) maxiter(50) generate(_webal1)

ebalance treatment north pc11_urb_share def_male def_nonmuslim  ///
    , targets(2) maxiter(50) generate(_webal2)

ebalance treatment north pc11_urb_share def_male def_nonmuslim ///
    , targets(3) maxiter(50) generate(_webal3)

/* check that weights work */
foreach var in north pc11_urb_share def_male def_nonmuslim {
  reg `var' judge_merge [pw = _webal3]
}


/* keep ddl_case_id and weights */
keep ddl_case_id _webal*

/* save */
compress
save $jdata/balance_weights, replace

/*********************/
/* Robustness tables */
/*********************/

use $jdata/justice_analysis, clear

/* bring in weights */
merge 1:1 ddl_case_id using $jdata/balance_weights, keep(master match) nogen

/* estimates store */
eststo clear

/* gender */
gen bias = judge_def_male
reghdfe acquitted judge_male def_male bias def_nonmuslim judge_men_def_nm ///
    [pw = _webal3], absorb(loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estimates store m1

reghdfe acquitted judge_male def_male bias def_nonmuslim judge_men_def_nm ///
    [pw = _webal3], absorb(loc_year acts judge) cluster(judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estimates store m2

/* religion */
replace bias = judge_def_nonmuslim
reghdfe acquitted judge_nonmuslim def_nonmuslim bias def_male judge_nm_def_men ///
    [pw = _webal3], absorb(loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estimates store m3

reghdfe acquitted judge_nonmuslim def_nonmuslim bias def_male judge_nm_def_men ///
    [pw = _webal3], absorb(loc_year acts judge) cluster(judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estimates store m4

/* make table */
esttab m1 m2 m3 m4 using $out/bias_weighted_sample.tex, ///
    replace se(3) label star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("FE Fixed Effect" "judge Judge Fixed Effect") ///
    keep(bias) ///
    coeflabel(bias "Ingroup Bias") b(3) ///
    mlabel("Gender" "Gender" "Religion" "Religion")


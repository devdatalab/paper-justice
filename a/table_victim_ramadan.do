/************************************/
/* prep dataset for victim analysis */
/************************************/
/* open analysis dataset */
use $jdata/justice_analysis, clear

/* create a variable that takes value 1 if victim identity */
/* and defendant identity vary */
gen gender_mismatch = (def_female + pet_female) == 1 if !mi(def_female) & !mi(pet_female)
gen religion_mismatch = (def_muslim + pet_muslim) == 1 if !mi(def_muslim) & !mi(pet_muslim)

/* create victim interaction variables */
gen jdmale_mis = judge_def_male * gender_mismatch
gen jmale_mis = judge_male * gender_mismatch
gen dmale_mis = def_male * gender_mismatch
gen jdnmus_mis = judge_def_nonmuslim * religion_mismatch
gen jnmus_mis = judge_nonmuslim * religion_mismatch
gen dnmus_mis = def_nonmuslim * religion_mismatch
gen jdmus_mis = judge_def_muslim * religion_mismatch
gen jmus_mis = judge_muslim * religion_mismatch
gen dmus_mis = def_muslim * religion_mismatch

/* create crimes against women interactions */
gen jdmale_wc = judge_def_male * women_crime
gen jmale_wc = judge_male * women_crime
gen dmale_wc = def_male * women_crime

/* label variables */
la var gender_mismatch "Gender mismatch"
la var religion_mismatch "Religion mismatch"
la var judge_male "Male judge"
la var judge_muslim "Muslim judge"
la var def_muslim "Muslim defendant"
la var def_male "Male defendant"
la var acq "Acquitted"
label drop muslim

la var jdmale_mis "Male judge and defendant * Mismatch"
la var jmale_mis "Male judge * Mismatch"
la var dmale_mis "Male defendant * Mismatch"
la var jdnmus_mis "Non-Muslim judge and defendant * Mismatch"
la var jnmus_mis "Non-Muslim judge * Mismatch"
la var dnmus_mis "Non-Muslim defendant * Mismatch"
la var jdmus_mis "Muslim judge and defendant * Mismatch"
la var jmus_mis "Muslim judge * Mismatch"
la var dmus_mis "Muslim defendant * Mismatch"
la var jdmale_wc "Male judge and defendant * Crime Against Women"
la var jmale_wc "Male judge * Crime Against Women"
la var dmale_wc "Male defendant * Crime Against Women"
la var women_crime "IPC is Crimes Against Women"

/**********************/
/* Outcome: Acquitted */
/**********************/
global gender_vars judge_male def_male 
global religion_vars judge_muslim def_muslim 

/* we want the bias columns stored in the same variable */
gen bias = judge_def_male

/* label bias coefficients for just this table */
label var bias "Ingroup Bias"
label var jdmale_mis "Ingroup Bias * Victim Gender Mismatch"
label var jdmus_mis "Ingroup Bias * Victim Religion Mismatch"
label var jdmale_wc "Ingroup Bias * Crime Against Women"

save $tmp/victim_tmp, replace

/******************/
/* Ramadan column */
/******************/

/* import analysis dataset */
tgo
use $jdata/justice_analysis, clear

/* drop all judge vars, since we want the judge on the decision date, not filing date */
drop judge*
drop ddl_judge_id

/* drop if no decision date */
drop if mi(decision_date)

/* get decision judge info */
ren ddl_decision_judge_id ddl_judge_id
merge m:1 ddl_judge_id using $jdata/judges_clean, keep(match) nogen keepusing(muslim_class female_class)

/* rename judge classification variables */
ren muslim_class judge_muslim
ren female_class judge_female

/* create standard classification variables */
gen judge_male = 1 - judge_female
gen judge_nonmuslim = 1 - judge_muslim
gen judge_def_male = judge_male * def_male
gen judge_def_muslim = judge_muslim * def_muslim
gen judge_def_nonmuslim = judge_nonmuslim * def_nonmuslim
egen judge = group(ddl_judge_id)

/* drop judges with missing religion info */
drop if judge_muslim == 9999 | def_muslim == 9999 | judge_nonmuslim == 9999
drop if mi(judge_muslim)

/* set dates for Ramadan and Hindu festivals */
set_festival_dates

/* make sure they look right, by summarizing share of ramadan cases each year-month */
gen ym = string(year(decision_date)) + "-" + substr("0" + string(month(decision_date)), -2, 2)
bys ym: egen mean_ramadan = mean(ramadan)
tag ym
sort ym
list ym mean_ramadan if ytag
drop mean_ramadan ytag ym

/* create interactions between ramadan and X variables */
gen j_nm_r = judge_nonmuslim * ramadan
gen d_nm_r = def_nonmuslim * ramadan
gen jd_nm_r = judge_def_nonmuslim * ramadan

/* create interactions between "all Hindu festivals" and X variables */
gen j_nm_hf = judge_nonmuslim * all_festivals_wa
gen d_nm_hf = def_nonmuslim * all_festivals_wa
gen jd_nm_hf = judge_def_nonmuslim * all_festivals_wa

/* label variabels */
la var judge_nonmuslim "Non-muslim judge"
la var def_nonmuslim "Non-muslim defendant"
la var judge_def_nonmuslim "Ingroup Bias"
la var ramadan "Ramadan"
la var all_festivals_wa "Hindu Festival"
la var j_nm_r "Non-muslim judge * Ramadan"
la var d_nm_r "Non-muslim defendant * Ramadan"
la var jd_nm_r "Ingroup Bias * Ramadan"
la var j_nm_hf "Non-muslim judge * Hindu Festivals"
la var d_nm_hf "Non-muslim defendant * Hindu Festivals"
la var jd_nm_hf "Ingroup Bias * Hindu Festivals"
ren judge_def_nonmuslim bias

/* save temporary religion analysis dataset */
save $tmp/religion_tmp, replace

/* main specification */
reghdfe acquitted judge_nonmuslim def_nonmuslim ramadan bias j_nm_r d_nm_r jd_nm_r , absorb(loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Ramadan"
estadd local sample "All"
estimates store ramadan

/* court-year */
reghdfe acquitted judge_nonmuslim def_nonmuslim  ramadan bias j_nm_r d_nm_r jd_nm_r , absorb(loc_year acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Ramadan"
estadd local sample "All"
estimates store ramadan_cy

/* same specs for hindu festivals */
reghdfe acquitted judge_nonmuslim def_nonmuslim  all_festivals_wa bias j_nm_hf d_nm_hf jd_nm_hf , absorb(loc_month acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Ramadan"
estadd local sample "All"
estimates store hindufestival

/* court-year */
reghdfe acquitted judge_nonmuslim def_nonmuslim  all_festivals_wa bias j_nm_hf d_nm_hf jd_nm_hf , absorb(loc_year acts judge) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Ramadan"
estadd local sample "All"
estimates store hindufestival_cy


/****************/
/* Victim panel */
/****************/

global gender_vars judge_male def_male 
global religion_vars judge_nonmuslim def_nonmuslim 

use $tmp/victim_tmp, clear

label var bias "Ingroup Bias"
label var jdmale_mis "Ingroup Bias * Victim Gender mismatch"
label var jdmus_mis "Ingroup Bias * Victim Religion mismatch"
label var jdmale_wc "Ingroup Bias * Crime against women"
la var jdmale_mis "Ingroup Bias * Gender mismatch"
la var jmale_mis "Male judge * Gender mismatch"
la var dmale_mis "Male defendant * Gender mismatch"
la var jdmus_mis "Ingroup Bias * Religion mismatch"
la var jmus_mis "Muslim judge * Religion mismatch"
la var dmus_mis "Muslim defendant * Religion mismatch"
la var jdmale_wc "Ingroup Bias * Crime against women"
la var jmale_wc "Male judge * Crime against women"
la var dmale_wc "Male defendant * Crime against women"
la var women_crime "IPC is Crimes against women"

reghdfe acquitted bias $gender_vars jdmale_mis jmale_mis dmale_mis gender_mismatch , absorb(loc_month judge acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Gender"
estadd local sample "All"
estimates store m1 

/* calculate effect on group most likely to see bias */
lincom bias + jdmale_mis

/* 2. religion victim interaction */
/* replace bias with muslim bias variable so it takes same row in the estout table */
replace bias = judge_def_nonmuslim
reghdfe acquitted bias $religion_vars jdnmus_mis jnmus_mis dnmus_mis religion_mismatch , absorb(loc_month judge acts  ) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Religion"
estadd local sample "All"
estimates store m2

/* calculate effect on group most likely to see bias */
lincom bias + jdnmus_mis

/* 3. crimes against women interaction */
/* replace bias with gender bias variable */
replace bias = judge_def_male
reghdfe acquitted bias $gender_vars jdmale_wc jmale_wc dmale_wc women_crime , absorb(loc_month judge acts) cluster(judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estadd local bias "Gender"
estadd local sample "All"
estimates store m3

lincom bias + jdmale_wc
 
/* write main table */
esttab m1 m2 m3 ramadan hindufestival ///
    using $out/victim_inter.tex, replace se(4) ///
    label star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("FE Fixed Effect" "judge Judge Fixed Effect"  "sample Sample") ///
    keep(bias jdmale_mis jdnmus_mis jdmale_wc jd_nm_r jd_nm_hf) b(4) ///
    mlabel("Gender" "Religion" "Gender" "Religion" "Religion")  ///
    coeflabel(jd_nm_r "Ingroup Bias * Ramadan" jd_nm_hf "Ingroup Bias * Hindu Festival") ///
    order(bias jdmale_mis jdnmus_mis jdmale_wc jd_nm_r jd_nm_hf)

/* for appendix, rewrite the same tables, but with all ancillary coefficients */
/* religion */
esttab m2 ramadan hindufestival ///
    using $out/victim_inter_all_r.tex, replace se(4) ///
    label star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("FE Fixed Effect" "judge Judge Fixed Effect"  "sample Sample") ///
    drop(_cons) b(4) noomitted ///
    coeflabel(def_nonmuslim "Non-Muslim defendant" ///
    ramadan "Ramadan" all_festivals_wa "Hindu Festival" j_nm_r "Non-Muslim judge * Ramadan" ///
    j_nm_hf "Non-Muslim judge * Hindu Festival" ///
    d_nm_r "Non-Muslim defendant * Ramadan" ///
    d_nm_hf "Non-Muslim defendant * Hindu Festival" ///
    judge_nonmuslim "Non-Muslim judge" ///
    bias "Ingroup Bias" ///
    jdmus_mis "\textbf{Ingroup Bias * Religion mismatch}"    ///
    jd_nm_r "\textbf{Ingroup Bias * Ramadan}" ///
    jd_nm_hf "\textbf{Ingroup Bias * Hindu Festival}") ///
    order(religion_mismatch def_nonmuslim bias jnmus_mis dnmus_mis ///
    jdnmus_mis ramadan def_nonmuslim bias j_nm_r d_nm_r jd_nm_r all_festivals_wa j_nm_hf d_nm_hf jd_nm_hf)

/* gender */
esttab m1 m3 ///
    using $out/victim_inter_all_g.tex, replace se(4) ///
    label star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("FE Fixed Effect" "judge Judge Fixed Effect"  "sample Sample") ///
    drop(_cons) b(4) noomitted ///
    coeflabel(jmale_wc "Male judge * Crime Against Women" ///
    jdmale_mis "\textbf{Ingroup Bias * Gender mismatch}" ///
    jdmale_wc "\textbf{Ingroup Bias * Crimes Against Women}" ///  
    dmale_wc "Male defendant * Crime Against Women")  ///
    order(gender_mismatch def_male bias jmale_mis dmale_mis ///
    jdmale_mis jmale_wc dmale_wc jdmale_wc) 

/*************************************************/
/* Appendix: Court-year FE version of main table */
/*************************************************/
reghdfe acquitted bias $gender_vars jdmale_mis jmale_mis dmale_mis gender_mismatch , absorb(loc_year judge acts) cluster(judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estadd local bias "Gender"
estadd local sample "All"
estimates store m4 

/* calculate effect on group most likely to see bias */
lincom bias + jdmale_mis

/* 2. religion victim interaction */
/* replace bias with muslim bias variable so it takes same row in the estout table */
replace bias = judge_def_nonmuslim
reghdfe acquitted bias $religion_vars jdnmus_mis jnmus_mis dnmus_mis religion_mismatch , absorb(loc_year judge acts  ) cluster(judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estadd local bias "Religion"
estadd local sample "All"
estimates store m5

/* calculate effect on group most likely to see bias */
lincom bias + jdnmus_mis

/* 3. crimes against women interaction */
/* replace bias with gender bias variable */
replace bias = judge_def_male
reghdfe acquitted bias $gender_vars jdmale_wc jmale_wc dmale_wc women_crime , absorb(loc_year judge acts) cluster(judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estadd local bias "Gender"
estadd local sample "All"
estimates store m6

lincom bias + jdmale_wc

/* write table */
esttab m4 m5 m6 ramadan_cy hindufestival_cy ///
    using $out/victim_inter_cy.tex, replace se(4) ///
    label star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("FE Fixed Effect" "judge Judge Fixed Effect"  "sample Sample") ///
    keep(bias jdmale_mis jdnmus_mis jdmale_wc jd_nm_r jd_nm_hf) b(4) ///
    mlabel("Gender" "Religion" "Gender" "Religion" "Religion") ///
    coeflabel(jd_nm_r "Ingroup Bias * Ramadan" jd_nm_hf "Ingroup Bias * Hindu Festival") ///
    order(bias jdmale_mis jdnmus_mis jdmale_wc jd_nm_r jd_nm_hf)

tstop

/***********************************/
/* victim info availability counts */
/***********************************/
use $tmp/victim_tmp, clear

global gender_vars judge_male def_male 
global religion_vars judge_muslim def_muslim 

reg acquitted bias $gender_vars loc_month acts
tab gender_mismatch if e(sample), mi

reg acquitted bias $religion_vars loc_month acts
tab religion_mismatch if e(sample), mi

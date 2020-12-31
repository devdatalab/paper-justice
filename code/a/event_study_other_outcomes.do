/* Replicate gender event study using delay as outcome */
use $tmp/jshort_female, clear

global graphspec msize(vsmall) bins(40) xtitle("Days to/from Transition") 

set scheme pn

/*********/
/* Delay */
/*********/

rd delay time_to_transition if mf_trans == 1 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mf_female_125) title("Judge composition becomes more male: Female defendants", size(small)) ytitle("Days since filing date") cluster(trans_group) 

rd delay time_to_transition if mf_trans == 1 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mf_male_125) title("Judge composition becomes more female: Male defendants", size(small)) ytitle("Days since filing date") cluster(trans_group) 

rd delay time_to_transition if mf_trans == 0 & fm_trans == 0 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_f) title("Composition-neutral judge change: Female defendants", size(small)) ytitle("Days since filing date") cluster(trans_group) 

rd delay time_to_transition if mf_trans == 0 & fm_trans == 0 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_m) title("Composition-neutral judge change: Male defendants", size(small)) ytitle("Days since filing date") cluster(trans_group) 

graph combine mf_female_125 mf_male_125 event_null_f event_null_m, title("Outcome: Days since filing date", size(medium)) ycommon
graphout g_event_delay, pdf

/******************************/
/* No. of cases seen in court */
/******************************/

preserve

drop if mi(decision_date)

/* generate no of cases seen in a court */
bys loc decision_date: gen case_count = _N

/* topcode case count variable */
sum case_count, d
replace case_count = . if case_count > `r(p95)'

/* label this outcome var */
la var case_count "No of cases decided in a court in a day"

rd case_count time_to_transition if mf_trans == 1 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mf_female_125) title("Judge composition becomes more male: Female defendants", size(small)) ytitle("# cases decided in a court in a day") cluster(trans_group) 

rd case_count time_to_transition if mf_trans == 1 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mf_male_125) title("Judge composition becomes more female: Male defendants", size(small)) ytitle("# cases decided in a court in a day") cluster(trans_group) 

rd case_count time_to_transition if mf_trans == 0 & fm_trans == 0 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_f) title("Composition-neutral judge change: Female defendants", size(small)) ytitle("# cases decided in a court in a day") cluster(trans_group) 

rd case_count time_to_transition if mf_trans == 0 & fm_trans == 0 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_m) title("Composition-neutral judge change: Male defendants", size(small)) ytitle("# cases decided in a court in a day") cluster(trans_group) 

graph combine mf_female_125 mf_male_125 event_null_f event_null_m, title("Outcome: # cases decided in a court in a day", size(medium)) ycommon
graphout g_event_case_count, pdf

restore

/***********************/
/* Punishment severity */
/***********************/

preserve

/* keep only IPC cases */
keep if !mi(number_sections_ipc)

/* now merge with our IPC sections dataset to bring in punishment */
gen section_ipc = section
merge m:1 section_ipc using $jdata/keys/ipc_section_key, keepusing(prison_ipc_mean) nogen keep(match)

/* label the punishment var */
la var prison_ipc "Years of prison associated with section"

rd prison_ipc_mean time_to_transition if mf_trans == 1 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mf_female_125) title("Judge composition becomes more male: Female defendants", size(small)) ytitle("Outcome severity") cluster(trans_group) 


rd prison_ipc_mean time_to_transition if mf_trans == 1 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(mf_male_125) title("Judge composition becomes more female: Male defendants", size(small)) ytitle("Outcome severity") cluster(trans_group) 


rd prison_ipc_mean time_to_transition if mf_trans == 0 & fm_trans == 0 & def_female == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_f) title("Composition-neutral judge change: Female defendants", size(small)) ytitle("Outcome severity") cluster(trans_group) 


rd prison_ipc_mean time_to_transition if mf_trans == 0 & fm_trans == 0 & def_female == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_m) title("Composition-neutral judge change: Male defendants", size(small)) ytitle("Outcome severity") cluster(trans_group) 


graph combine mf_female_125 mf_male_125 event_null_f event_null_m, title("Outcome: Years of prison associated with offense", size(medium)) ycommon
graphout g_event_severity, pdf

restore

/* Replicate religion event study using delay as outcome */
use $tmp/jshort_muslim, clear

global graphspec msize(vsmall) bins(40) xtitle("Days to/from Transition") 

set scheme pn

/*********/
/* Delay */
/*********/

rd delay time_to_transition if nm_trans == 1 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(nm_muslim_125) title("Judge composition becomes more Muslim: Muslim defendants", size(small)) ytitle("Days since filing date") cluster(trans_group) 


rd delay time_to_transition if nm_trans == 1 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(nm_nonmuslim_125) title("Judge composition becomes more Muslim: Nonmuslim defendants", size(small)) ytitle("Days since filing date") cluster(trans_group) 


rd delay time_to_transition if nm_trans == 0 & mn_trans == 0 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_mus) title("Composition-neutral judge change: Muslim defendants", size(small)) ytitle("Days since filing date") cluster(trans_group) 


rd delay time_to_transition if nm_trans == 0 & mn_trans == 0 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_nm) title("Composition-neutral judge change: Nonmuslim defendants", size(small)) ytitle("Days since filing date") cluster(trans_group) 


graph combine nm_muslim_125 nm_nonmuslim_125 event_null_mus event_null_nm, title("Outcome: Days since filing date", size(medium)) ycommon
graphout r_event_delay, pdf

/******************************/
/* No. of cases seen in court */
/******************************/

preserve

drop if mi(decision_date)

/* generate no of cases seen in a court */
bys loc decision_date: gen case_count = _N

/* topcode case count variable */
sum case_count, d
replace case_count = . if case_count > `r(p95)'

/* label this outcome var */
la var case_count "No of cases decided in a court in a day"

rd case_count time_to_transition if nm_trans == 1 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(nm_muslim_125) title("Judge composition becomes more Muslim: Muslim defendants", size(small)) ytitle("# cases decided in a court in a day") cluster(trans_group) 

rd case_count time_to_transition if nm_trans == 1 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(nm_nonmuslim_125) title("Judge composition becomes more Muslim: Nonmuslim defendants", size(small)) ytitle("# cases decided in a court in a day") cluster(trans_group) 

rd case_count time_to_transition if nm_trans == 0 & mn_trans == 0 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_mus) title("Composition-neutral judge change: Muslim defendants", size(small)) ytitle("# cases decided in a court in a day") cluster(trans_group) 

rd case_count time_to_transition if nm_trans == 0 & mn_trans == 0 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_nm) title("Composition-neutral judge change: Nonmuslim defendants", size(small)) ytitle("# cases decided in a court in a day") cluster(trans_group) 

graph combine nm_muslim_125 nm_nonmuslim_125 event_null_mus event_null_nm, title("Outcome: # cases decided in a court in a day", size(medium)) ycommon
graphout r_event_case_count, pdf

restore

/***********************/
/* Punishment severity */
/***********************/

preserve

/* keep only IPC cases */
keep if !mi(number_sections_ipc)

/* now merge with our IPC sections dataset to bring in punishment */
gen section_ipc = section
merge m:1 section_ipc using $jdata/keys/ipc_section_key, keepusing(prison_ipc_mean) nogen keep(match)

/* label the punishment var */
la var prison_ipc "Years of prison associated with section"

rd prison_ipc_mean time_to_transition if nm_trans == 1 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(nm_muslim_125) title("Judge composition becomes more Muslim: Muslim defendants", size(small)) ytitle("Outcome severity") cluster(trans_group) 

rd prison_ipc_mean time_to_transition if nm_trans == 1 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(nm_nonmuslim_125) title("Judge composition becomes more Muslim: Nonmuslim defendants", size(small)) ytitle("Outcome severity") cluster(trans_group) 

rd prison_ipc_mean time_to_transition if nm_trans == 0 & mn_trans == 0 & def_muslim == 1 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_mus) title("Composition-neutral judge change: Muslim defendants", size(small)) ytitle("Outcome severity") cluster(trans_group) 

rd prison_ipc_mean time_to_transition if nm_trans == 0 & mn_trans == 0 & def_muslim == 0 & inrange(time_to_transition, -125, 125), bw  ///
    degree(2) xlabel(-125 (25) 125) $graphspec name(event_null_nm) title("Composition-neutral judge change: Non-muslim defendants", size(small)) ytitle("Outcome severity") cluster(trans_group) 

graph combine nm_muslim_125 nm_nonmuslim_125 event_null_mus event_null_nm, title("Outcome: Years of prison associated with offense", size(medium)) ycommon
graphout r_event_severity, pdf

restore

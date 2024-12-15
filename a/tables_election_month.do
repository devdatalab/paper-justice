/***********************************************************************************/
/* Examine whether ingroup religious judicial bias appears during election months  */
/***********************************************************************************/

/* start a timer  */
tgo //4.47 min

/**********************************************/
/* create a state-year-month election dataset */
/**********************************************/

/* load the data - this data is unique on eci_state_name sh_election_id year month */
use ~/iec/misc_data/elections/trivedi_elections_clean, clear

/* drop bye-elections */
drop if bye_election == 1

/* collapse by state year and month. A variable is required by collapse, but we only want the groups. */
gen x = 1
collapse (count) x, by(pc01_state_id year month)
drop x

/* get 2011 state ids from the pc01-11 state key */
merge m:1 pc01_state_id using $keys/pc0111_state_key, keepusing(pc11_state_id) keep(match master)
assert _merge == 3
drop _merge

/* specify the lag and lead election month variables here, where it will be easier */

/* create a row for every state-year-month group */
/* incredibly, there has never been an election in august, so we need to add an obs for this to work */
set obs `=_N + 1'
replace month = 8 if _n == _N

/* now do this filling in, so we get one obs for every year/month/state */
fillin year month pc11_state_id 

/* create an indicator for election months */
gen election_month = _fillin == 0
drop _fillin

/* set as a time series. To do this, we need a sequential month operator. */
sort year month
egen month_number = group(year month)
group pc11_state_id 
xtset sgroup month_number

/* create post- and pre-election month variables */
gen post_election_month = L.election_month
gen pre_election_month = F.election_month

/* rename the year var in preparation for merge */
ren year decision_year
ren month decision_month

/* drop things we don't need again */
drop pc01_state_id sgroup month_number

/* save state-year election data */
save $tmp/election_months, replace

/* chandigarh */
list if pc11_state_id == "04" & decision_month == 1 & inrange(decision_year, 2014, 2019)

/************************************************************************/
/* open justice analysis data and prepare for merging to election month */
/************************************************************************/

/* load the justice analysis dataset */
use $jdata/justice_analysis.dta, clear

/* drop some bulky vars to move this along */
drop name judge_desg judge_position ddl_case_id case_no cino act

/* get the pc11 state ids. Note we need to rename state and state_code --- this is an error
   in the build (since state_code doesn't match the key), but it's not a big deal and costly
   to trace through and fix. */
drop state_code
ren state state_code
merge m:1 state_code year using $jdata/keys/cases_state_key, keepusing(pc11_state_id) keep(match master)
assert _merge == 3
drop _merge

/* calculate decision year and month */
drop if mi(decision_date)
gen decision_year = year(decision_date)
gen decision_month = month(decision_date)

/* merge to election data */
merge m:1 pc11_state_id decision_year decision_month using $tmp/election_months, keep(match master) keepusing()
keep if _merge == 3
drop _merge
/* weird, no chandigarh in the election dataset. */

/* set the election window to 3 months around the election */
egen tmp = rowmax(election_month post_election_month pre_election_month)
replace election_month = tmp

/* generate interaction terms and label vars*/
gen def_nm_em = def_nonmuslim * election_month
la var def_nm_em "Non-Muslim defendant * election month"

gen judge_nm_em = judge_nonmuslim * election_month
la var judge_nm_em "Non-Muslim judge * election month"

gen bias_em = judge_def_nonmuslim * election_month
la var bias_em "Own religion bias * election month"
la var election_month "Election month"
la var judge_def_nonmuslim "Own religion bias"

/* save a working file */
save $tmp/justice_elections, replace


/***************************/
/* Run regressions here */
/***************************/

reghdfe acquitted def_nonmuslim judge_nonmuslim judge_def_nonmuslim election_month def_nm_em judge_nm_em bias_em, absorb(acts loc_year) cluster(judge)
eststo m1
estadd local FE "court-year"

/* column 2: restrict to cases where filing=deciding judge */
reghdfe acquitted def_nonmuslim judge_nonmuslim judge_def_nonmuslim election_month def_nm_em judge_nm_em bias_em if inrange(decision_date, tenure_start, tenure_end), absorb(acts loc_year) cluster(judge)
eststo m2
estadd local FE "court-year"


/* save the table to tex */
esttab m1 m2 using "$out/table_election_month.tex", replace label b(4) se(4) s(FE N, label("Fixed Effect" "Observations") fmt(0 0) ) drop(_cons) mtitles("Acquitted" "Acquitted") booktabs nostar nonote

/* stop a timer */
tstop

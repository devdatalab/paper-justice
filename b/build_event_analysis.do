/* append all years */
use $tmp/2010_event_complete, clear

forval yr = 2011/2018 {
  append using $tmp/`yr'_event_complete
}

/* drop heavy strings that we don't use */
drop judge_desg judge_position pet_name pet_adv def_name def_adv court_name district_name

/* Use program to create justice variables:
 - generate justice specific vars (outcomes, bail indicator) 
 - note the year variable should capture filing year to 
 - merge with purpose name, type name, and disposition name keys */
/* Need to use filing year to merge the other variables */
ren year decision_year
gen year = filing_year
create_justice_vars

/* keep only closed cases */
drop if mi(date_of_decision) | mi(decision_date)

/* create demographic dummy vars */
create_demo_dummy

/* keep sample frame */
keep if inrange(filing_year, 2010, 2018)

/* drop bail obs */
drop if bail == 1

/* generate fixed effect vars */
egen loc = group(state_code dist_code court)
egen loc_month = group(state_code dist_code court filing_year filing_month)
egen loc_year = group(state_code dist_code court filing_year)
egen acts = group(act section)

/* generate a transition size + direction, where positive = female */
gen f_transition_p = female_judge_share - female_judge_share_p
gen f_transition_n = female_judge_share_n - female_judge_share

/* generate a transition size + direction, where positive = muslim */
gen mus_transition_p = mus_judge_share - mus_judge_share_p
gen mus_transition_n = mus_judge_share_n - mus_judge_share

/* expand dataset in to 2 obs per row */
/* to separate previous and next transition and get them both in the dataset */
/* call this variable "left" because it indicates we are on the left side of the RD */
expand 2, gen(left)

/* note that left == 0 happens earlier in time, because the transition takes place *before*
   the case is heard.  So the case is to the right (left == 0) of the transition. */
gen     f_transition = f_transition_p if left == 0
replace f_transition = f_transition_n if left == 1

gen     mus_transition = mus_transition_p if left == 0
replace mus_transition = mus_transition_n if left == 1

/* generate time before/after transition */
gen     time_to_transition = date - date_start if left == 0
replace time_to_transition = date - date_end   if left == 1

/* for left side of RD: generate time between last transition and the one before it */
/* this is the next transition on the right side of the RD, and the prev on the left */
gen     outside_court_length = date_start - date_prev if left == 0

/* for left side of RD: generate time between next transition and the one after it */
replace outside_court_length = date_next - date_end   if left == 1

/* calc the length of time the current judge ends up in office */
gen current_court_length = date_end - date_start

/* drop if we can't measure these variables-- but we should understand why this happens */
drop if mi(current_court_length) | mi(outside_court_length) | mi(time_to_trans)

/* drop unnecessary vars */
drop f_transition_* mus_transition_* left group lower upper
// drop *_prev *_next
drop bailable_ipc year 

/* order dataset */
/* case details */
order ddl_case_id act section state_code state_name dist_code court 
/* outcomes */
order acquitted non_convicted delay topcoded_delay, after(court)
/* treatment */
order transitiondate date time_to_transition f_transition mus_transition outside_court_length current_court_length, after(topcoded_delay)
/* other details */
order def_* bail, after(current_court_length)

/* drop remaining unnecessary variables */
// drop court - disp_name

/* final labelling */
la var acquitted "Acquitted"
la var time_to_transition "Difference between transition date and decision/last hearing date"
la var f_transition "Change in female judge share upon transition"
la var mus_transition "Change in Muslim judge share upon transition"
la var outside_court_length "Court time length on other side of studied transition"
la var current_court_length "Total time length of court with current judges"
cap la var murder "Murder indicator"
cap la var women_crime "Crimes against women"

/* save dataset */
compress
save $jdata/justice_event_analysis, replace


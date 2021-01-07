/***** TABLE OF CONTENTS *****/
/* Merge judge-case data */
/* Format and save appended cleaned datasets for all years */
/* Inputs: $jdata/classification/cases_classified_[year], $jdata/judges_clean */
/* Outputs : $jdata/justice_analysis, $jdata/justice_event_analysis, $jdata/cases_all_years */


/****************************************************/
/* Save appended case data for all years separately */
/****************************************************/

use $jdata/classification/cases_classified_2010, clear

forval yr = 2011/2018{

  append using $jdata/classification/cases_classified_`yr'
}

duplicates drop
compress

save $jdata/cases_all_years, replace

/*************************/
/* Merge judge-case data */
/*************************/

/* loop over years */
forval yr = 2010/2018{

  /* bring in processed case data */
  use $jdata/classification/cases_classified_`yr', clear

  /* drop obs without a filing date - these cannot be used for a rangejoin */
  replace filing_date = . if filing_year < 2000
  drop if filing_date == .

  /* c_code in case data reflects court no in the judge data - rename before merge */  
  ren court_no court
  ren c_code court_no
  
  /* check pre judge-case match count */
  disp_nice "pre match `yr' count"
  count
  
  /* save case dataset for rangejoin */
  save $tmp/rj_case_`yr', replace
  
  /* bring in judge dataset */
  use $jdata/judges_clean, clear
  
  /* merge judge data with case data based on filing date, tenure of judge + IDs */
  rangejoin filing_date tenure_start tenure_end using $tmp/rj_case_`yr', by(state_code dist_code court_no position) 

  /* drop unmatched from using */
  drop if case_no == .

  /* drop unnecessary vars */
  drop *U

  /* final check for duplicates across all variables */
  duplicates drop

  /* check no. of obs */
  disp_nice "post-match:`yr'"
  count
  
  /* compress and save */
  compress
  save "$tmp/`yr'_case_complete.dta", replace 

} 

/***********************************/
/* Create final build for analysis */
/***********************************/

/* append data for all four years */
use $tmp/2010_case_complete, clear

forval y = 2011/2018{
  append using $tmp/`y'_case_complete
  }

/* prepare for analysis */
/* program defined in justice_programs.do */
prep_for_analysis

/* generate additional controls */
bys judge filing_year: gen case_load = _N
bys judge: egen mean_annual_case = mean(case_load)
gen tenure_length = tenure_end - tenure_start

/* label these */
la var mean_annual_case "Mean annual case load"
la var tenure_length "Tenure length"

/* finally, create an outcome for decision/no decision */
gen decision = 1 if !mi(decision_date)
replace decision = 0 if mi(decision_date)
la var decision "Whether the accused got a decision at all"

duplicates drop

/* drop unnecessary vars */
drop offense* bail_grant positive_* unclear_perc lm_gender lm_religion ly_gender ly_religion negative case_load court_no
drop cino case_no disp_name_raw disp_name type_name position *_ipc

/* order dataset */
/* case details */
order act section state_code dist_code court 
/* outcomes */
order decision acquitted non_convicted delay topcoded_delay, after(court)
/* demographics */
order judge_* def_*, after(topcoded_delay)
/* fixed effects and judge designation */
order loc loc_month loc_year loc_pos acts judge, after(def_male)
/* other case characteristics */
order person_crime-tenure_length bail, after(judge)
/* dates appear last - drop them as theyre not needed in analysis*/
drop date-first_hearing loc_pos

/* final labelling */
la var acquitted "Acquitted"
la var judge_def_male "Male judge and defendant"
la var judge_def_nonmuslim "Non-muslim judge and defendant"
la var loc_pos "Court-judge position fixed effect"
la var murder "Murder indicator"
la var women_crime "Crimes against women"
la var religion "Religious offense"

/* save dataset */
compress
save $jdata/justice_analysis, replace

/****************************************/
/* Prepare event study analysis dataset */
/****************************************/

/* match judge - court data within transition windows */
forval yr = 2010/2018{
  
  /* bring in processed case data */
  use $jdata/classification/cases_classified_`yr', clear  

  /* drop obs without a filing date - these cannot be used for a rangejoin */
  replace filing_date = . if filing_year < 2000
  drop if date == .

  /* we want to match on c_code not court_no in case - rename before merge */
  ren court_no court
  ren c_code court_no
  
  /* check pre judge-case match count */
  disp_nice "pre match `yr' count" 
  count

  /* save case dataset for rangejoin */
  save $tmp/rj_case_`yr', replace

  /* bring in judge data for rangejoin */
  use $tmp/courts_ts_rangejoin, clear

  /* rangejoin */
  rangejoin date date_start date_end using $tmp/rj_case_`yr', by(state_code dist_code court_no)

  /* drop unmatched from using */
  drop if case_no == .

  /* drop unnecessary vars */
  cap drop *U

  /* final check for duplicates across all variables */
  duplicates drop

  /* check no. of obs */
  disp_nice "post-match:`yr'"
  count

  /* compress and save */
  compress
  save "$tmp/`yr'_event_complete.dta", replace
  } 

/* append all years */
use $tmp/2010_event_complete, clear

forval yr = 2011/2018{
  append using $tmp/`yr'_event_complete
  }

/* drop duplicates */
duplicates drop

/* prep for analysis */
/* note: creates outcome variables, FEs etc */
/* defined in justice_progs.do */
prep_for_analysis_event

/* keep sample frame */
keep if inrange(filing_year, 2010, 2018)

/* generate a transition size + direction, where positive = female */
gen f_transition_p = female_judge_share - female_judge_share_p
gen f_transition_n = female_judge_share_n - female_judge_share

/* generate a transition size + direction, where positive = muslim */
gen mus_transition_p = mus_judge_share - mus_judge_share_p
gen mus_transition_n = mus_judge_share_n - mus_judge_share

/* expand dataset in to 2 obs per row */
/* to separate previous and next transition */
/* call this variable "left" because it indicates we are on the left side of the RD */
expand 2, gen(left)

gen     f_transition = f_transition_p if left == 0
replace f_transition = f_transition_n if left == 1

gen     mus_transition = mus_transition_p if left == 0
replace mus_transition = mus_transition_n if left == 1

/* generate time before/after transition */
gen     time_to_transition = date - date_start if left == 0
replace time_to_transition = date - date_end   if left == 1

/* for left side of RD: generate time between last transition and the one before it */
/* this is the next transition on the right side of the RD, and the prev on the left */
gen     nextprev_trans_time = date_start - date_prev if left == 0

/* for left side of RD: generate time between next transition and the one after it */
replace nextprev_trans_time = date_next - date_end   if left == 1

/* calc the length the current judge ends up in office */
gen current_judge_tenure = date_end - date_start

/* drop if we can't measure these variables-- but we should understand why this happens */
drop if mi(current_judge_tenure) | mi(nextprev_trans_time) | mi(time_to_trans)

/* drop unnecessary vars */
drop offense* bail_grant positive_* unclear_perc  negative  court_no
drop f_transition_* mus_transition_* left group lower upper
drop date_start-date_next
drop *_prev *_next *_p *_n
drop cino case_no disp_name_raw disp_name type_name *_ipc year *judges *judge_share*

/* order dataset */
/* case details */
order act section state_code state_name dist_code court 
/* outcomes */
order acquitted non_convicted delay topcoded_delay, after(court)
/* treatment */
order transitiondate date time_to_transition f_transition mus_transition nextprev_trans_time current_judge_tenure, after(topcoded_delay)
/* other details */
order def_* bail, after(current_judge_tenure)
/* fixed effects */
order loc-religion, before(decision_date)
order loc_year, after(loc_month)

/* drop remaining unnecessary bulky date variables */
drop decision_date - first_hearing

/* final labelling */
la var acquitted "Acquitted"
la var time_to_transition "Difference between transition date and decision/last hearing date"
la var f_transition "Change in female judge share upon transition"
la var mus_transition "Change in Muslim judge share upon transition"
la var nextprev_trans_time "Time between subsequent transitions (before or after)"
la var current_judge_tenure "Tenure of current judge"
la var murder "Murder indicator"
la var women_crime "Crimes against women"

/* save dataset */
compress
save $jdata/justice_event_analysis, replace


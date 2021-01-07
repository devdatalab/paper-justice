/* This do file creates a court level dataset */
/* suitable for the event study analysis */

/* import clean judge dataset */
use $jdata/judges_clean, clear

/* create court id */
egen court = group(state_code dist_code court_no)

/* keep only the basic court and judge identifiers-- goal is just to count number of
   non-muslim and muslim judges in the court at any time. */
keep court state_code dist_code court_no muslim_class female_class tenure* position

/* fill in the dataset so each court is observed on each date */
expand 2, gen(new)
gen     date = tenure_start if new == 0
replace date = tenure_end if new == 1

/* on any given date, count the number of judges with the same court number
   who were present on that date. */
sort court date
gen row = _n
foreach v in judges mus_judges nm_judges female_judges male_judges {
  gen num_`v' = 0
}
label drop female_class
label drop muslim_class
timer clear
timer on 1
count
local n = `r(N)'
qui forval i = 1/`n' {

  if mod(`i', 100) == 1 noi di %5.1f (`i'/`n'*100) "%"
  
  /* count number of judges in the court/date indicated by row i */
  count if court == court[`i'] & inrange(date[`i'], tenure_start, tenure_end)
  replace num_judges = num_judges + `r(N)' / 2 if row == `i'

  /* count muslim judges in the court/date indicated by row i */
  count if court == court[`i'] & inrange(date[`i'], tenure_start, tenure_end) & muslim == 1
  replace num_mus_judges = num_mus_judges + `r(N)' / 2 if row == `i'

  /* count number of non-muslim judges in the court/date indicated by row i */
  count if court == court[`i'] & inrange(date[`i'], tenure_start, tenure_end) & muslim == 0
  replace num_nm_judges = num_nm_judges + `r(N)' / 2 if row == `i'

  /* repeat for male/female */
  count if court == court[`i'] & inrange(date[`i'], tenure_start, tenure_end) & female == 1
  replace num_female_judges = num_female_judges + `r(N)' / 2 if row == `i'

  /* count number of non-muslim judges in the court/date indicated by row i */
  count if court == court[`i'] & inrange(date[`i'], tenure_start, tenure_end) & female == 0
  replace num_male_judges = num_male_judges + `r(N)' / 2 if row == `i'
}
timer off 1
timer list

drop row
format date %d

/* save the raw data for inspection */
save $tmp/courts_numbers, replace

/* keep necessary vars */
keep state_code dist_code court_no date num* 

/* collapse to court level */
duplicates drop
save $tmp/court_ts, replace

/* import court level data */
use $tmp/court_ts, clear

/* drop erroneous obs */
drop if num_judges == 0

/* create group for court */
egen group = group(state_code dist_code court_no)

/* create upper and lower variables (transition window) */
gen lower = date - 175
gen upper = date + 175
format lower upper %td

/* label variables */
la var lower "Transition - 25 weeks"
la var upper "Transition + 25 weeks"

/* sort */
sort group date

/* generate share variables */
foreach i in mus nm male female{
  gen `i'_judge_share = num_`i'_judges/num_judges 
}

/* create date start variable */
gen date_start = date

/* create date end variable */
gen date_end = date_start[_n+1] - 1 if group[_n+1] == group[_n]

/* create date previous variable */
gen date_prev = date_start[_n-1] if group[_n-1] == group[_n]

/* create date next variable */
gen date_next = date_end[_n+1] if group[_n+1] == group[_n]

/* format all date vars */
format date* %td

/* values of number of judges in previous and next rows */
foreach x of var num*{
  gen `x'_prev = `x'[_n-1] if group[_n-1] == group[_n]
  gen `x'_next = `x'[_n+1] if group[_n+1] == group[_n]
  }

/* values of share of judges in previous and next row */
foreach x of var *share{
  gen `x'_p = `x'[_n-1] if group[_n-1] == group[_n]
  gen `x'_n = `x'[_n+1] if group[_n+1] == group[_n]
  }

/* label all variables */
do $jcode/b/label_courts_ts_rangejoin

/* save dataset */
save $tmp/courts_ts_rangejoin, replace

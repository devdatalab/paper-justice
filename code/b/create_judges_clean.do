/***** TABLE OF CONTENTS *****/
/* Bring in raw judge data with classified demographic + extracted court no */
/* Clean court number */
/* Clean dates */
/* Clean judge_desg, and split into position and location */
/* Check for overlap in tenure of judges in the same court  */
/* Final cleaning */
/* Save judge data keys */

/* import dataset */
use $jdata/classification/judge_names_classified, clear

/******************/
/* clean court no */
/******************/
replace court_no = subinstr(court_no, "-", "", .)

/* remove letters from court no */
egen _temp = sieve(court_no), char( 0123456789 )

/* save proper court number with no letters */
drop court_no
ren _temp court_no

/* convert into numeric character */
destring court_no, replace

/* drop if court number is missing */
drop if mi(court_no)

/***************/
/* clean dates */
/***************/

/* isolate the year, month, and day of the starting date */
gen low_year = substr(start, -4, 4)
gen low_month = substr(start, 4, 2)
gen low_day = substr(start, 1, 2)

/* convert dates to integers */
destring low_year low_month low_day, replace

/* compile month, day, and year into a numerical time counter */
gen tenure_start = mdy(low_month, low_day, low_year)

/* isolate the year, month, and day of the ending date */
gen high_year = substr(end, -4, 4) 
gen high_month = substr(end, 4, 2) 
gen high_day = substr(end, 1, 2) 

/* convert dates to integers */
destring high_year high_month high_day, replace 

/* compile month, day, and year into a numerical time counter */
gen tenure_end = mdy(high_month, high_day, high_year) 

/* replace missing dates with the last day in 2019 */
replace tenure_end = mdy(12,31,2019) if tenure_end == . 
drop if tenure_start == .

/* format date variables */
format tenure_start tenure_end %td

/* drop intermediate date variables */
drop high* low*

/* removing judges whose tenure is a single day only */
gen temp = tenure_end - tenure_start
drop if temp <= 0

/*******************************/
/* Harmonize judge designation */
/*******************************/

/* generate judge designation */
gen judge_desg = lower(desg_info)
	
/* trim spaces */
replace judge_desg = itrim(trim(judge_desg))

/* perserve raw judge_desg variable */
gen judge_desg_raw = judge_desg

/* name clean judge designation */
name_clean judge_desg, replace

/* run desgformat */
desgformat

/************************************************************/
/* Check for overlap in tenure of judges in the same court  */
/************************************************************/

/* format tenure start and end */
format tenure_start tenure_end %td

/* first, keep unique obs on state, dist, court no, position and tenure */
duplicates tag state_code dist_code court_no position tenure_start tenure_end, gen(tag)
keep if tag == 0
drop tag

/* check for tenure overlap */
check_overlap

/* check no. flagged */
tab flag, mis
/* 83% of the data */

/* save intermediate judge data */
save $tmp/judge_intermediate_working, replace

/* keep obs unique in tenure */
keep if flag == .
count

/******************/
/* Final cleaning */
/******************/

/* format codes for merge with case data */
destring state_code, replace
tostring state_code dist_code, replace format(%2.0f)
tostring court_no, replace format(%4.0f)

/* drop unnecessary vars */
drop diff flag group pos1 honoraries judge_desg temp desg desg_info roman no female

/* rename position */
ren position1 position

/* order vars */
order state_code dist_code court_no, first
order judge_desg_raw position *class tenure* start end, after(court_no)

/* label variables */
la var court_no "Court number"
la var judge_desg_raw "Raw judge designation"
la var position "Formatted judge designation"
la var tenure_start "Formatted tenure start date"
la var tenure_end "Formatted tenure end date"

/* save clean dataset */
save $jdata/judges_clean, replace


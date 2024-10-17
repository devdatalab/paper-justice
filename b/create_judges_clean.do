/***** TABLE OF CONTENTS *****/
/* Bring in judge demographics from classified name output */
/* clean court number */
/* clean dates */
/* Clean judge_desg, and split into position and location */
/* Check for overlap in tenure of judges in the same court  */
/* Final cleaning */
/* Save judge data keys */

/* import raw data */
use $jdata/classification/judges_clean_names.dta, clear

/* drop unnecessary variables */
drop html_values v1 

/* convert state code to string */
tostring state_code, format("%02.0f") replace 

/***********************************************************/
/* Bring in judge demographics from classified name output */
/***********************************************************/

/* drop observations with no names */
drop if name == ""

/* merge in muslim classifier */
merge m:1 name using $jdata/classification/judges_clean_muslim_class, keepusing(muslim_class)

/* manual classification of unclassified judges */
foreach fragment in warud ahmad haider habibullah hamza hasan ansari jamal javed jawed mohammed mohammad niyaz quamrul syed waseem zeenat {
  replace muslim_class = 1 if _merge == 1 & regexm(name, "`fragment'") == 1
}

replace muslim_class = 1 if _merge == 1 & regexm(name, "md ") == 1
replace muslim_class = 1 if _merge == 1 & regexm(name, "w a khan") == 1

/* flag bad names so that we dont classify them */
foreach x in list senior cadre dummy judicial magistrate prl special spl vcant {
  replace muslim_class = 99 if _merge == 1 & regexm(name, "`x'") == 1
  }

foreach x in new nil vc x{
  replace muslim_class = 99 if _merge == 1 & name == "`x'"
}

replace muslim_class = 99 if name == " iv" 
replace muslim_class = 99 if name == " va"
replace muslim_class = 99 if name == "po a d j"
replace muslim_class = 99 if name == "st    j d"
replace muslim_class = 99 if name == "   s d"

replace muslim_class = 0 if _merge == 1 & muslim_class == .
replace muslim_class = .  if muslim_class == 99

/* drop merge */
drop _merge

/* merge in gender classifier */
merge m:1 name using $jdata/classification/judges_clean_female_class, keepusing(female_class female)

/* fix classification of names that are in master only */
replace female_class = 0 if _merge == 1 & regexm(name, "kumari") == 0
replace female_class = 1 if _merge == 1 & female_class == .
replace female_class = 1 if draft_female == 1
replace female_class = 0 if draft_female == 0
replace female_class = . if regexm(name, "xxxxxxxxxxx") == 1

/* drop merge */
drop _merge

/***************************************************************************/
/* Incorporate manual corrections to names that were classified as unclear */
/***************************************************************************/

/* merge in correction */
merge m:1 name using $jdata/classification/muslim_judges_corrected, nogen

/* rename corrected var */
ren corrected m_corrected

/* merge in gender corrections */
merge m:1 name using $jdata/classification/female_judges_corrected, nogen

/* rename corrected var */
ren corrected f_corrected

/* correct muslim class */
replace muslim_class = m_corrected if !mi(m_corrected) & muslim_class < 0
replace female_class = f_corrected if !mi(f_corrected) & female_class < 0

/* drop corrected variable */
drop *corrected

/* correct non-muslim judges incorrectly classified as muslim */
do $jcode/b/judge_corrections.do

/*********************/
/* clean court number */
/*********************/

/* extract court number from name_info */
gen court_no = substr(name_info, 1, 3)

/* save intermediate classified judge name dataset */
save $jdata/classification/judge_names_classified, replace

/* clean court no */
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

/******************/
/* Final cleaning */
/******************/

/* format codes for merge with case data */
destring state_code, replace
tostring state_code dist_code, replace format(%2.0f)
tostring court_no, replace format(%4.0f)

/* drop unnecessary vars */
drop draft* after_comma bracket_term non_names 
drop  group pos1 honoraries judge_desg temp desg desg_info roman no

/* rename position */
ren position1 judge_position

/* order vars */
order state_code dist_code court_no name_info name, first
order judge_desg_raw judge_position *class tenure* start end, after(name)

/* check distribution of demographics in clean judge dataset */
tab female_class, mis
tab muslim_class, mis

/* create judge id */
gen ddl_judge_id = _n

/* label variables */
la var state_code "State code"
la var dist_code "District code"
la var court_no "Court number"
la var judge_desg_raw "Raw judge designation"
la var judge_position "Formatted judge designation"
la var tenure_start "Formatted tenure start date"
la var tenure_end "Formatted tenure end date"
la var start "Tenure start date"
la var end "Tenure end date"
la var female_class "Judge gender classification"

/* save intermediate judge data */
save $jdata/judges_clean_public, replace

/* keep obs unique in tenure */
keep if flag == .
count
drop flag diff

/* save clean dataset */
save $jdata/judges_clean, replace

/************************/
/* Save judge data keys */
/************************/

/* court key */
bys state_code dist_code court_no: keep if _n == 1

/* keep necessary vars */
keep state_code dist_code court_no

/* save court key */
save $jdata/keys/j_court_key, replace

/* district key */
bys state_code dist_code: keep if _n == 1

/* keep necessary vars */
keep state_code dist_code

/* save district key */
save $jdata/keys/j_district_key, replace

/* state key */
bys state_code: keep if _n == 1

/* keep necessary vars */
keep state_code

/* save state key */
save $jdata/keys/j_state_key, replace

/* position key */
use $jdata/judges_clean, clear

/* make data unique */
bys judge_position: keep if _n == 1
keep judge_position

/* save position key */
save $jdata/keys/j_position_key, replace

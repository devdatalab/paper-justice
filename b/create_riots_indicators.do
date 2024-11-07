/*********************************************************************************/
/* this dofile uses ACLED religious violence data to create indicators of riots  */
/*********************************************************************************/

/****************************************************************************/
/* part 1: clean up district keys (used to merge case data with riot data)  */
/****************************************************************************/

/* EI: iec/justice/keys/cases_district_key does not uniquely identify obs. at the state-district level.
 This affects only 4 observations, whose strings are causing duplicates, ex. "Jaipur Metro" vs "Jaipur Metro I"
 Create new keys - unique at the state_code - dist_code level, which are then merged with justice_analysis data
*/

/* open the justice district keys dataset */
use $jdata/keys/cases_district_key, clear

/* drop duplicates -- only 2 observations should be deleted here */
duplicates drop state_code dist_code, force

/* destring dist_code to match formatting in justice data */
destring dist_code, replace

/* save new keys in temp for now */
save $tmp/justice_district_key, replace

/*********************************************************************************/
/* part 2: merge case data to district keys and prepare for merge with riot data */
/*********************************************************************************/

/* open the justice data */
use $jdata/justice_analysis, clear

/* format state var to be consistent with keys for merge  */
cap drop state_code
ren state state_code

/* rename district var to merge with keys */
ren district_code dist_code

/* merge with district key to get pc11 district IDs */
merge m:1 state_code dist_code using $tmp/justice_district_key, gen(jdistricts) keep(master match)

/* keep only vars of interest for rangejoin testing purposes */
keep ddl_case_id *state* *district* *date 

/* save subsample of cases and variables in temp */
save $tmp/justice_analysis_cases, replace

/********************************************************************/
/* part 3: create riot date variables and rangejoin with case data  */
/********************************************************************/

/* load raw ACLED data  */
import delimited using $jdata/raw/ACLED_India_violence_2005-2023.csv, clear varnames(1)

/* keep only justice relevant years */
keep if inrange(year, 2015, 2018)

/* fix var naming */
ren event_id_cnty event_id

/* save subset of data to map to districts */
preserve

/* save geo data */
keep event_id admin* location lat longitude
save $tmp/acled_geo_vars, replace

/* map lat/lon to pc11_district_id billy write $jdata/acled_districts.dta */
/* NOTE: THIS ONLY WORKS IN PY-SPATIAL */
// python script $jcode/b/merge_acled_geo_districts.py

/* restore full dataset to create vars of interest */
restore

/* make all strings uniformly lowercase so regexm doesn't miss events due to case sensitivity */
foreach v in actor1 actor2 assoc_actor_1 assoc_actor_2 notes {
  replace `v' = lower(`v')
}


/* create identifier for riots involving Hindu groups */
gen hindu = regexm(actor1, "hindu|temple|mandir|ganesha|shiva|ram") |       ///
    regexm(actor2, "hindu|temple|mandir|ganesha|shiva|ram") |              ///
    regexm(assoc_actor_1, "hindu|temple|mandir|ganesha|shiva|ram") |     ///
    regexm(assoc_actor_2, "hindu|temple|mandir|ganesha|shiva|ram") |     ///
    regexm(notes, "hindu|temple|mandir|ganesha|shiva|ram") 

/* create identifier for riots involving Muslum groups */
gen muslim = regexm(actor1, "muslim|mosque|masjid|minaret|islam|eid") |    ///
    regexm(actor2, "muslim|mosque|masjid|minaret|islam|eid") |            ///
    regexm(assoc_actor_1, "muslim|mosque|masjid|minaret|islam|eid") |    ///
    regexm(assoc_actor_2, "muslim|mosque|masjid|minaret|islam|eid") |   ///
    regexm(notes, "muslim|mosque|masjid|minaret|islam|eid") 

/* create identifier for events mentioning "Cow" (or synonyms)  */
gen cow = regexm(actor1, "cow|beef|gau|raksha|gaumata") |        ///
    regexm(actor2, "cow|beef|gau|raksha|gaumata")  |            ///
    regexm(assoc_actor_1, "cow|beef|gau|raksha|gaumata") |     ///
    regexm(assoc_actor_2, "cow|beef|gau|raksha|gaumata") |    ///
    regexm(notes, "cow|beef|gau|raksha|gaumata") 

/* create identifier for any event involving the BJP */
gen bjp = regexm(actor1, "bjp|bharatiya janata party|modi") |        ///
    regexm(actor2, "bjp|bharatiya janata party|modi") |             ///
    regexm(assoc_actor_1, "bjp|bharatiya janata party|modi") |     ///
    regexm(assoc_actor_2, "bjp|bharatiya janata party|modi") |    ///
    regexm(notes, "bjp|bharatiya janata party") 

/* create 1st indicator for religious riots, defined as all events involving Hindus and Muslims */
gen religious_riot1 = (hindu == 1) & (muslim == 1)

/* create 2nd indicator for religious riots, adding all BJP events and "Cow"-related events  */
gen religious_riot2 = (religious_riot1 == 1) | (bjp == 1) | (cow == 1)

/* gen 3rd religious riot var, defined as religious riot 1 + at least 1 fatality  */
gen religious_riot3 = (religious_riot1 == 1) & (fatalities > 0)

/* gen 4rd religious riot var, defined as religious riot 2 + at least 1 fatality  */
gen religious_riot4 = (religious_riot2 == 1) & (fatalities > 0)

/* export subsample to manually check indicators of events  */
export excel $tmp/riot_validation_sample.xlsx if religious_riot2 == 0 & runiform() < 50 / _N, firstrow(var) replace

/* save data in temp to validate indicators  */
save $tmp/riot_definitions, replace

/*  clean up district names to validate */
replace admin2 = strlower(admin2)

/* name admin2 pc11_district_name to clean up district names */
ren (admin1 admin2)  (acled_state_name pc11_district_name)

/* fix strings */
fix_place_names, place(district) year(11)

/* change name back to not confuse with shrug pc11_district_name  */
ren pc11_district_name acled_district_name

/* switch back to uppercase */
replace acled_district_name = strproper(acled_district_name)

/* merge with acled data containing districts */
merge 1:1 event_id using $jdata/acled_districts

/* rename shrug vars */
ren (pc11_s_id pc11_d_id d_name) (pc11_state_id pc11_district_id district_name)

/* keep only riots  */
keep if religious_riot1 == 1 |  religious_riot2 == 1 | religious_riot3 == 1 | religious_riot4 == 1

/* convert event date from string to date format */
gen year2 = substr(event_date, -2, .)
replace event_date = substr(event_date, 1, length(event_date) - 2)
gen year1 = "20"
gen date = event_date + year1 + year2
gen riot_date = date(date, "DMY")
format riot_date %td
drop date

/* state - district - riot date doesn't uniquely identify obs  */
drep pc11_state_id pc11_district_id riot_date

/* calc total fatalities in districts with multiple events in same date-district  */
bys pc11_state_id pc11_district_id riot_date: egen tot_fatalities = total(fatalities)

/*  count nr of riots in districts with multiple events in same date-district */
forval i = 1/4 {
  bys pc11_state_id pc11_district_id riot_date: egen tot_riot`i' = total(religious_riot`i') if religious_riot`i' != .
}

/* drop duplicates to be able to merge to justice data down the line  */
duplicates drop pc11_state_id pc11_district_id riot_date, force

/* keep only vars of interest */
keep event_id riot_date year assoc_actor* acled_state_name acled_district_name notes ///
fatalities religious_riot* hindu muslim cow bjp pc11* district_name 

/* create date var for end of week after riot  */
gen riot_week = riot_date + 7

/* create date var for month after riot */
gen riot_month = riot_date + 30

/* format new vars as date vars */
format riot_week %td
format riot_month %td

/* save riot data with weekly/monthly date vars in tmp */
save $tmp/riots, replace

/* join riot data with all cases falling within week after riot window within state-district */
rangejoin filing_date riot_date riot_month using $tmp/justice_analysis_cases, by(pc11_state_id pc11_district_id)

/* save merged datasets before making unique at case level */
save $tmp/rangejoin_result, replace

/* loop over religious riot indicators to create week/month-after indicators if filing date is inrange of riot and end of week/month dates */
forval i = 1/4 {

  /* create indicator for cases being filed during week after riot takes place  */
  gen week_after_riot`i' = religious_riot`i' if inrange(filing_date, riot_date, riot_week)

  /* create indicator for cases being filed during month after riot takes place  */
  gen month_after_riot`i' = religious_riot`i' if inrange(filing_date, riot_date, riot_month)

}

/* replace missing values with 0s to keep indicator categories consistent  */
forval i = 1/4 {

  /* loop over week and month */
  foreach t in week month {
    
    /* fix missing values in week/month after riot indicators */
    replace `t'_after_riot`i' = 0 if `t'_after_riot`i' == .

  }
}

/* drop obs with missing filing dates  */
drop if mi(filing_date)

/* save in tmp until decision on operation below is final */
save $tmp/cases_non_unique_riots, replace

/* EI: this data is not unique at the case id level because when the filing date falls between the
weekly or monthly window for multiple riots, rangejoin creates multiple copies of it.
 Importantly, the riot indicators might take on different values, depending on the riot definition.
 For the purposes of our analysis, we only case about flagging whether the case was filed during the week/month
 following *any* riot, so first make sure to keep the 'version' of the same case with riot indicator = 1 instead of 0,
and then drop duplicates for those that have the same indicator value */

/* first, make sure to identify cases following *any* riot */
/* loop over all riot definitons */
forval i = 1/4 {

  /* loop over week/month indicators */
  foreach t in week month {
    
    /* create aux. vars to identify total riots taking place after a case is filed */
    /* these variables will be the same for all obs within a case, so we don't lose info when dropping */
    bys ddl_case_id: egen max_`t'_riot`i' = max(`t'_after_riot`i')
    drop `t'_after_riot`i'
    ren max_`t'_riot`i' `t'_after_riot`i'
  }
}

/* drop case duplicates - note: stata will randomly decide which obs to keep as unique copy */
duplicates drop ddl_case_id, force

/* keep only vars of interest and those needed to merge with justice data */
keep ddl_case_id riot* week* month* religious_riot* notes

/* save riots data to merge with justice data later in analysis */
save $jdata/acled_religious_violence, replace

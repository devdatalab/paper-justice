/**************************************************/
/* builds the central judicial bias analysis file */
/**************************************************/

/* to use less space, shrink datasets before loading */
forval yr = 2010/2018 {
  use $jdata/cases_clean_`yr', clear

  /* drop unused variables */
  drop pet_name date_next_list date_last_list date_first_list date_of_decision date_of_filing

  /* restrict to criminal cases */
  keep if criminal == 1

  /* save shortened database */
  save $tmp/cases_clean_`yr'_tmp, replace
}

/* append data for all years */
use $tmp/cases_clean_2010_tmp, clear

forval yr = 2011/2018 {
  append using $tmp/cases_clean_`yr'_tmp
}

/* drop if we don't observe defendant name */
drop if mi(def_name)

/* encode some other string variables to make the dataset smaller */
foreach v in judge_desg judge_position state_name district_name court_name {
  encode `v', gen(`v'_code)
  drop `v'
}

/* merge with filing judge details  */
gen ddl_judge_id = ddl_filing_judge_id

/* merge with judge data */
merge m:1 ddl_judge_id using $jdata/judges_clean, keep(master match) gen(judge_merge) keepusing(muslim_class female_class tenure*)

/* generate crime types */
gen_crime_types

/* generate justice specific vars (outcomes, bail indicator) */
create_justice_vars

/**************************/
/* clean the lawyer names */
/**************************/
foreach name in pet_adv def_adv {

  /* run basic cleaning steps (PN: don't change the order of these, or you may
     create mismatches with $jcode/b/csv/lawyer_non_names.csv. Verify if any
     changes are made. */
  replace `name' = subinstr(`name', ".", "", .)
  replace `name' = lower(`name')
  name_clean `name', replace
  
  /* drop names that are less than 6 characters) */
  replace `name' = "" if strlen(subinstr(`name', " ", "", .)) <= 5

}

/* save all criminal case data for summary statistics of all cases*/
save $jdata/cases_all_years, replace

/* now only keep cases we could match with judge data */
keep if judge_merge == 3
drop judge_merge

/* drop long string lawyer names, which are mostly not needed and can be pulled back from cases_all_years */
drop pet_adv def_adv

/* rename def_name in a form for merging to the clean name list */
gen name_original = lower(def_name)
drop def_name

/*******************************************/
/* create some additional useful variables */
/*******************************************/

/* create demographic dummy vars */
create_demo_dummy

/* create interaction vars for rct */
gen judge_def_female = judge_female * def_female
gen judge_def_muslim = judge_muslim * def_muslim
gen judge_def_male = judge_male * def_male
gen judge_def_nonmuslim = judge_nonmuslim * def_nonmuslim
gen judge_men_def_nm = judge_male * def_nonmuslim
gen judge_nm_def_men = judge_nonmuslim * def_male

/* generate variables to keep reghdfe the same style */
gen def_adv_male = 1 - def_adv_female
gen pet_adv_male = 1 - pet_adv_female
gen def_adv_nonmuslim = 1 - def_adv_muslim
gen pet_adv_nonmuslim = 1 - pet_adv_muslim

/* generate interaction terms needed for tables_rct_lawyers */
gen judge_def_adv_male = judge_male * def_adv_male
gen judge_pet_adv_male = judge_male * pet_adv_male
gen judge_def_adv_nonmuslim = judge_nonmuslim * def_adv_nonmuslim
gen judge_pet_adv_nonmuslim = judge_nonmuslim * pet_adv_nonmuslim

/* label vars */
la var judge_def_female "Female judge and defendant"
la var judge_def_muslim "Muslim judge and defendant"
la var judge_def_male "Male judge and defendant"
la var judge_def_nonmuslim "Non-Muslim judge and defendant"
la var judge_men_def_nm "Male judge with non-Muslim defendant"
la var judge_nm_def_men "Non-Muslim judge with male defendant"
la var judge_female "Female judge"
la var judge_muslim "Muslim judge"
la var def_female   "Female defendant"
la var def_muslim   "Muslim defendant"

la var judge_male "Male judge"
la var def_male "Male defendant"
la var judge_nonmuslim "Non-Muslim judge"
la var def_nonmuslim "Non-Muslim defendant"
la var def_adv_male "Male advocate of defendant"
la var pet_adv_male "Male advocate of petitioner"
la var def_adv_nonmuslim "Non-Muslim advocate of defendant"
la var pet_adv_nonmuslim "Non-Muslim advocate of petitioner"
la var judge_def_adv_male "Male judge and advocate of defendant"
la var judge_pet_adv_male "Male judge and advocate of petitioner"
la var judge_def_adv_nonmuslim "Non-Muslim judge and advocate of defendant"
la var judge_pet_adv_nonmuslim "Non-Muslim judge and advocate of petitioner"

/* generate fixed effect vars */
egen loc_month = group(state district court_no filing_year filing_month)
egen loc_year = group(state district court_no filing_year)
egen acts = group(act section)
egen judge = group(state district court_no judge_position tenure_start tenure_end)

/* label newly created variables */
la var acts "act section fixed effect"
la var loc_month "court-year-month fixed effect"
la var loc_year "court-year fixed effect"
la var judge "judge fixed effect"

/* drop duplicates before dropping case identifiers */
/* EI: rendundant code? this drops 0 obs (sounds right, why would we drop duplicates after creating FEs)*/
duplicates drop

/* save bail cases separately for bail analysis */
savesome if bail == 1 using $jdata/justice_bail_analysis, replace

/* drop bail cases */
drop if bail == 1

/* remove minority of plea bargained outcomes which didn't make it to trial */
merge m:1 year disp_name using $jdata/keys/disp_name_key, keepusing(disp_name_s) keep(match master) nogen

/* this drops ~ 33,45K obs */
drop if disp_name_s == "plea bargaining"
drop disp_name_s

/*********************************/
/* deal with nonindividual names */
/*********************************/

/* merge with dataset that has nonindividual name indicator */
/* we also pull "name" -- unfortunately it seems like we have different versions of names in 
   different datasets, and this one is the one needed for build_lastname_analysis.do */
merge m:1 name_original using $jdata/classification/pooled_names_clean_appended, keepusing(nonindividual name) keep(master match) nogen

/* drop nonindividual names */
drop if nonindividual == 1

/* drop heavy strings that we don't use again */
drop nonindividual name_original 

/****************/
/* save dataset */
/****************/
compress
save $jdata/justice_analysis, replace

/********************************************************************/
/* steps in the build mirroring the sample accounting in figure A3  */
/********************************************************************/

/* append clean data for all years */
/* starting point = ~ 24.51 million obs */
use $tmp/cases_clean_2010_tmp, clear

forval yr = 2011/2018 {
  append using $tmp/cases_clean_`yr'_tmp
}
save $tmp/cases_combined, replace

/* drop if we don't observe defendant name */
/* this drops ~ 31K obs */
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

/* create crime category var */
// replace crime_category = "sexual assault" if sexual_assault == 1 
// replace crime_category = "violent crime" if violent_crime == 1
// replace crime_category = "theft/dacoity" if theft_dacoity == 1
// replace crime_category = "disturbing public safety" if peace == 1
// replace crime_category = "marriage offense" if marriage_offenses == 1
// replace crime_category = "petty theft" if petty_theft == 1
// replace crime_category = "person crime" if person_crime == 1
// replace crime_category = "property_crime" if property_crime == 1
// replace crime_category = "murder" if murder == 1
// replace crime_category = "other crime against women" if women_crime == 1
// replace crime_category = "other" if other_crime == 1
// replace crime_category = "missing offense" if offenses == .


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

/* save all criminal case data for summary statistics of all cases */
/* smaple size = ~ 23.2 million obs */
save $tmp/all_cases, replace

/*  only keep cases we could match with judge data */
/* drops ~ 13 million obs */
keep if judge_merge == 3
drop judge_merge

/* drop long string lawyer names, which are mostly not needed and can be pulled back from cases_all_years */
drop pet_adv def_adv

/* rename def_name in a form for merging to the clean name list */
gen name_original = lower(def_name)
drop def_name

/* create demographic dummy vars */
create_demo_dummy

/* sample size = ~ 10 million obs */
/* drop bail cases = ~ 1.54 million obs */
drop if bail == 1

/* sample size = ~ 8.5 million obs */
/* remove minority of plea bargained outcomes which didn't make it to trial */
merge m:1 year disp_name using $jdata/keys/disp_name_key, keepusing(disp_name_s) keep(match master) nogen

/* this drops ~ 33.45K obs */
drop if disp_name_s == "plea bargaining"
drop disp_name_s

/* merge with dataset that has nonindividual name indicator */
/* we also pull "name" -- unfortunately it seems like we have different versions of names in 
   different datasets, and this one is the one needed for build_lastname_analysis.do */
merge m:1 name_original using $jdata/classification/pooled_names_clean_appended, keepusing(nonindividual name) keep(master match) nogen

/* save cases concerning nonindividual defendants for closer inspection */
savesome if nonindividual == 1 using $tmp/justice_nonindividual_cases, replace

/* sample size =  */
/* drop nonindividual names = ~ 1.67 million obs */
drop if nonindividual == 1

/* drop heavy strings that we don't use again */
drop nonindividual name_original 

/* save analysis dataset (~X million obs) */
compress
save $tmp/justice_analysis_equivalent, replace

/* show characteristics of places that drop from sample because Muslim or female are unclassifiable */
use $tmp/justice_analysis_equivalent, clear

/* generate an indicator for being in both religion and gender samples */
gen in_sample = !mi(judge_muslim) & !mi(judge_female) & !mi(def_muslim) & !mi(def_female)

/* count the number of cases in each state (to cut small states out of the state table) */
bys state_name_code: egen state_count = count(in_sample)

table crime_category in_sample
tabstat in_sample if state_count > 50000, s(mean n) by(state_name_code)

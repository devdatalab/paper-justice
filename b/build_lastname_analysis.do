/* load analysis dataset */
use $jdata/justice_analysis, clear

/* bring in defendant name */
merge 1:1 ddl_case_id using $jdata/cases_all_years, keepusing(def_name) keep(master match) nogen

/* clean up defendant name and extract last name */
gen def_last_name = word(name, -1)

/* clean up defendant last name a little */
replace def_last_name = "" if inlist(def_last_name, "state", "p.s.", "maharashtra")

/* drop if last name is missing or too short to match */
drop if mi(def_last_name)
drop if strlen(def_last_name) <= 2

/* rename name variable */
ren name def_name_clean

/* now bring in judge name */
merge m:1 ddl_judge_id using $jdata/judges_clean, keepusing(name) keep(master match) nogen

/* extract judge last name */
gen judge_last_name = word(name, -1)

/* first check how many exact last name matches */
count if judge_last_name == def_last_name
/* 1% */

/* name clean judge last name */
name_clean judge_last_name, replace
name_clean def_last_name, replace
drop if mi(def_last_name)
drop if mi(judge_last_name)

/* drop again all def and judges with names too short to work with */
drop if (strlen(def_last_name) <= 2) | (strlen(judge_last_name) <= 2) | mi(def_last_name) | mi(judge_last_name)

/* reconcile names to standard versions */
fix_names def_last_name
fix_names judge_last_name

/* count how many last names are exactly equal */
count if judge_last_name == def_last_name
gen same_last_name = judge_last_name == def_last_name
/* 1.7% */

/* need a last name fixed effect since some names are more likely to appear as judges */
group def_last_name
tag def_last_name

/* count the number of defendant appearances of each last name */
bys dgroup: egen name_count = count(dgroup)

/* count the match rate for each last name */
bys dgroup: egen match_rate = mean(same_last_name)

/* calculate lev dist between names (extremely slow) */
// masala_lev_dist judge_last_name def_last_name, gen(lev)
// sum lev, d
// gen same_last_name_2 = lev <= 1

// gsort -dtag match_rate
// list def_last_name name_count match_rate if dtag & name_count > 100
// gsort -dtag name_count
// list def_last_name name_count match_rate if dtag & name_count > 100

/* Create inverse group size weight -- so we can equally weight each group */
gen wt = 1 / name_count

/* create a rare name indicator */
gen rare_name = name_count < 18986
gen rare_name_wt = name_count < 1000

/* create interaction variables with rare name and same name indicator */
gen same_rare = same_last_name * rare_name
gen same_rare_wt = same_last_name * rare_name_wt

/* label new variables */
label var same_rare "Same name * Rare name"
label var same_rare_wt "Same name * Rare name"
label var same_last_name "Same last name"
label var acq "Acquitted"

/* tag judge last name */
egen judge_name_tag = tag(judge_last_name)

/* group judge last name */
egen int jgroup = group(judge_last_name)

/* drop first names incorrectly classified as last names */
drop if (inlist(def_last_name,"raju", "rajesh", "ramesh", "suresh") | inlist(def_last_name, "rahul", "rakesh", "sanjay", "ravi", "mahesh", "ashok"))
drop if (inlist(judge_last_name,"raju", "rajesh", "ramesh", "suresh") | inlist(judge_last_name, "rahul","rakesh", "sanjay","ravi", "mahesh", "ashok"))

save $tmp/justice_same_names_unmatched, replace

/* note: most match rates are 0 -- drop them, since they could have different
         acquittal rates and would get dropped by the fixed effect anymway */
drop if match_rate == 0

save $jdata/justice_same_names, replace

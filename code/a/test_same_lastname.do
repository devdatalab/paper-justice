/* program to rationalize some last names */
/**********************************************************/
/* program fix_names: force names into common spellings   */
/**********************************************************/
cap prog drop fix_names
prog def fix_names
  syntax varlist
  tokenize `varlist'

  replace `1' = "adhikari" if `1' == "adhikary"
  replace `1' = "agarwal" if `1' == "agrawal"
  replace `1' = "agarwal" if `1' == "aggarwal"
  replace `1' = "ahamad" if `1' == "ahamed"
  replace `1' = "ahamad" if `1' == "ahmad"
  replace `1' = "ahamad" if `1' == "ahmed"
  replace `1' = "begam" if `1' == "begum"
  replace `1' = "behera" if `1' == "bera"
  replace `1' = "bhat" if `1' == "bhatt"
  replace `1' = "bhosale" if `1' == "bhosle"
  replace `1' = "bhowmick" if `1' == "bhowmik"
  replace `1' = "bora" if `1' == "borah"
  replace `1' = "chand" if `1' == "chanda"
  replace `1' = "chaudhari" if `1' == "chaudhary"
  replace `1' = "chetri" if `1' == "chettri"
  replace `1' = "choudhary" if `1' == "choudhry"
  replace `1' = "choudhary" if `1' == "choudhury"
  replace `1' = "choudhary" if `1' == "chowdhury"
  replace `1' = "dahariya" if `1' == "dahiya"
  replace `1' = "dahariya" if `1' == "dahriya"
  replace `1' = "dube" if `1' == "dubey"
  replace `1' = "gouda" if `1' == "gowda"
  replace `1' = "haldar" if `1' == "halder"
  replace `1' = "husain" if `1' == "hussain"
  replace `1' = "jadav" if `1' == "jadhav"
  replace `1' = "kala" if `1' == "kale"
  replace `1' = "karthick" if `1' == "karthik"
  replace `1' = "krishna" if `1' == "krishnaiah"
  replace `1' = "krishna" if `1' == "krishnan"
  replace `1' = "kushwah" if `1' == "kushwaha"
  replace `1' = "mahesh" if `1' == "mahesha"
  replace `1' = "malik" if `1' == "mallick"
  replace `1' = "manjunath" if `1' == "manjunatha"
  replace `1' = "narain" if `1' == "narayan"
  replace `1' = "nigam" if `1' == "nikam"
  replace `1' = "panda" if `1' == "pande"
  replace `1' = "panda" if `1' == "pandey"
  replace `1' = "panda" if `1' == "pandy"
  replace `1' = "panda" if `1' == "pandya"
  replace `1' = "pandit" if `1' == "pandita"
  replace `1' = "panigrahi" if `1' == "panigrahy"
  replace `1' = "patel" if `1' == "patil"
  replace `1' = "pattanaik" if `1' == "pattnaik"
  replace `1' = "pavar" if `1' == "pawar"
  replace `1' = "rajasekar" if `1' == "rajasekhar"
  replace `1' = "sahoo" if `1' == "sahu"
  replace `1' = "sarma" if `1' == "sarmah"
  replace `1' = "satapathy" if `1' == "satpathy"
  replace `1' = "sethi" if `1' == "sethy"
  replace `1' = "shaik" if `1' == "shaikh"
  replace `1' = "shaik" if `1' == "sheik"
  replace `1' = "shukl" if `1' == "shukla"
  replace `1' = "suryavanshi" if `1' == "suryawanshi"
  replace `1' = "tiwari" if `1' == "tiwary"
  replace `1' = "tripathi" if `1' == "tripathy"
  
end
/** END program fix_names *********************************/

use $jdata/justice_analysis, clear

/* bring in defendant name */
merge 1:1 ddl_case_id using $jdata/cases_all_years, keepusing(def_name) keep(master match) nogen

/* bring in clean name */
gen name_original = lower(def_name)
merge m:1 name_original using $jdata/classification/pooled_names_clean_appended, keepusing(name nonindividual) keep(master match) nogen

/* drop nonindividual names */
drop if nonindividual == 1

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

/* note: most match rates are 0 -- drop them, since they could have different
         acquittal rates and would get dropped by the fixed effect anymway */
drop if match_rate == 0

/* calculate lev dist between names (extremely slow) */
// masala_lev_dist judge_last_name def_last_name, gen(lev)
// sum lev, d
// gen same_last_name_2 = lev <= 1

// gsort -dtag match_rate
// list def_last_name name_count match_rate if dtag & name_count > 100
// gsort -dtag name_count
// list def_last_name name_count match_rate if dtag & name_count > 100

/* Put equal weighting on all the last names */
gen wt = 1 / name_count

save $tmp/justice_same_names, replace

/******************************/
/* run the last name analysis */
/******************************/
use $tmp/justice_same_names, clear

la var same_last_name "Same last name"

la var acq "Acquitted"

/* four regressions for the table. With and without judge FE, loc-month and loc-year fixed effects */
/* unweighted, without and with judge FE */
eststo clear

/* log timestamp */
set_log_time

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup loc_month acts)
estadd local FE "Court-month"
estadd local judge "No"
estimates store m1 

/* store sample size from regression above in a local */
count if e(sample) == 1
local sample_1: di `r(N)'

/* store bias coefficient in a local */
local last_name_cm: di _b["same_last_name"]

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup loc_month acts judge)
estadd local FE "Court-month"
estadd local judge "Yes"
estimates store m2

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup loc_year acts)
estadd local FE "Court-year"
estadd local judge "No"
estimates store m3 

/* store sample size from regression above in a local */
count if e(sample) == 1
local sample_2: di `r(N)'

/* store bias coefficient in a local */
local last_name_cy: di _b["same_last_name"]

reghdfe acq same_last_name def_female def_muslim [pw=wt], absorb(dgroup loc_year acts judge)
estadd local FE "Court-year"
estadd local judge "Yes"
estimates store m4 

esttab m1 m2 m3 m4 using $out/last_names.tex, replace se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars("FE Fixed Effect" "judge Judge Fixed Effect") drop(_cons def_female def_muslim) b(3)  
//estout_default using $out/last_names, order(same_last_name)

/* write stored statistics in the paper stats csv file */
store_paper_stat `sample_1' using $out/justice_paper_stats.csv, description("Last name bias result - court-month: sample") group("same caste bias")
store_paper_stat `sample_2' using $out/justice_paper_stats.csv, description("Last name bias result - court-year: sample") group("same caste bias")
store_paper_stat `last_name_cm' using $out/justice_paper_stats.csv, description("Last name bias result - court-month: coef") group("same caste bias")
store_paper_stat `last_name_cy' using $out/justice_paper_stats.csv, description("Last name bias result - court-year: coef") group("same caste bias")


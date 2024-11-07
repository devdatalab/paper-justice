/*****************************************/
/* exclude non-names from lawyer dataset */
/*****************************************/

/* import the lawyer non name csv and save as dta with match variable pet_adv*/
import delimited $jcode/b/csv/lawyer_non_names, varnames(1) clear
rename lawyer_non_name pet_adv
save $tmp/pet_adv_non_name, replace

/* import the lawyer non name csv and save as dta with match variable def_adv */
import delimited $jcode/b/csv/lawyer_non_names, varnames(1) clear
rename lawyer_non_name def_adv
save $tmp/def_adv_non_name, replace

/* load the analysis dataset from which we have to remove non names */
use $jdata/justice_analysis, clear

/* pull defendent and petitioner lawyer names back from cases_all_years */
merge 1:1 ddl_case_id using $jdata/cases_all_years, keepusing(def_adv pet_adv) keep(match) nogen

/* Merge to the list of non-names (e.g. "prosecutor") and drop matches, so we are left with real names. */
merge m:1 pet_adv using $tmp/pet_adv_non_name
drop if _merge == 3
drop _merge

/* Merge to the list of non-names (e.g. "prosecutor") and drop matches, so we are left with real names. */
merge m:1 def_adv using $tmp/def_adv_non_name
drop if _merge == 3
drop _merge

/**************************************************/
/* Verify whether the top few names are real names */
/**************************************************/

//keep if (inlist(pet_adv_nonmuslim, 0, 1)

///* verifying most common pet_adv names */
//bys pet_adv: egen pcount = count(pet_adv)
//tag pet_adv
//gsort -ptag -pcount
//list pet_adv pcount if ptag

//keep if inlist(def_adv_nonmuslim, 0, 1)), clear
  
///* verifying most common def_adv names */
//bys def_adv: egen dcount = count(def_adv)
//tag def_adv
//gsort -dtag -dcount
//list def_adv dcount if dtag

save $jdata/lawyer_name_analysis, replace

/***********************************************************/
/* Religion analysis for defendant and petitioner advocates */
/***********************************************************/

/* load cases where we have petitioner and defendant advocate religion  */
use $jdata/lawyer_name_analysis if inlist(def_adv_nonmuslim, 0, 1) & inlist(pet_adv_nonmuslim, 0, 1), clear

/* column 1 - main bias result, check if there is bias in acquittal rate when defendant and judge have the same religion*/
estimates clear
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim, absorb(loc_month acts) cluster(judge)
eststo reg1
estimates save reg1, replace

/* column 4 - check if there if bias in acquittal rate when religion of judge and each of the lawyers match, controlling for defendant religion */
estimates clear
reghdfe acquitted def_adv_nonmuslim judge_nonmuslim judge_def_adv_nonmuslim pet_adv_nonmuslim judge_pet_adv_nonmuslim def_nonmuslim judge_def_nonmuslim, absorb(loc_month acts) cluster(judge)
eststo reg4
estimates save reg4, replace

/* load cases where we have defendant advocate religion  */
use $jdata/lawyer_name_analysis if inlist(def_adv_nonmuslim, 0, 1), clear

/* column 2 - check if there is bias in acquittal rate when defendant advocate and judge match on religious identity */
estimates clear
reghdfe acquitted def_adv_nonmuslim judge_nonmuslim judge_def_adv_nonmuslim, absorb(loc_month acts) cluster(judge)
estimates save reg2, replace

/* load cases where we have petitioner advocate religion  */
use $jdata/lawyer_name_analysis if inlist(pet_adv_nonmuslim, 0, 1), clear

/* column 3 - check if there is bias in acquittal rate when petitioner advocate and judge match on religious identity */
estimates clear
reghdfe acquitted judge_nonmuslim pet_adv_nonmuslim judge_pet_adv_nonmuslim, absorb(loc_month acts) cluster(judge)
estimates save reg3, replace

estimates use reg1
eststo reg1
qui estadd local fe "Court-month"
estimates use reg2
eststo reg2
qui estadd local fe "Court-month"
estimates use reg3
eststo reg3
qui estadd local fe "Court-month"
estimates use reg4
eststo reg4
qui estadd local fe "Court-month"

/* output to table  */
esttab reg1 reg2 reg3 reg4 using "$out/lawyers_religion.tex", replace label b(4) se(4) s(fe N, label("Fixed Effect" "Observations") fmt(0 0)) drop(_cons) mtitles("Acquitted" "Acquitted" "Acquitted" "Acquitted") booktabs nonotes nostar

/***********************************************************/
/* Gender analysis for defendant and petitioner advocates */
/***********************************************************/

/* load cases where we have petitioner and defendant advocate gender */
use $jdata/lawyer_name_analysis if inlist(def_adv_male, 0, 1) & inlist(pet_adv_male, 0, 1), clear

/* column 1 - check if there if bias in acquittal rate when the gender identity of judge and defendant match */
estimates clear
reghdfe acquitted judge_male def_male judge_def_male, absorb(loc_month acts) cluster(judge)
estimates save reg4, replace

/* column 4 - check if there if bias in acquittal rate when the gender identity of judge and each of the lawyers match, controlling for defendant gender*/
estimates clear
reghdfe acquitted def_adv_male judge_male judge_def_adv_male pet_adv_male judge_pet_adv_male def_male judge_def_male, absorb(loc_month acts) cluster(judge)
estimates save reg7, replace

/* load cases where we have defendant advocate gender  */
use $jdata/lawyer_name_analysis if inlist(def_adv_male, 0, 1), clear

estimates clear
/* column 2 - check if there is bias in acquittal rate when defendant advocate and judge match on gender identity */
reghdfe acquitted def_adv_male judge_male judge_def_adv_male, absorb(loc_month acts) cluster(judge)
estimates save reg5, replace

/* load cases where we have petitioner advocate gender  */
use $jdata/lawyer_name_analysis if inlist(pet_adv_male, 0, 1), clear

estimates clear
/* column 3 - check if there is bias in acquittal rate when petitioner advocate and judge match on gender identity */
reghdfe acquitted judge_male pet_adv_male judge_pet_adv_male, absorb(loc_month acts) cluster(judge)
estimates save reg6, replace

estimates use reg4
eststo reg4
qui estadd local fe "Court-month"
estimates use reg5
eststo reg5
qui estadd local fe "Court-month"
estimates use reg6
eststo reg6
qui estadd local fe "Court-month"
estimates use reg7
eststo reg7
qui estadd local fe "Court-month"

/* output to table  */
esttab reg4 reg5 reg6 reg7 using "$out/lawyers_gender.tex", replace label b(4) se(4) s(fe N, label("Fixed Effect" "Observations") fmt(0 0) ) mtitles("Acquitted" "Acquitted" "Acquitted" "Acquitted") drop(_cons) booktabs nonotes nostar


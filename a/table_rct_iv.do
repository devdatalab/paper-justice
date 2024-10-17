/* import analysis dataset */
use $jdata/justice_analysis, clear

/* drop if no decision date */
drop if mi(decision_date)

/* shrink dataset */
drop name cino case_no

/* get decision judge identity */
ren ddl_judge_id ddl_judge_id_filing
ren ddl_decision_judge_id ddl_judge_id
merge m:1 ddl_judge_id using $jdata/judges_clean, keep(match) nogen keepusing(muslim_class female_class)
ren muslim_class judge_dec_muslim
ren female_class judge_dec_female

/* replace coded missing values with missing */
replace judge_dec_muslim = . if !inlist(judge_dec_muslim, 0, 1)
replace judge_dec_female = . if !inlist(judge_dec_female, 0, 1)

gen judge_dec_male = 1 - judge_dec_female
gen judge_dec_nonmuslim = 1 - judge_dec_muslim
gen judge_dec_def_male = judge_dec_male * def_male
gen judge_dec_def_nonmuslim = judge_dec_nonmuslim * def_nonmuslim

/* label judge vars needed for the regressions */
la var judge_male "Male Filing Judge"
la var judge_nonmuslim "Non-Muslim Filing Judge"
la var judge_dec_male "Male Deciding Judge"
la var judge_dec_nonmuslim "Non-Muslim Deciding Judge"
la var judge_dec_def_male "Male Deciding Judge and Defendant"
la var judge_dec_def_nonmuslim "Non-Muslim Deciding Judge and Defendant"
la var def_male "Male Defendant"
la var def_nonmuslim "Non-Muslim Defendant"

/* run main regression to tag sample */
reg acquitted judge_male def_male judge_def_male 
keep if e(sample) & !mi(loc_month) & !mi(acts)

save $tmp/justice_iv, replace

/**********************************************/
/* Store some basic statistics for validation */
/**********************************************/
eststo clear

/* column 1: main simple paper spec, no judge FE for timing */
ivreghdfe acquitted def_male judge_dec_male (judge_dec_def_male  = judge_def_male), absorb(loc_month acts)  cluster(judge)
estadd local fe "Court-month"
estadd local judge "No"
eststo m1

/* column 2: switch to loc_year FE */
ivreghdfe acquitted def_male judge_dec_male (judge_dec_def_male  = judge_def_male), absorb(loc_year acts)  cluster(judge)
estadd local fe "Court-year"
estadd local judge "No"
eststo m2

/* columns 3 and 4: same thing but for religion */
ivreghdfe acquitted def_nonmuslim judge_dec_nonmuslim (judge_dec_def_nonmuslim  = judge_def_nonmuslim), absorb(loc_month acts)  cluster(judge)
estadd local fe "Court-month"
estadd local judge "No"
eststo m3

ivreghdfe acquitted def_nonmuslim judge_dec_nonmuslim (judge_dec_def_nonmuslim  = judge_def_nonmuslim), absorb(loc_year acts)  cluster(judge)
estadd local fe "Court-year"
estadd local judge "No"
eststo m4

esttab m1 m2 m3 m4 using "$out/table_rct_iv", order(judge_male def_male judge_dec_male judge_dec_def_male judge_nonmuslim def_nonmuslim judge_dec_nonmuslim judge_dec_def_nonmuslim)  replace label b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    s(N fe judge, label( "Observations" "Fixed Effect" "Judge Fixed Effect") fmt(0 0 0) )  ///
    mtitles("Acquitted" "Acquitted" "Acquitted" "Acquitted") booktabs nonote

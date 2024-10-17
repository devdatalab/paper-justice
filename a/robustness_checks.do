/* billy write $out/religion_amb.tex */
/* billy write $out/gender_amb.tex */
/* billy write $out/religion_same_judge.tex */
/* billy write $out/gender_same_judge.tex */
/* billy ignore all */

/*******/
/* RCT */
/*******/

/* import analysis dataset */
use $jdata/justice_analysis, clear

/* generate indicator for whether filing judge reached a verdict */
gen same_judge = 1 if ddl_filing_judge_id == ddl_decision_judge_id 
replace same_judge = 0 if ddl_filing_judge_id != ddl_decision_judge_id 

/**********/
/* Gender */
/**********/

/* column 1 */
reghdfe amb judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
store_gender, name("col1") outcome("amb") label("Ambiguous outcome")

/* column 2 */
reghdfe amb judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
store_gender, name("col2") outcome("amb") label("Ambiguous outcome")

/* column 3 */
reghdfe amb judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
store_gender, name("col3") outcome("amb") label("Ambiguous outcome")

/* column 4 */
reghdfe amb judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("amb") label("Ambiguous outcome")

/* column 5 */
reghdfe amb judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("amb") label("Ambiguous outcome")

/* column 6 */
reghdfe amb judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("amb") label("Ambiguous outcome")

table_from_tpl, t($jcode/tex/g_tpl.tex) r($tmp/gender_amb.csv) o($out/gender_amb.tex)

/* same judge */
/* column 1 */
reghdfe same_judge judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
store_gender, name("col1") outcome("same_judge") label("Filing judge reached decision")

/* column 2 */
reghdfe same_judge judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
store_gender, name("col2") outcome("same_judge") label("Filing judge reached decision")

/* column 3 */
reghdfe same_judge judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
store_gender, name("col3") outcome("same_judge") label("Filing judge reached decision")

/* column 4 */
reghdfe same_judge judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
store_gender, name("col4") outcome("same_judge") label("Filing judge reached decision")

/* column 5 */
reghdfe same_judge judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
store_gender, name("col5") outcome("same_judge") label("Filing judge reached decision")

/* column 6 */
reghdfe same_judge judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
store_gender, name("col6") outcome("same_judge") label("Filing judge reached decision")

table_from_tpl, t($jcode/tex/g_tpl.tex) r($tmp/gender_same_judge.csv) o($out/gender_same_judge.tex)

/************/
/* Religion */
/************/

/* column 1 */
reghdfe amb judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
store_religion, name("col1") outcome("amb") label("Ambiguous outcome")

/* column 2 */
reghdfe amb judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
store_religion, name("col2") outcome("amb") label("Ambiguous outcome")

/* column 3 */
reghdfe amb judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
store_religion, name("col3") outcome("amb") label("Ambiguous outcome")

/* column 4 */
reghdfe amb judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_year acts) cluster(judge)
store_religion, name("col4") outcome("amb") label("Ambiguous outcome")

/* column 5 */
reghdfe amb judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts) cluster(judge)
store_religion, name("col5") outcome("amb") label("Ambiguous outcome")

/* column 6 */
reghdfe amb judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
store_religion, name("col6") outcome("amb") label("Ambiguous outcome")

table_from_tpl, t($jcode/tex/r_tpl.tex) r($tmp/religion_amb.csv) o($out/religion_amb.tex)

/* same judge */
/* column 1 */
reghdfe same_judge judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
store_religion, name("col1") outcome("same_judge") label("Filing judge reached decision")

/* column 2 */
reghdfe same_judge judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
store_religion, name("col2") outcome("same_judge") label("Filing judge reached decision")

/* column 3 */
reghdfe same_judge judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
store_religion, name("col3") outcome("same_judge") label("Filing judge reached decision")

/* column 4 */
reghdfe same_judge judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_year acts) cluster(judge)
store_religion, name("col4") outcome("same_judge") label("Filing judge reached decision")

/* column 5 */
reghdfe same_judge judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts) cluster(judge)
store_religion, name("col5") outcome("same_judge") label("Filing judge reached decision")

/* column 6 */
reghdfe same_judge judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
store_religion, name("col6") outcome("same_judge") label("Filing judge reached decision")

table_from_tpl, t($jcode/tex/r_tpl.tex) r($tmp/religion_same_judge.csv) o($out/religion_same_judge.tex)

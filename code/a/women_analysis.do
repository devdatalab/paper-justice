/******************************************/
/* program progname: crime_type_analysis  */
/******************************************/
cap prog drop crime_type_analysis
prog def crime_type_analysis

  syntax, var(string) label(string)

  /* activate below depending on sample */
  keep if `var' == 1 & act == "The Indian Penal Code"

  /* column 1 */
  reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_month acts) cluster(judge)
  store_gender, name("col1") outcome("acquitted") label("Acquittal rate")

  /* column 2 */
  reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts) cluster(judge)
  store_gender, name("col2") outcome("acquitted") label("Acquittal rate")

  /* column 3 */
  reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_month acts judge) cluster(judge)
  store_gender, name("col3") outcome("acquitted") label("Acquittal rate")

  /* column 4 */
  reghdfe acquitted judge_male def_male judge_def_male , absorb(loc_year acts) cluster(judge)
  store_gender, name("col4") outcome("acquitted") label("Acquittal rate")

  /* column 5 */
  reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts) cluster(judge)
  store_gender, name("col5") outcome("acquitted") label("Acquittal rate")

  /* column 6 */
  reghdfe acquitted judge_male def_male judge_def_male def_nonmuslim judge_men_def_nm , absorb(loc_year acts judge) cluster(judge)
  store_gender, name("col6") outcome("acquitted") label("Acquittal rate")

  table_from_tpl, t($out/g_template.tex) r($tmp/gender_acquitted.csv) o($out/gender_acquitted_`label'.tex)
  
  /* column 1 */
  reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim , absorb(loc_month acts) cluster(judge)
  store_religion, name("col1") outcome("acquitted") label("Acquittal rate")

  /* column 2 */
  reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts) cluster(judge)
  store_religion, name("col2") outcome("acquitted") label("Acquittal rate")

  /* column 3 */
  reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_month acts judge) cluster(judge)
  store_religion, name("col3") outcome("acquitted") label("Acquittal rate")

  /* column 6 */
  reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim def_male judge_nm_def_men , absorb(loc_year acts judge) cluster(judge)
  store_religion, name("col6") outcome("acquitted") label("Acquittal rate")

  table_from_tpl, t($out/r_template.tex) r($tmp/religion_acquitted.csv) o($out/religion_acquitted_`label'.tex)

  /* save csv */
  insheet using $tmp/religion_acquitted.csv, clear
  outsheet using $tmp/religion_acquitted_`label'.csv, comma replace
  insheet using $tmp/gender_acquitted.csv, clear
  outsheet using $tmp/gender_acquitted_`label'.csv, comma replace
  
end
/** END program crime_type_analysis ******/

/* set up crime analysis data */
use $jdata/justice_analysis, clear

/* tab offenses */
tab offenses, gen(offense)

/* set global */
global descvars murder women_crime property_crime offense23 offense5 offense11 offense12 offense16 offense21 offense22 offense30 offense34 

/* generate other */
gen other = 1

/* tag uncategorized crimes as other */
foreach x of var $descvars{
  replace other = 0 if `x' == 1
}

/* rename and label offenses */
do $jcode/b/balance_rename.do

/* save in scratch */
save $tmp/crime_type_analysis, replace

/* 1. crimes against women */
use $tmp/crime_type_analysis, clear
crime_type_analysis, var(women_crime) label(wom)

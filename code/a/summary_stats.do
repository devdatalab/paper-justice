/*********************/
/* Prep case dataset */
/*********************/

/* bring in dataset */
use $jdata/cases_all_years, clear

/* drop cases wheren clean defendant name is missing */
drop if mi(def_name)

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

/* gender */
rename def_name_female def_female 
replace def_female = . if def_female < 0 
gen def_male = !(def_female) if def_female != . 

/* religion */
rename def_name_muslim def_muslim 
replace def_muslim = . if def_muslim < 0 
gen def_nonmuslim = !(def_muslim) if def_muslim != . 

/* keep only vars we need */
keep $descvars acquitted def_muslim def_female section act other

/* create a dummy variable for all */
gen all = 1

/* rename and label offenses */
do $jcode/b/balance_rename.do

/* set new category of offenses */
global cat murder women_crime property_crime offense* peace other all

/* save */
save $tmp/desc_short, replace


/**********/
/* Tables */
/**********/

/* import dataset */
use $tmp/desc_short, clear

drop if mi(def_muslim)

/* Religion table */

/* create descriptive table of share of muslims in various crime populations */
foreach x of var $cat {

  qui{
    
/* Muslim share of charge */
  sum def_muslim if `x' == 1
  local m: di %6.3f `r(mean)'

/* Muslim share/population share */
  local mr: di %6.3f `m'/0.142
  local mre `mr'

/* Muslim conviction rate */
  sum acquitted if def_muslim == 1 & `x' == 1
  local mc: di %6.3f `r(mean)'
  
/* Non-muslim conviction rate */
  sum acquitted if def_muslim == 0 & `x' == 1
  local nmc: di %6.3f `r(mean)'
    
/* difference between the two */
  local diff = `mc' - `nmc'

/* total */
  count if `x' == 1
  local N: di %10.3f `r(N)'
    
/* store label */
  local y: variable label `x'    

 }  
    
  di "`y':" %20s "`m'" %20s "`mre'" %20s "`mc'" %20s "`nmc'" %20s "`diff'" 

/* some morel locals */
  local demo "Muslim"
  local nondemo "Non-Muslim"

  /* store results into csv */
  insert_into_file using $tmp/rbalance.csv, key(m_`x') value("`m'") format(%6.3f)
  insert_into_file using $tmp/rbalance.csv, key(mre_`x') value("`mre'") format(%6.3f)
  insert_into_file using $tmp/rbalance.csv, key(mc_`x') value("`mc'") format(%6.3f)
  insert_into_file using $tmp/rbalance.csv, key(nmc_`x') value("`nmc'") format(%6.3f)
  insert_into_file using $tmp/rbalance.csv, key(diff_`x') value("`diff'") format(%6.3f)
  insert_into_file using $tmp/rbalance.csv, key(N_`x') value("`N'") format(%12.0fc)
  insert_into_file using $tmp/rbalance.csv, key(`x') value("`y'") format(%6.3f)  
  insert_into_file using $tmp/rbalance.csv, key(demo) value("`demo'") format(%6.3f)
  insert_into_file using $tmp/rbalance.csv, key(nondemo) value("`nondemo'") format(%6.3f)  
}

/* write estimates to tables */
table_from_tpl, t($jcode/a/tpl/balance_tpl.tex) r($tmp/rbalance.csv) o($out/rbal.tex)     

/* Gender */
/* import dataset */
use $tmp/desc_short, clear

/* drop if we dont have defendant gender */
drop if mi(def_female)

/* Religion table */

/* create descriptive table of share of females in various crime populations */
foreach x of var $cat {

  qui{

/* Female share of charge */
  sum def_female if `x' == 1
  local m: di %6.3f `r(mean)'

/* Female share/population share */
  local mr: di %6.3f `m'/0.48
  local mre `mr'

/* Female conviction rate */
  sum acquitted if def_female == 1 & `x' == 1
  local mc: di %6.3f `r(mean)'
  
/* Non-female conviction rate */
  sum acquitted if def_female == 0 & `x' == 1
  local nmc: di %6.3f `r(mean)'
    
/* difference between the two */
  local diff = `mc' - `nmc'

/* total */
  count if `x' == 1
  local N: di %10.3f `r(N)'
    
/* store label */
  local y: variable label `x'    

  }  
    
  di "`y':" %20s "`m'" %20s "`mre'" %20s "`mc'" %20s "`nmc'" %20s "`diff'" 

/* some morel locals */
  local demo "Female"
  local nondemo "Male"
  
  /* store results into csv */
  insert_into_file using $tmp/gbalance.csv, key(m_`x') value("`m'") format(%6.3f)
  insert_into_file using $tmp/gbalance.csv, key(mre_`x') value("`mre'") format(%6.3f)
  insert_into_file using $tmp/gbalance.csv, key(mc_`x') value("`mc'") format(%6.3f)
  insert_into_file using $tmp/gbalance.csv, key(nmc_`x') value("`nmc'") format(%6.3f)
  insert_into_file using $tmp/gbalance.csv, key(diff_`x') value("`diff'") format(%6.3f)
  insert_into_file using $tmp/gbalance.csv, key(N_`x') value("`N'") format(%12.0fc)
  insert_into_file using $tmp/gbalance.csv, key(`x') value("`y'") format(%6.3f)  
  insert_into_file using $tmp/gbalance.csv, key(demo) value("`demo'") format(%6.3f)
  insert_into_file using $tmp/gbalance.csv, key(nondemo) value("`nondemo'") format(%6.3f)  
}

/* write estimates to tables */
table_from_tpl, t($jcode/a/tpl/balance_tpl.tex) r($tmp/gbalance.csv) o($out/gbal.tex)     

/***********************************/
/* Prepare a dataset for coefplots */
/***********************************/

/* bring in religion csv */
insheet using $tmp/rbalance.csv, clear

/* drop what we dont need */
drop v3 v4

/* splot the first variable */
split v1, p("_") 

/* keep only the variables we are interested in */
keep if inlist(v11, "mre", "mc", "nmc", "diff")

/* drop what we dont need */
cap drop if inlist(v12, "robbery", "offense11", "offense5", "offense12")

/* rename variables */
ren v11 stat
ren v12 crime
ren v2 coef

/* savesome separately */
savesome crime coef using $tmp/mre if stat == "mre", replace
savesome crime coef using $tmp/mc if stat == "mc", replace
savesome crime coef using $tmp/nmc if stat == "nmc", replace
savesome crime coef using $tmp/diff if stat == "diff", replace

/* merge all three */
use $tmp/mre, clear
ren coef mre
merge 1:1 crime using $tmp/mc, nogen
ren coef mc
merge 1:1 crime using $tmp/nmc, nogen
ren coef nmc
merge 1:1 crime using $tmp/diff, nogen
ren coef diff

/* destring and format all vars */
destring mre mc nmc diff, replace
format %9.3g mre mc nmc diff 

/* save dataset */
save $tmp/religion_coefplot, replace

/* bring in religion csv */
insheet using $tmp/gbalance.csv, clear

/* drop what we dont need */
drop v3 v4

/* splot the first variable */
split v1, p("_") 

/* keep only the variables we are interested in */
keep if inlist(v11, "mre", "mc", "nmc", "diff")

/* drop what we dont need */
cap drop if inlist(v12, "robbery", "offense11", "offense5", "offense12")

/* rename variables */
ren v11 stat
ren v12 crime
ren v2 coef

/* savesome separately */
savesome crime coef using $tmp/mre if stat == "mre", replace
savesome crime coef using $tmp/mc if stat == "mc", replace
savesome crime coef using $tmp/nmc if stat == "nmc", replace
savesome crime coef using $tmp/diff if stat == "diff", replace

/* merge all three */
use $tmp/mre, clear
ren coef mre
merge 1:1 crime using $tmp/mc, nogen
ren coef mc
merge 1:1 crime using $tmp/nmc, nogen
ren coef nmc
merge 1:1 crime using $tmp/diff, nogen
ren coef diff

/* destring and format all vars */
destring mre mc nmc diff, replace
format %9.3g mre mc nmc diff 

/* save dataset */
save $tmp/gender_coefplot, replace

/* erase desc_short from scratcg */
erase $tmp/desc_short.dta

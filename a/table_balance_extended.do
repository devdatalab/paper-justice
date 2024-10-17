/* load analysis dataset */
use $jdata/justice_analysis, clear

/* drop heavy strings */
drop name ddl_case_id case_no cino

/* for lawyer variables, make sure missing is not coded as a number */
foreach s in pet def {
  foreach i in female muslim {
    replace `s'_adv_`i' = . if inlist(`s'_adv_`i', -9999, -9998, -1)
  }
}

/* define variables indicating when we don't observe defendant characteristics */
gen nm_def_female = !mi(def_female)
gen nm_def_muslim = !mi(def_muslim)

/* do we observe lawyers' characteristics */
gen nm_pet_adv_gender = !mi(pet_adv_female)
gen nm_def_adv_gender = !mi(def_adv_female)
gen nm_pet_adv_muslim = !mi(pet_adv_muslim)
gen nm_def_adv_muslim = !mi(def_adv_muslim)

/* save working extended balance dataset */
save $tmp/justice_balance_extended, replace

/************/
/* Analysis */
/************/

/* for each type of regression, we get a version each for:
  (i) court-year or court-month fixed effects;
  (ii) outcome is muslim judge or female judge.
*/


/*****************************************/
/* Regression 1: balance on lawyer types */
/*****************************************/
/* We run a bivariate balance test for each variable, since requiring all vars to be
   non-missing drops nearly all observations. */

/* Open balance dataset */
use $tmp/justice_balance_extended, clear

/* create and clear the estimates file */
global f $out/balance_adv.csv
cap erase $f

/* loop over fixed effect, y-var, and x-var */
foreach fe in loc_month loc_year {

  /* assign short labels for the template file */
  local loc_month_lab "m"
  local loc_year_lab "y"
  foreach y in judge_female judge_muslim {
    local judge_female_lab "fem"
    local judge_muslim_lab "mus"
    foreach x in def_female def_muslim def_adv_female pet_adv_female def_adv_muslim pet_adv_muslim {
      local def_adv_female_lab "da_fem"
      local pet_adv_female_lab "pa_fem"
      local def_adv_muslim_lab "da_mus"
      local pet_adv_muslim_lab "pa_mus"
      local def_female_lab "d_fem"
      local def_muslim_lab "d_mus"
      
      /* run the bivariate regression for this x, y, FE combination */
      quireg `y' `x', absorb(`fe' acts) cluster(judge) title("`y'-`x'-`fe'")

      /* insert the result into the estimates file */
      insert_est_into_file using $f, b(`x') spec(``y'_lab'_``x'_lab'_``fe'_lab')
    }
  }
}
table_from_tpl, t($jcode/tex/balance_extended_lawyers_tpl.tex) r($f) o($out/balance_extended_lawyers.tex)


/**********************************************************************************/
/* Regression 2: balance on observability of defendant and lawyer characteristics */
/**********************************************************************************/
use $tmp/justice_balance_extended, clear

reghdfe judge_female nm_def_* nm_pet*, absorb(loc_month acts) cluster(judge)
estadd local fe "Court-month"
eststo m1
reghdfe judge_muslim nm_def_* nm_pet*, absorb(loc_month acts) cluster(judge)
estadd local fe "Court-month"
eststo m2
reghdfe judge_female nm_def_* nm_pet*, absorb(loc_year  acts) cluster(judge)
estadd local fe "Court-year"
eststo m3
reghdfe judge_muslim nm_def_* nm_pet*, absorb(loc_year  acts) cluster(judge)
estadd local fe "Court-year"
eststo m4

/* label variables */
la var nm_def_female "Observed Defendant Gender"
la var nm_def_muslim "Observed Defendant Religion"
la var nm_def_adv_gender "Observed Defendant Lawyer Gender"
la var nm_def_adv_muslim "Observed Defendant Lawyer Religion"
la var nm_pet_adv_gender "Observed Petitioner Lawyer Gender"
la var nm_pet_adv_muslim "Observed Petitioner Lawyer Religion"

esttab m1 m3 m2 m4 using "$out/balance_extended_missing", replace label b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    s(N fe, label( "Observations" "Fixed Effect") fmt(0 0) ) drop(_cons) ///
    mtitles("Female Judge" "Female Judge" "Muslim Judge" "Muslim Judge") booktabs nonote


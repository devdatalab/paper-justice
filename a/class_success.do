/* This do file creates a table that has classification success rates by state */

/* load dataset */
use $jdata/cases_all_years, clear

/* create identifier for missing defendant gender */
gen gen_success = 1 if inlist(def_name_female, 1, 0)
replace gen_success = 0 if inlist(def_name_female, -9998)

/* create identifier for missing defendant religion */
gen rel_success = 1 if inlist(def_name_muslim, 1, 0)
replace rel_success = 0 if inlist(def_name_muslim, -9998)

/* collapse data at the state level */
collapse gen_success rel_success, by(state_name)
drop if mi(state_name)
decode state_name_code, gen(state_name)

drop if regexm(state_name, "DNH") == 1

ren gen_success Gender
ren rel_success Religion

format Gender Religion %03.2f

/* export dataset as nice latex table */
estpost tabstat Gender Religion, by(state_name)

cap esttab using $out/class_success.tex, cells("Gender(fmt(%03.2f)) Religion(fmt(%03.2f))") noobs  ///
    varwidth(30) drop(Total) ///
     tex replace nonumbers nomtitle 


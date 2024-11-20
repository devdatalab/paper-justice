/* This do file attempts a first pass */
/* merge between the poi last name - community */
/* name key and names from the justice analysis data */

/* starting point justice dataset with */
/* clean judge and defendant last names */
/* that was prepared for same last name */
/* analysis in b/build_lastname_analysis.do */

use $jdata/justice_same_names, clear

/* save only the variables we care about */
keep *last_name acq loc_month loc_year acts acq judge ///
    jgroup dgroup state* year *muslim* *male*
compress

/* get state names */
ren (state_code state) (state state_code)
merge m:1 state_code year using $jdata/keys/cases_state_key, nogen keep(match)

/* save intermediate dataset */
save $tmp/working_full, replace

/* prepare defendant last names for masala merge */
preserve

keep pc11_state_id def_last_name
duplicates drop
gen idu = _n
tostring idu, replace
save $tmp/def_fm, replace

restore

/* prepare judge last names for masala merge */
preserve

keep pc11_state_id judge_last_name
duplicates drop
gen idu = _n
tostring idu, replace
save $tmp/judge_fm, replace

restore

/* prepare poi data for masala merge */
use $norms/poi_master, clear

/* drop norms, keeping only the POI classifications */
ren (t_180 t_181 t_182 t_183 t_64 t_65) ///
    (brahm kshat vaish shudr sc st)
capture drop t_*

/* only keep lastnames that are mapped to a */
/* single community within a state */
/* i.e. not allowing for ambiguous matches */
/* (67% of data) */
keep if n_comm_state == 1

/* 10 obs erroneously remain despite the drop */
duplicates tag pc11_state_id lastname, gen(tag)
tab tag
keep if tag == 0
drop tag

/* generate id for masala merge */
/* EI Note: changing this to idu because using different structure for poi-merge than Aditi's version */
gen idu = _n
tostring idu, replace

/* drop the obs with state ids that don't appear in the justice data (because merge will fail and code will crash) */
drop if inlist(pc11_state_id, "25", "26", "34", "35")

/* save */
compress
save $tmp/poi_fm, replace

/* gen var containing only first letter to masala-merge within that group later */
gen first_letter = substr(lastname, 1,1)

/* save  */
save $tmp/poi_name_jatis, replace



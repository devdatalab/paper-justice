/* import dataset */
use $jdata/justice_analysis, clear

/* bring in state and district name from case keys */
merge m:1 state_code using $jdata/keys/c_state_key_2018, nogen keep(match)

/* get pc11 state ids */
replace state_name = lower(state_name)

/* fix state names for merge */
replace state_name = "nct of delhi"  if state_name == "delhi"
replace state_name = "jammu kashmir" if state_name == "jammu and kashmir"
replace state_name = "odisha" if state_name == "orissa"
replace state_name = "andhra pradesh" if state_name == "telangana"

/* gen var for merge */
gen pc11_state_name = state_name

/* do the merge */
merge m:1 pc11_state_name using $keys/pc11_state_key, keep(match) keepusing(pc11_state_id) nogen

/* generate a total variable to allow us to calculate shares */
gen total = 1

/* collapse to state level */
collapse_save_labels
collapse (sum) def_muslim def_female total, by(pc11_state_id pc11_state_name)
collapse_apply_labels

/* generate shares */
gen fem_share = def_female/total
gen mus_share = def_muslim/total

/* save dataset */
save $tmp/case_demo, replace

/* prepare pc11 data */
use $pc11/pca/religion/pc11u_district_social_group, clear
append using $pc11/pca/religion/pc11r_district_social_group

/* collapse */
collapse (sum) pc11_p_muslim pc11_tot_p, by(pc11_state_id)

/* generate muslim share */
gen pc11_mus_share = pc11_p_muslim/pc11_tot_p

/* merge collapsed case data */
merge 1:1 pc11_state_id using $tmp/case_demo, keep(match) nogen

/* label variable for graph */
la var mus_share "Muslim defendant share"

/* scatter plot */
set scheme pn
graph twoway (scatter mus_share pc11_mus_share [w=pc11_p_muslim], msymbol(circle_hollow)) (lfit mus_share pc11_mus_share) ///
    , xtitle("Muslim population share in state (Census 2011)") ylabel(0(0.1)0.8) xlabel(0(0.1) 0.8) ///
    ytitle("LSTM classified Muslim defendant share")
graphout validation, pdf

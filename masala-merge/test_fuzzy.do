do ~/include

/* test_fuzzy.do: program to ensure any changes to our fuzzy merge
                  don't make any matches worse */

/* set SHORT = 0 to run full test */
global SHORT 0

/* START WITH MATCHED pc91-01 key, and split into a 1991 and 2001 dataset. */
use $keys/pc9101r_key_unique, clear

/* shrink dataset if we want a fast version */
if ($SHORT > 0) {
  keep if inlist(pc01_subdistrict_id, "0003") & pc01_state_id == "02"
}

keep pc91_village_name pc01_village_name pc01_state_id pc01_district_id pc01_subdistrict_id 
gen id = _n

gen name91 = pc91_village_name
gen name01 = pc01_village_name 

name_clean pc01_village_name, replace
name_clean pc91_village_name, replace

keep if pc91_village_name != pc01_village_name & !mi(pc91_village_name) & !mi(pc01_village_name)

/* match these within subdistricts as if we don't know what the match is */

/* save pc01 version */
preserve
keep pc01_village_name pc01_state_id pc01_district_id pc01_subdistrict_id name01 id
ren id id01
ren pc01_village_name village_name
duplicates drop pc01_state_id pc01_district_id pc01_subdistrict_id village_name , force

save $tmp/pc01_$SHORT, replace
restore

/* prep pc91 version */
keep pc91_village_name pc01_state_id pc01_district_id pc01_subdistrict_id name91 id
ren id id91
ren pc91_village_name village_name
duplicates drop pc01_state_id pc01_district_id pc01_subdistrict_id village_name , force
save $tmp/pc91_$SHORT, replace

/********************/
/* RUN masala merge */
/********************/
use $tmp/pc91_$SHORT, clear

lev_merge pc01_state_id pc01_district_id pc01_subdistrict_id using $tmp/pc01_$SHORT, s1(village_name) out($tmp/matches_$SHORT) sortwords

/* generate matches we know to be correct */
gen true_match = id91 == id01 if !mi(id91)

/* set acceptable thresholds for lev_merge */
count if _masala_merge == 3
local matches = `r(N)'

/* count number of matches that were accurate */
qui count if true_match == 1 & _mas == 3
local correct = `r(N)'

/* calculate error rate */
local error_rate = (`matches' - `correct') / `matches'

/* to calculate the find rate, need to see how many duplicate ids we have in non-matches */

/* doublecheck -- 91 or 01 must be missing if we didn't match */
assert (mi(id91) | mi(id01)) if _mas < 3
gen loc_id = pc01_state_id + "-" + pc01_district_id + "-" + pc01_subdistrict_id if _mas < 3
replace loc_id = loc_id + "-" + string(id91) if !mi(id91)
replace loc_id = loc_id + "-" + string(id01) if !mi(id01)

/* duplicate loc_ids indicate we should have been able to match these */
duplicates tag loc_id if _mas < 3, gen(dup)
assert dup < 2 | mi(dup)
count if dup == 1
local missed = `r(N)' / 2

local find_rate = (`correct' / (`correct' + `missed'))

disp_nice "2015-01-17: ERROR RATE: 0.0122, FIND RATE: 0.750"

disp_nice "ERROR RATE: `error_rate'"
disp_nice "FIND RATE:  `find_rate'"

assert `error_rate' < 0.0122
assert `find_rate' > 0.749



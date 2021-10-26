do ~/include
use $keys/pc9101r_key_unique, clear

keep pc91_village_name pc01_village_name pc01_state_id pc01_district_id pc01_subdistrict_id 
gen id = _n

gen name91 = pc91_village_name
gen name01 = pc01_village_name 

name_clean pc01_village_name
name_clean pc91_village_name

keep if pc91_village_name != pc01_village_name & !mi(pc91_village_name) & !mi(pc01_village_name)

/* match these within subdistricts as if we don't know what the match is */

/* save pc01 version */
preserve
keep pc01_village_name pc01_state_id pc01_district_id pc01_subdistrict_id name01 id
ren id id01
ren pc01_village_name village_name
duplicates drop pc01_state_id pc01_district_id pc01_subdistrict_id village_name , force
save $tmp/pc01, replace
restore

/* prep pc91 version */
keep pc91_village_name pc01_state_id pc01_district_id pc01_subdistrict_id name91 id
ren id id91
ren pc91_village_name village_name
duplicates drop pc01_state_id pc01_district_id pc01_subdistrict_id village_name , force
save $tmp/pc91, replace

lev_merge pc01_state_id pc01_district_id pc01_subdistrict_id using $tmp/pc01, s1(village_name) out($tmp/matches) dist(4)

use $tmp/matches, clear

ren village_name_master village_name
merge m:1 pc01_state_id pc01_district_id pc01_subdistrict_id village_name using $tmp/pc91, gen(_merge91)
ren village_name pc91_village_name

ren village_name_using village_name
merge m:1 pc01_state_id pc01_district_id pc01_subdistrict_id village_name using $tmp/pc01, gen(_merge01)
ren village_name pc01_village_name 

/* calculate word length */
gen length = floor((length(pc91_village_name) + length(pc01_village_name)) / 2)
save $tmp/foo, replace

/* drop places with length < 4 - not reasonable for fuzzy matching */
drop if length < 4

/* generate matches we know to be correct */
gen true_match = id91 == id01

/* drop places with lev_dist = 0: these bias results since we have dropped all */
drop if master_dist_best == 0

/* we want to know the optimal stopping point for each string length.

we have length, lev_dist, true_match, dist_second - dist_best

for each length:
  for each lev_dist threshold:
    report # correct / # true matches
    report # wrong / (# correct + # wrong)

categorize required margin to consider this match specific. try three
alternatives to limit # possibilities that need ot be checked.
1. m = 0.5
2. m = 0.4 + 0.5 * lev_dist
3. m = 0.4 + 0.25 * lev_dist

*/

/* arbitrarily focus on master */

/* define margin groups */
gen margin = master_dist_second - master_dist_best

/* dichotomous variables determine whether match has sufficient margin */
gen m1 = margin > 0.5 if !mi(margin)
gen m2 = margin > (0.4 + .5 * master_dist_best)
gen m3 = margin > (0.4 + .25 * master_dist_best)

/* store outcomes in new data fields */
gen row_number = _n
foreach i in error_rate emp_matches true_matches correct find_rate lev_threshold margin_group len n {
  gen `i' = .
}
local count = 0
forval length = 4/20 {

  di "LENGTH == `length'..."
  foreach margin in 1 2 3 {
  
    forval lev_threshold = 0.1(0.1)4 {

      cap drop my_match
      gen my_match = (lev_dist < `lev_threshold') & (m`margin' == 1)

      qui count if length == `length' & my_match == 1
      local matches = `r(N)'

      qui count if length == `length' & true_match == 1
      local true_matches = `r(N)'

      qui count if length == `length' & true_match == 1 & my_match == 1
      local correct = `r(N)'

      local error_rate = (`matches' - `correct') / `matches'
      local find_rate  = (`correct' / `true_matches')

      /* store results */
      qui replace emp_matches = `matches' if row_number == `count'
      qui replace true_matches = `true_matches' if row_number == `count'
      qui replace correct = `correct' if row_number == `count'
      qui replace error_rate = `error_rate' if row_number == `count'
      qui replace find_rate = `find_rate' if row_number == `count'
      qui replace lev_threshold = `lev_threshold' if row_number == `count'
      qui replace margin_group = `margin' if row_number == `count'
      qui replace len = `length' if row_number == `count'
      qui replace n = `true_matches' if row_number == `count'
      
      /* increment storage counter */
      local count = `count' + 1
    }
  }
}



/* save output */
keep error_rate emp_matches true_matches correct find_rate lev_threshold margin_group len n
ren len length
keep if !mi(n)
order length margin_group lev_threshold n find_rate error_rate emp_matches true_matches correct
save $iec/tmp/fuzzy, replace

/* fix error rate at 3%, margin group 3 */
global error_rate .03

/* margin group 3 */
bys length: egen best_find_rate3 = max(find_rate * (error_rate < $error_rate)) if margin_group == 3
sort length lev_threshold
list length lev_thresh best_find_rate3 find_rate error_rate margin_group n if float(best_find_rate3) == float(find_rate)

/* margin group 2 */
bys length: egen best_find_rate2 = max(find_rate * (error_rate < $error_rate)) if margin_group == 2
sort length lev_threshold
list length lev_thresh best_find_rate2 find_rate error_rate margin_group if float(best_find_rate2) == float(find_rate)

/* repeat with .05 error rate */
global error_rate .05

/* margin group 3 */
bys length: egen best_find_rate3b = max(find_rate * (error_rate < $error_rate)) if margin_group == 3
sort length lev_threshold
list length lev_thresh best_find_rate3b find_rate error_rate margin_group if float(best_find_rate3b) == float(find_rate)

/* margin group 2 */
bys length: egen best_find_rate2b = max(find_rate * (error_rate < $error_rate)) if margin_group == 2
sort length lev_threshold
list length lev_thresh best_find_rate2b find_rate error_rate margin_group if float(best_find_rate2b) == float(find_rate)

/* repeat with .01 error rate */
global error_rate .01

/* margin group 3 */
bys length: egen best_find_rate3c = max(find_rate * (error_rate < $error_rate)) if margin_group == 3
sort length lev_threshold
list length lev_thresh best_find_rate3c find_rate error_rate margin_group if float(best_find_rate3c) == float(find_rate)

/* margin group 2 */
bys length: egen best_find_rate2c = max(find_rate * (error_rate < $error_rate)) if margin_group == 2
sort length lev_threshold
list length lev_thresh best_find_rate2c find_rate error_rate margin_group if float(best_find_rate2c) == float(find_rate)

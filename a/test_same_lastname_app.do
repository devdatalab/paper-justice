/*******************************************************************************************************************************************/
* TABLE - create a table of most common surnames and corresponding defendant, judge and case frequencies associated with this last name  */
/*******************************************************************************************************************************************/

/* set code timer */
tgo

/* open justice name analysis file */
use $jdata/justice_same_names, clear

/* rank defendant last names by frequency */
bysort dgroup: egen dfreq = count(dgroup)
gsort -dfreq
gen rank = sum(dfreq != dfreq[_n-1])

/* label vars */
la var dfreq "No. of defendants with surname"
la var rank "Rank by most common defendant surname"

save $tmp/same_names, replace

/* count number of cases which have this common surname */
bys dgroup: egen cfreq = count(dgroup) if same_last_name == 1

/* save surname, rank and frequency of defendants and cases */
collapse rank dfreq cfreq, by(def_last_name)
rename def_last_name last_name
save $tmp/dcount, replace

/* for count of judges with this surname collapse by judge_last_name */
use $tmp/same_names, clear

/* tabulate frequencies of judge_last_names */
bysort jgroup: egen jfreq = count(jgroup)
collapse jfreq, by(judge_last_name)

/* merge with temp file dcount which has frequency by defendant name and cases */
rename judge_last_name last_name
merge 1:1 last_name using $tmp/dcount

/* gen percentage of defendant names with each surname */
egen sum_dfreq = sum(dfreq)
gen dperc = (dfreq / sum_dfreq) * 100
format dperc %3.1f

/* sort and order into columns */
gsort -_merge rank
gen slno = _n
order slno last_name rank dfreq dperc jfreq cfreq, first

/* label vars */
la var last_name "Surname"
la var slno "Serial Number"
la var cfreq "No. of cases where defendant and judge share surname"
la var dperc "% of defendants with surname"
la var jfreq "No. of judges with surname"

/* store table with all surnames */
export delimited $tmp/surname_table.csv, replace

/* keep only the names that matched between judge and def last name - 609*/
keep if _merge == 3
drop _merge
drop sum_dfreq //2744399

/* keep only 100 most common surnames for tex output */
keep if slno <= 30

/* this command does not write a long table across pages */
texsave * using $out/surname_freq_table.tex, replace varlabels frag

/* extract begin and end table lines from the output tex file */
shell grep -v 'begin.*table' $out/surname_freq_table.tex | grep -v 'end.*table' > $out/tmp.tex && mv $out/tmp.tex $out/surname_freq_table.tex
cat $out/surname_freq_table.tex

/*******************************************************************************************************/
* GRAPH - graph of how many common surnames need to be dropped before the estimate becomes substantial */
* x axis - log share of names dropped
* y axis - estimate from same surname regression on rate of acquittal

* Drop ranks 1 to 10 serially and then 5 at a time
/******************************************************************************************************/

use $tmp/same_names, clear
cap erase $tmp/rare_names_analysis.csv
append_to_file using $tmp/rare_names_analysis.csv, s("b,se,p,n,rank,wt,coef,share_rare")

/* identify the max rank */
sum rank, meanonly
local N = r(max)

keep acq same_last_name same_rare def_female def_muslim wt dgroup jgroup loc_month acts rank

/* start the timer */
tgo

/* loop over the ranks */
forval r = 0/`N' {

  /* skip by 2 for the first 10, then by 20 */
  if mod(`r', 2) != 0 continue
  if (`r' > 10) & mod(`r', 20) != 0 continue
  
  /* show elapsed time and restart timer */
  timer off 1
  timer list 1
  timer on 1
  
  disp_nice "Interacting rare = rank > `r'"

  /* define rare, meaning "more rare than rank `r'", and interact it with same */
  capdrop rare same_rare
  gen rare = rank > `r' if !mi(rank)
  gen same_rare = same_last_name * rare
  
  /* run the column 5 specification with this definition of rare */
  /* note no "rare" since it's captured by dgroup */
  
//  reghdfe acq same_last_name same_rare def_female def_muslim [pw=wt], absorb(acts)
  reghdfe acq same_last_name same_rare def_female def_muslim [pw=wt], absorb(dgroup jgroup loc_month acts)

  /* count the share of obs classified as rare */
  count if rare == 1
  local N_rare = `r(N)'
  local share_rare = `N_rare' / _N
  
  /* store the main and interaction coefs */
  append_est_to_file using $tmp/rare_names_analysis.csv, suffix("`r',1,same,`share_rare'") b(same_last_name)
  append_est_to_file using $tmp/rare_names_analysis.csv, suffix("`r',1,same_rare,`share_rare'") b(same_rare)

/* repeat unweighted */
  reghdfe acq same_last_name same_rare def_female def_muslim , absorb(dgroup jgroup loc_month acts)
  append_est_to_file using $tmp/rare_names_analysis.csv, suffix("`r',0,same,`share_rare'") b(same_last_name)
  append_est_to_file using $tmp/rare_names_analysis.csv, suffix("`r',0,same_rare,`share_rare'") b(same_rare)
  
  /* compute log share of names dropped  */
  distinct dgroup if rank > `r' & !mi(rank)
  local z = r(ndistinct)
  local x = (`N'-`z')/`N'

  /* store this in the same csv so we can graph it  */
  insert_into_file using $tmp/rare_names_analysis.csv, key(x_`r') value(`x')

  /* break out of loop if standard error of interest is too large */
  if (_se[same_last_name]>0.1) {
    di "Standard error > 0.1 once rank > `r'."
    continue, break
  }
}

/* import the csv to create the graph */
copy $tmp/rare_names_analysis.csv $out/rare_names_analysis.csv, replace


/* ------------------ cell: make the output graph ----------------- */
import delimited using $out/rare_names_analysis.csv, clear

drop if substr(b, 1, 1) == "x"
destring b, replace

/* create standard errors */
gen b_high = b + 1.96 * se
gen b_low  = b - 1.96 * se

/* stop when SE of interaction is greater than 0.1  */
// gen tmp = b_high - b_low
// bys rank: egen se_inter = max(tmp)
// replace rank = . if se_inter > .1
// replace rank = . if rank > 500

/* discard some redundant intermediate ranks to make graph less over-packed, and high large SE ranks */
drop if inlist(rank, 0, 2, 4, 6, 8) | rank > 420
drop if rank > 420

/* nudge the X axis rank values so they don't overlap */
replace rank = rank + 1 if coef == "same_rare"
replace rank = rank - 1 if coef == "same"

drop if mi(rank) | mi(share_rare)

twoway ///
    (rcap b_high b_low rank if wt == 1 & coef == "same", lwidth(medthick))  ///
    (scatter b rank if wt == 1 & coef == "same", msymbol(T)) ///
    (rcap b_high b_low rank if wt == 1 & coef == "same_rare", lwidth(medthick))  ///
    (scatter b rank if wt == 1 & coef == "same_rare", color(black))          ///
    , legend(ring(0) pos(2)  order(2 "Base Coef" 4 "Rare Interaction") ) ///
    xtitle("Number of defendant last names classified as common") ///
    ytitle("Coefficient (s.e.)") ylab(-.02(.02).1) yline(0, lwidth(medium) lcolor(gs8) lpattern(solid))
  
graphout rare_names_weighted, pdf

twoway ///
    (rcap b_high b_low rank if wt == 0 & coef == "same", lwidth(medthick))  ///
    (scatter b rank if wt == 0 & coef == "same", msymbol(T)) ///
    (rcap b_high b_low rank if wt == 0 & coef == "same_rare", lwidth(medthick))  ///
    (scatter b rank if wt == 0 & coef == "same_rare", color(black))          ///
    , legend(ring(0) pos(2)  order(2 "Base Coef" 4 "Rare Interaction") ) ///
    xtitle("Number of defendant last names classified as common") ///
    ytitle("Coefficient (s.e.)") ylab(-.02(.02).1) yline(0, lwidth(medium) lcolor(gs8) lpattern(solid))
  
graphout rare_names_unweighted, pdf

/******************************************************************************************************/
/* Balance test for defendants being assigned to judges with same last names*/

/* Plotting a kdensity graph for the balance regression for 50 of the most common defendant surnames */
/*****************************************************************************************************/

/* load temp dataset which has the rank variable. This is the ranking of the most common defendant surnames by frequency */
use $tmp/same_names, clear

/* generate flag variables which represent cases where the judge/defendant have each of the common surnames */
gen def_surname_flag = 0
gen judge_surname_flag = 0

/* loop over 50 of the most common defendant surnames */
levelsof def_last_name if rank < 500, local(unique_surnames)
local i = 1
foreach name in `unique_surnames' {

  di "`i': `name'"
  local i = `i' + 1

  /* store the rank */
  sum rank if def_last_name == "`name'"
  local rank = `r(mean)'
  
  /* switch flags to 1 for all the cases where the judge or defendant have the surname that the current loop variable represents.
  We then run a regression to check whether defendants are more likely to be assigned to judges who share their surname. */
  
  /* note: we divide def_surname_flag by 100 to make the reg coef 100x larger, since
           insert_est_into_file is hard-coded a 3 decimal points, which would be 0.000 for most of these.
           we the divide the coef by 100 in the analysis below, reversing this change. */
  replace def_surname_flag = 0.01 if def_last_name == "`name'" 
  replace judge_surname_flag = 1 if judge_last_name == "`name'"

  /* run the match test. */
  reghdfe judge_surname_flag def_surname_flag, absorb(acts loc_year) cluster(judge)

  /* store the estimates in a csv so we can plot it */
  insert_est_into_file using "$out/balance_same_surname.csv", spec(reg_`name'_`rank') b("def_surname_flag")

  /* switch the flags back to zero so that we can reassign them for the next surname */  
  replace def_surname_flag = 0
  replace judge_surname_flag = 0
}  
tstop

/* Kdensity graph of coefficients for the balance regression */

/* open the csv with the estimates */
import delimited using $out/balance_same_surname.csv, clear

/* rename the variables something easier to interpret */
ren v1 spec
ren v2 value

/* drop star beta rows which are non-numeric */
drop if strpos(spec, "starbeta") | strpos(spec, "r2")

/* convert reg results to numbers */
destring value, replace

/* manually reshape to get all the coefs in wide */
replace spec = substr(spec, 5, .)
gen group = substr(spec, 1, strpos(spec, "_") - 1)
replace spec = substr(spec, strpos(spec, "_") + 1, .)

/* get the group rank into a variable */
gen rank = substr(spec, 1, strpos(spec, "_") - 1)
replace spec = substr(spec, strpos(spec, "_") + 1, .)

foreach v in beta se p n {
  gen tmp = value if spec == "`v'"
  bys group: egen `v' = max(tmp)
  drop tmp
}

/* rescale beta and se since we divided the x-var by 100 in the regressions */
replace beta = beta / 100
replace se = se / 100

/* finish the reshape by dropping redundant rows */
tag group
keep if gtag
drop value spec

/* graph the coefficients */
kdensity beta, graph xtitle("Coefficient for the balance regression") title("Balance regression estimate for defendant and judge sharing the same last name")
graphout name_balance_coef_density, pdf

/* create error bars */
gen beta_high = beta + 1.96 * se
gen beta_low  = beta - 1.96 * se

/* make the rcap graph */
sort beta
gen i = _n
twoway (rcap beta_high beta_low i) (scatter beta i), yline(0) legend(off) xlabel(none) xtitle("") ytitle("Balance Coefficient")
graphout name_balance_coef_rcap, pdf




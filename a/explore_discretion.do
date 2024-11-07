/* bring in justice analysis dataset */
use $jdata/justice_analysis, clear

/* drop if missing any of the ids we need */
drop if mi(acts) | mi(loc_month) | mi(judge) | mi(acquit)

/* review acquittal rates under various definitions */
sum acq
sum acq if !mi(decision_date)
sum acq if !mi(decision_date) & ambiguous == 0

/* keep the non-ambiguous decisions for studying judge influence */
keep if ambiguous == 0 & !mi(decision_date)

/***********************************************************************/
/* show amount of residual variation explained by judge fixed effects. */
/***********************************************************************/

/* reg acquittal rates on court time and act FE */
reghdfe acq, absorb(acts loc_month)
local r2_base  = e(r2)

/* add judge FE */
reghdfe acq, absorb(acts loc_month judge)
local r2_post = e(r2)

di "Variation explained by judge: " (`r2_post' - `r2_base') / (1 - `r2_base')

/****************************************/
/* show distribution of judge residuals */
/****************************************/

/* drop fixed effect groups with only one judge */
egen g1 = tag(acts judge)
bys acts: egen acts_num_judges = total(g1)

egen g2 = tag(loc_month judge)
bys loc_month: egen loc_num_judges = total(g2)

sum acts_num_judges, d
sum loc_num_judges, d
drop if acts_num_judges <= 1
drop if loc_num_judges <= 1

/* calculate acquittal residuals on acts and loc_month */
reghdfe acq, absorb(acts loc_month) resid
predict resid, resid

/* calculate the average residual for each judge */
bys judge: egen judge_mean_resid = mean(resid)

/* tag each judge */
tag judge

/* see the distribution of residuals */
sum judge_mean_resid if jtag, d

/* note we truncate the histogram at +/- to avoid confusion --- but some
  rates are outside of -1/+1 because they are residual on two types of fixed
  effects -- the court and the location-month. */
histogram judge_mean_resid if jtag & inrange(judge_mean_resid, -1, 1), xtitle("Residual of judge mean acquittal rate")
graphout judge_acquittal_resids, pdf



exit
exit


/* collapse residual by judge and defendant religion */
preserve
collapse (mean) resid, by(judge def_muslim)
save $tmp/resid_judge_dr, replace
restore

/* collapse residual by judge and defendant gender */
preserve
collapse (mean) resid, by(judge def_male)
save $tmp/resid_judge_dg, replace
restore

/* plot residuals by defendant gender */
use $tmp/resid_judge_dg, clear

/* reshape data */
drop if mi(def_male)
reshape wide resid, i(judge) j(def_male)

/* calculate differences between male and female averages */
gen diff_gender = resid1 - resid0

/* plot graph */
hist diff_gender, xtitle("Residual average difference for each judge between male and female defendants")
graphout resid_g

/* plot residuals by defendant religion */
use $tmp/resid_judge_dr, clear

/* reshape data */
drop if mi(def_muslim)
reshape wide resid, i(judge) j(def_muslim)

/* calculate differences between mus and non-mus averages */
gen diff_religion = resid1 - resid0

/* plot graph */
hist diff_religion, xtitle("Residual average difference for each judge between Muslim and non-Muslim defendants")
graphout resid_r




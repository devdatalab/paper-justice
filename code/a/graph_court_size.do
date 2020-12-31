/* import rct analysis sample */
use $jdata/justice_analysis, clear

/* drop bail obs */
drop if bail == 1

/* calculate court size */
egen tag = tag(loc judge)
egen rct_court_size = total(tag), by(loc)

/* drop duplicate cinos to facilitate merge (0.22% of data) */
duplicates drop cino, force

/* keep vars we need */
keep cino rct_court_size

/* merge with event study analysis dataset */
merge 1:m cino using $jdata/justice_event_analysis, nogen keepusing(num_judges bail)

/* rename event study court size */
ren num_judges event_court_size

/* label both variables */
la var rct_court_size "RCT sample court size (Median: 5)"
la var event_court_size "Event study sample court size (Median: 2)"

/* graph distribution of court size */
set scheme pn
twoway (kdensity rct_court_size if !mi(rct_court_size) & rct_court_size < 15) (kdensity event_court_size if !mi(event_court_size) & bail != 1, ytitle("Kernel Density") xtitle("Court size")), ///
note("Note: The median courts in the RCT and event study samples have 5 judges and 2 judges respectively") legend(label(1 "RCT court size") label(2 "Event study court size"))

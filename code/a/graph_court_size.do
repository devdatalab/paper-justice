/* import rct analysis sample */
use $jdata/justice_analysis, clear

/* drop bail obs */
drop if bail == 1

/* calculate court size */
egen tag = tag(state_code district_code court judge)
egen rct_court_size = total(tag), by(state_code district_code court)

/* keep vars we need */
keep ddl_case_id rct_court_size

/* label both variables */
la var rct_court_size "Court size distribution (Median: 5)"

/* graph distribution of court size */
set scheme pn
twoway histogram rct_court_size if !mi(rct_court_size) & rct_court_size < 15, width(1) color(cranberry) ///        
        legend(off) xtitle("No. of judges in court") text(.12 5.8 "Median: 5", size(small)) xline(5)
graphout court_size, png

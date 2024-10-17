/***************************************************************************************/
/* Show main RCT results for different time periods: pre/post 2014, and in 2-year bins */
/***************************************************************************************/

/* start a timer */
tgo //9.04 minutes

/* import analysis dataset */
use $jdata/justice_analysis, clear

/*********************************************************************************/
/* table: Own religion bias regressions separately for pre and post 2014 periods */
/*********************************************************************************/

eststo clear

/* column 1 specification, pre 2014 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim if (filing_year >= 2010 & filing_year <= 2014) , absorb(loc_month acts) cluster(judge) 
estadd local FE "Court-month"
estadd local Sample "2010--14"
eststo reg1

/* column 1 specification, post 2014 */
reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim if (filing_year >= 2015 & filing_year <= 2018) , absorb(loc_month acts) cluster(judge)
estadd local FE "Court-month"
estadd local Sample "2015--18"
eststo reg2

/* save table to tex */
esttab reg1 reg2 using "$out/rct_prepost_2014.tex", replace label b(4) se(4) ///
    s(N FE Sample, label( "Observations" "Fixed Effect" "Sample") fmt(0 0 0) ) drop(_cons) ///
    mtitles("Acquitted" "Acquitted" ) booktabs nostar nonote


/***************************************************************************************/
/* Table: results in 2-year bins (with first bin 2010-2012 since it is smaller sample) */
/***************************************************************************************/


/* specify the four bins we want */
local bin1_start 2010
local bin1_end   2012
local bin2_start 2013
local bin2_end   2014
local bin3_start 2015
local bin3_end   2016
local bin4_start 2017
local bin4_end   2018

eststo clear

forval i = 1/4 {  

  reghdfe acquitted judge_nonmuslim def_nonmuslim judge_def_nonmuslim if inrange(year, `bin`i'_start', `bin`i'_end') , absorb(loc_month acts) cluster(judge)
  estadd local FE "court-month"
  estadd local sample "`bin`i'_start'-`bin`i'_end'" 
  eststo reg`i'
}

esttab reg* using "$out/rct_2year_bins.tex", replace label b(4) se(4) nostar nonote s(N FE sample, label( "Observations" "Fixed Effect" "Sample") fmt(0 0 0) ) drop(_cons) mtitles("Acquitted" "Acquitted" "Acquitted" "Acquitted") booktabs

/* stop the timer */
tstop

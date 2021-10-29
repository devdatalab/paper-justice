/* make a test folder */
cap mkdir $tests/masala_merge
global testdir $tests/masala_merge

/* core idea of tests: match winners from ADR to winners from ECI */


/* creates core datasets for running masala-merge tests */
use $adr/adr_candidates_combined, clear

/* create a small dataset to use for the tests */
keep if bye_election == 0
keep ac_id year adr_cand_name party adr_cand_id winner age source pc01_state_name any_crim

/* rename candidate name for matching to Trivedi election data */
ren adr_cand_name cand_name

/* generate unique identifiers -- one string, and one numeric */
gen _adr_id = _n
tostring _adr_id, gen(_adr_id_string)

/* keep only a few years to make the test run faster */
keep if inrange(year, 2004, 2007) & inlist(pc01_state_name, "gujarat", "anhdra pradesh")

/* force unique and save */
ddrop ac_id year cand_name 

/* save master test dataset */
save $testdir/adr_candidates_test, replace

/* prepare using side dataset from Trivedi  */
use $elections/trivedi_candidates_clean, clear
keep if poll_no == 0
keep year ac_id position cand_name party age sh_cand_id pc01_state_name sex

/* keep same years as above */
keep if inrange(year, 2004, 2007) & inlist(pc01_state_name, "gujarat", "anhdra pradesh")

/* keep candidates in top 5 positions */
keep if position <= 5

/* generate numeric and string ids */
gen _tr_id = _n
tostring _tr_id, gen(_tr_id_string)

/* force unique and save */
ddrop ac_id year cand_name
save $testdir/tr_candidates_test, replace

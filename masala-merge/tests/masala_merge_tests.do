global testdir $tests/masala_merge
do ~/iecmerge/include

/**********************************************************************/
/* program verify_merge: Confirm a merge returned plausible results   */
/**********************************************************************/
cap prog drop verify_merge
prog def verify_merge
{
  /* confirm at least some matches found */
  obs_check if _merge == 3, n(40)

  /* confirm master side variables kept */
  obs_check if !mi(any_crim), n(40)

  /* confirm string on both sides of match were kept */
  obs_check if !mi(cand_name_master) & !mi(cand_name_using), n(40)
  
}
end
/** END program verify_merge ******************************************/


/*******************************************/
/* standard masala-merge, string identifiers */
/*******************************************/
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string)

/* run basic checks */
verify_merge

/* confirm using side variables kept */
obs_check if !mi(sex), n(100)

/* confirm no manual matches made */
assert match_source != 5

/* match source and _merge should exist for all obs */
assert !mi(_merge) & !mi(match_source)

/* count matches to check against fuzziness() setting below */
count if _merge == 3
global n_main_match = `r(N)'

/* save the merge results to be used later */
save $testdir/test_merge_results, replace

/***********************/
/* numeric identifiers */
/***********************/
// use $testdir/adr_candidates_test, clear
// masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id) idusing(_tr_id)
// verify_merge

/**************************************/
/* one string, one numeric identifier */
/**************************************/
// use $testdir/adr_candidates_test, clear
// masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id)
// verify_merge

// use $testdir/adr_candidates_test, clear
// masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id) idusing(_tr_id_string)
// verify_merge

/*********************************/
/* with manual replacements file */
/*********************************/
// CREATE A STRING FILE IN masala-merge/tests/strings/ AND REQUIRE IT. ASSERT THAT THE MATCH FROM THE STRING FILE WAS MADE


/***********************/
/* reclink or lev only */
/***********************/
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) method(rlonly)
verify_merge

/* this is rl only so we shouldn't have any lev matches */
assert !inlist(match_source, 2, 3)

/* repeat for levonly */
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) method(levonly)
//verify_merge --> lev only comes up with 16 matches
assert !inlist(match_source, 2, 4)



/**********************/
/* increase fuzziness */
/**********************/

/* run basic test with higher fuzziness */
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) fuzziness(4)
verify_merge

/* we should get more matches */
count if _merge == 3
assert `r(N)' > $n_main_match

/************/
/* listvars */
/************/

/* listvars, unsorted */
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) listvars(age)
verify_merge

/* assert that the output csv file contains a head */
// NOTE: we need to make it an rclass program that returns the CSV file in a string, so we can use it programmatically

/* listvars, sorted */
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) listvars(age) csvsort(age)
verify_merge

/*****************************************************************************/
/* verify other params work don't crash, even if we don't test their outputs */
/*****************************************************************************/

/* nopreserve */
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string)  nopreserve
verify_merge

/* minscore */
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) minscore(.7)
verify_merge

/* minbigram */
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) minbigram(.7)
verify_merge

/*************/
/* keepusing */
/*************/
use $testdir/adr_candidates_test, clear
masala_merge ac_id year using $testdir/tr_candidates_test, s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) keepusing(position)
verify_merge

/* position variable should exist, sex should not */
cap confirm variable position
assert _rc == 0
cap confirm variable sex
assert _rc == 111


/***************************/
/*  No matches in the data */
/***************************/

/* create versions of the master and using data that have no matches in them */
foreach i in master using {

  /* set id for each side */
  if "`i'" == "master" {
    local id adr
  }
  if "`i'" == "using" {
    local id tr
  }
  
  /* open the merge results */
  use $testdir/test_merge_results, clear

  /* keep only one side */
  keep if !mi(_`id'_id_string)

  /* drop the matches */
  drop if _merge == 3
  drop _merge

  /* save as a tempfile */
  tempfile nomatches
  save `nomatches'
  
  /* open the raw master/using data, merge in the non-matches to keep only those without a match */
  use $testdir/`id'_candidates_test, clear
  merge m:1 _`id'_id_string using `nomatches', keep(match) keepusing(_`id'_id_string) nogen
  
  /* save as a tempfile */
  tempfile no_matches_`i'
  save `no_matches_`i''
}

/* reload the maaster file with no matches */
use `no_matches_master', clear

/* execute masala_merge with the no-match using side */
masala_merge ac_id year using `no_matches_using', s1(cand_name) idmaster(_adr_id_string) idusing(_tr_id_string) 

/* assert that there are no matches */
assert _merge != 3

/* assert that the match source is unmathced */
assert match_source >= 6


// some tests to add:
//                 - data with no overlapping groups
//                 - data with no matches


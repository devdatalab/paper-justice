/***************************/
/* Clean delhli voter list */
/***************************/

/* This do file takes prepares the delhi voter list to be the training set for 
name classification (religion and gender). 

I. Full name cleaning: combine first and last names and clean characters
II. Individual name cleaning: split words in the full name and apply logic-cleaning rules
III. Split first and last names
   A. Stack all first names
   B. Save first and last names

input:
$jdata/names/delhi_voter_list_unclean.dta: raw names from delhi voter list

output:
$jdata/names/delhi_voter_list_clean.dta: full names from delhi voter list, cleaned with all variables
$jdata/names/delhi_full_names_clean.dta: full names from delhi voter list, cleaned with names, gender, religion
$jdata/names/delhi_first_names_clean.dta: first names from delhi voter list, cleaned with names, gender, religion
$jdata/names/delhi_last_names_clean.dta: last names from delhi voter list, cleaned with names, gender, religion
*/
 
/* open the raw delhi voter list data */
use "$jdata/names/delhi_voter_list_unclean.dta", clear

/*************************/
/* I. Full name cleaning */
/*************************/
/* append the first and last names to create one full name */
gen full_name = first_name + " " + last_name

/* make the full name lower case */
replace full_name = lower(full_name)

/* replace these special characters with a space */
replace full_name = subinstr(full_name, ".", " ", .)
replace full_name = subinstr(full_name, "-", " ", .)

/* remove any characters that are not letters or a space from the names*/
egen _temp = sieve(full_name), char(abcdefghijklmnopqrstuvwxyz )

/* trim leading, trailing, and duplicated internal spaces */
replace full_name = trim(itrim(_temp))
drop _temp

/* save the full dataset with full, cleaned names */
save $jdata/names/delhi_voter_list_clean.dta, replace

/*********************************/
/* II. Individual name cleaning */
/********************************/
/* count the words in the full name */
gen wordcount = wordcount(full_name)

/* split the full name on spaces */
split full_name, gen(name_) p(" ")

/* find the maximum number of woords in any name */
qui sum wordcount
local n = `r(max)'

/* cycle through the individual names and apply cleaning logic */
forval i = 1/`n' {

  /* 1. Drop names with only 1 unique letter (repeated or single) */
  /* count how many unique letters are in each name */
  gen _unique_letters = 0
  foreach l in a b c d e f g h i j k l m n o p q r s t u v w x y z {
    replace _unique_letters = _unique_letters + regexm(name_`i', "`l'")
  }
  /* clear all names that only have 1 unique letter */
  replace name_`i' = "" if _unique_letters == 1
  drop _unique_letters

  /* 2. Drop any names that don't have a vowel, except for "md" (a known abbreviation for mohammed) */
  replace name_`i' = "" if (strpos(name_`i', "a")==0 & strpos(name_`i', "e")==0 & strpos(name_`i', "i")==0 & strpos(name_`i', "o")==0 & strpos(name_`i', "u")==0 & strpos(name_`i', "y")==0) & strpos(name_`i', "md")==0
}

/************************************/
/* III. Split first and last names */
/***********************************/
/* rename the old first and last name variables */
ren first_name old_first
ren last_name old_last

/* create an empty last_name variable */
gen last_name = ""

/* cycle through the split names to find the last name */
forval i = 1/`n' {

  /* replace the last name with the proper name split (the last word in the full name) */
  replace last_name = name_`i' if wordcount == `i'

  /* now that it is the last name, drop its name split */
  replace name_`i' = "" if wordcount == `i'
}

/* join the remaining names to create the first name field */
egen first_name = concat(name_*), punct(" ")

/* correction: if there was only one name as the first name and no last name,
   set it to be the first name and set the last name to missing */
replace first_name = full_name if wordcount == 1 & mi(old_last)
replace last_name = "" if wordcount == 1 & mi(old_last)

/* generate binary indicator for female, missing values are unkown gender (~.01%) */
gen female = 1 if gender == "F"
replace female = 0 if gender == "M"

/* abbreviate religions as single letter codes */
replace religion = ""
replace religion = "M" if religion_confidence == "Muslim"
replace religion = "H" if religion_confidence == "Hindu"
replace religion = "C" if religion_confidence == "Christian"
replace religion = "S" if religion_confidence == "Sikh"

/* replace the full name with first and last name */
replace full_name = first_name + " " + last_name
replace full_name = itrim(full_name)

/* save the complete data */
save $jdata/names/delhi_voter_list_clean, replace

/* save only the name, religion, and gender */
keep full_name religion gender female
save $jdata/names/delhi_voter_list_clean_full_names, replace

/******************************/
/* A. Combine all first names */
/******************************/
clear
tempfile first_name_data
gen first_name = ""
save `first_name_data'

/* cycle through all the names */
forval i = 1/`n' {
  
  /* open all the names */
  use $jdata/names/delhi_voter_list_clean, clear

  /* only keep non-missing names */
  keep if !mi(name_`i')

  /* only keep religion, gender, and this name split */
  keep name_`i' religion gender female

  /* rename to first_name */
  ren name_`i' first_name

  /* append to the rest of the names */
  append using `first_name_data'

  /* save */
  save `first_name_data', replace
}

/********************************/
/* B. Save first and last names */
/********************************/

/* save just the first names */
keep first_name religion gender female
drop if mi(first_name)
save $jdata/names/delhi_voter_list_clean_first_names, replace

/* save just the last names */
use $jdata/names/delhi_voter_list_clean, clear
keep last_name religion gender female
drop if mi(last_name)
save $jdata/names/delhi_voter_list_clean_last_names, replace

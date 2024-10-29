
/* This do file cleans the railway names to be used in LSTM classification of religion. 

-Clean Religion
-Intial full name clean 
-Individual name cleaning
-Split first and last names 
-Combine all first names

Input:
$jdata/names/railway_names_unclean: raw railway names

Output:
$jdata/names/railway_names_clean_full: cleaned full names as one string
$jdata/names/railway_names_clean_first: cleaned first names, all words preceding the last, stacked
$jdata/names/railway_names_clean_last: cleaned last names, only the last word of the name

*/

/* read in the data */
use $jdata/names/railway_names_unclean, clear

/******************/
/* Clean Religion */
/******************/
/* replace religion names with single letter codes */
gen temp = ""
replace temp = "M" if religion == "MUSLIM"
replace temp = "H" if religion == "HINDU"
replace temp = "C" if religion == "CHRISTIAN"
replace temp = "B" if religion == "BUDDHIST"
replace temp = "N" if religion == "NA"

/* replace the religion variable with the single letter codes */
drop religion
ren temp religion

/* drop if missing religion */
drop if mi(religion)

/***************************/
/* Initial Full Name Clean */
/***************************/
/* make the names all lowercase */
replace name = lower(name)

/* remove any characters that are not spaces or lower case letters */
egen full_name = sieve(name), char(abcdefghijklmnopqrstuvwxyz )

/* drop the original name variable and other unused variables */
drop name muslim wordcount

/* MANUAL REPLACEMENTS */
replace full_name = "mohd shahnawaz" if full_name == "m o h d  s h a h n a w a z"
replace full_name = "bishnu  ray" if full_name == "b i s h n u  r a y"
drop if regexm(full_name, "board of secondary education")

/* trim leading, trailing and duplicated internal spaces */
replace full_name = trim(itrim(full_name))

/* drop if missing full_name */
drop if mi(full_name)

/* save cleaned full names here */
save $jdata/names/railway_names_clean_full, replace

/****************************/
/* Individual name cleaning */
/****************************/
/* split the full name on spaces */
split full_name, gen(name_) p(" ")

/* count the words in the full name */
gen wordcount = wordcount(full_name)

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
  replace name_`i' = "" if (strpos(name_`i', "a")==0 & strpos(name_`i', "e")==0 & strpos(name_`i', "i")==0 & strpos(name_`i', "o")==0 & strpos(name_`i', "u")==0 & strpos(name_`i', "y")==0) & strpos(name_`i', "md")==0 & strpos(name_`i', "sk")==0
}

/* recount the words */
replace wordcount = wordcount(full_name)

/******************************/
/* Split first and last names */
/******************************/
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

/* correction: if there was only one name, also save it as a first name */ 
replace first_name = full_name if wordcount == 1

/* save as a tempfile */
tempfile all_names
save `all_names'

/* save the last names */
keep last_name religion
drop if mi(last_name)
save $jdata/names/railway_names_clean_last, replace

/***************************/
/* Combine All First Names */
/***************************/
clear
tempfile first_name_data
gen first_name = ""
save `first_name_data'

/* cycle through all the names */
forval i = 1/`n' {
  
  /* open all the names */
  use `all_names'

  /* only keep non-missing names */
  keep if !mi(name_`i')

  /* only keep religion, gender, and this name split */
  keep name_`i' religion

  /* rename to first_name */
  ren name_`i' first_name

  /* append to the rest of the names */
  append using `first_name_data'

  /* save */
  save `first_name_data', replace
}

/* save the first names */
keep first_name religion
drop if mi(first_name)
save $jdata/names/railway_names_clean_first, replace

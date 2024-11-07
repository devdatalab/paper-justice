/* This dofile:

i) checks the summary stats in Table A2: Summary of Name Classifier Training Datasets
ii) reproduces those statistics and stores them in the appropriate output directory

NB: exhibits/training_dist.tex has been manually created and is not generated by the code below

*/

/* load delhi voter rolls names data  */
use $jdata/names/delhi_voter_list_clean_full_names.dta, clear

/* fix 4 observations that don't get counted in current table (because of gender string case)  */
replace gender = upper(gender)

/* check obs count and gender distribution */
tab gender

/* store stats */
tabout gender using $out/training_gender_stats.csv, cells(freq col) replace

/* load the national railway exam names dataset  */
use $jdata/names/railway_names_clean_full.dta, clear

/* check obs count and religion distribution */
estpost tab religion

/*  store estimates from table */
tabout religion using $out/training_religion_stats.csv, cells(freq col) replace

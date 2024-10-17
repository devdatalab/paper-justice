import delimited using $jcode/b/lit_coefs.csv, clear

/* trim the variables */
replace study = strtrim(study)
replace name = strtrim(name)

/* fill in the outcome mean and se for this study */
replace outcome_mean = .231 if strpos(study, "ash")
replace outcome_sd = .178 if strpos(study, "ash")

/* calculate standard effect sizes for all studies */
/* [these are in the sheet already but missing for some studies] */
gen std_effect_size = coef / outcome_sd
gen std_se          = se   / outcome_sd

/* tag rows from this study */
gen this = substr(study, 1, 3) == "ash"

/* generate percentage effect */
gen perc_effect_size = coef / outcome_mean

save $jdata/lit_coefs, replace

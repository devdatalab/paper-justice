cap mkdir $tmp/lstm_results
cd $jcode/classifier

/**********/
/* GENDER */
/**********/

/* classify the names */
shell python -c "from classify_names import classify_gender; classify_gender('classify', model_fp='$jdata/delhi_names_gender.hdf5', data_fn='$jdata/sample_names.dta', output_fp='$tmp/lstm_results/names_female_class_sample.csv')"

/* import data */
import delimited using $tmp/lstm_results/names_female_class_sample.csv, clear

/* drop v1 index if it's there */
cap drop v1

/* process classified variables */
gen name_female = .
replace name_female = 1 if female >= 0.65 & !mi(female)
replace name_female = 0 if female < 0.35 & !mi(female)
replace name_female = -9999 if mi(name_clean)
replace name_female = -9998 if mi(name_female) 

/* format demographic vars */
cap label drop female
label define female 0 "0 male" 1 "1 female" -9998 "-9998 unclear" -9999 "-9999 missing name"
label values name_female female

/* keep vars we need */
keep name* female male name_female

/* save the key */
save $tmp/classified_gender, replace


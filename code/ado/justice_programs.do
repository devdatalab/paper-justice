/**********************************************************************************/
/* program store_validation_data : Write a warning/error to the log file if value > threshold  */
/**********************************************************************************/
cap prog drop store_validation_data
prog def store_validation_data
  syntax anything [using/], test_type(string) timestamp(string) sample(real) group(string)

  /* rename primary input for clarity */
  local validation_value "`anything'"
  
  /* set to $validationfile if not specified */
  if mi("`using'") {
    if mi("$validationfile") {
      di as error "no parameter or global \$validationfile was specified."
      error 345
    }
    local using $validationfile
  }
  
  /* if `flipsign' was passed in, switch the signs of all numbers */
  if !mi("`flipsign'") {

    /* confirm the passed in parameter is a number */
    if mi(real("`validation_value'")) {
      disp as error "`validation_value' could not be interpreted as a number"
      error 345
    }

    /* switch signs */
    local validation_value -`validation_value'
    local warning -`warning'
    local error -`error'
  }
  
  /* write the line to the error output data file */
  pyfunc write_validation_value(validation_datafile="`using'", timestamp="`timestamp'", test_type="`test_type'", group="`group'", validation_value="`validation_value'", sample_size="`sample_size'"), i(from validation.write_values import write_validation_value)
end
/* *********** END program store_validation_data ***************************************** */


/* PROGRAM TO STORE RESULTS FROM REGRESSIONS FOR STATA-TEX */
cap prog drop store_gender
prog def store_gender, rclass

  /* syntax */
  syntax, name(string) outcome(string) label(string)
  local o = "`outcome'"
  local col = "`name'"
  local lab = "`label'"
  
  /* store N */
  local obs `e(N)'

  /* store control mean */
  sum `o' if def_male == 0 & judge_male == 0 & e(sample) == 1
  local cont: di %9.3f `r(mean)'
  local cont_est "`cont'"     

  /* store effect of male judge on female defendant */
  local jfm: di %9.3f _b["judge_male"]
  local se: di %9.3f _se["judge_male"]
  local jfmse: di %9.3f _se["judge_male"]
  test judge_male = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local jfm_est "`jfm'`r(stars)'"
  if `p' > 0.1 local jfm_est "`jfm'"
  local jfm_ci: di %5.2f invttail(e(df_r),0.025)*_se["judge_male"]
  
  /* store effect of male judge on male defendant */
  local jff: di %9.3f (_b["judge_male"] + _b["judge_def_male"])
  lincom judge_male + judge_def_male 
  local se: di %9.3f `r(se)'
  local jffse: di %9.3f `r(se)'
  test judge_male + judge_def_male = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local jff_est "`jff'`r(stars)'"
  if `p' > 0.1 local jff_est "`jff'"
  lincom judge_male + judge_def_male
  local jff_ci: di %5.2f invttail(e(df_r),0.025)*(_se["judge_male"] + _se["judge_def_male"])
  
  /* store marginal effect of male judge on male defendant */
  local int: di %9.3f (_b["judge_def_male"])
  local se: di %9.3f _se["judge_def_male"]
  local intse: di %9.3f _se["judge_def_male"]
  test judge_def_male = 0
  local p: di %5.2f (`r(p)')
  count_stars, p(`p')
  local int_est "`int'`r(stars)'"
  if `p' > 0.1 local int_est "`int'"
  local int_ci: di %5.2f invttail(e(df_r),0.025)*_se["judge_def_male"]

  /* display results */
  di  %25s "`jfm_est'" %25s "`jff_est'" %25s "`int_est'" %15s "`col'"
  
  local demo "Male"
  local nondemo "Female"
  local identity "gender"
  
  /* store results into csv */
  insert_into_file using $tmp/gender_`o'.csv, key(o) value("`o'") 
  insert_into_file using $tmp/gender_`o'.csv, key(label) value("`lab'") 
  insert_into_file using $tmp/gender_`o'.csv, key(demo) value("`demo'") 
  insert_into_file using $tmp/gender_`o'.csv, key(nondemo) value("`nondemo'") 
  insert_into_file using $tmp/gender_`o'.csv, key(jfm_`col') value("`jfm_est'") 
  insert_into_file using $tmp/gender_`o'.csv, key(jff_`col') value("`jff_est'") 
  insert_into_file using $tmp/gender_`o'.csv, key(cmint_`col') value("`int_est'") 
  insert_into_file using $tmp/gender_`o'.csv, key(sefjm_`col') value("`jfmse'") 
  insert_into_file using $tmp/gender_`o'.csv, key(sefjf_`col') value("`jffse'") 
  insert_into_file using $tmp/gender_`o'.csv, key(seint_`col') value("`intse'") 
  insert_into_file using $tmp/gender_`o'.csv, key(cons_`col') value("`cont_est'") format(%25s)
  insert_into_file using $tmp/gender_`o'.csv, key(N_`col') value("`obs'") format(%25s)
  insert_into_file using $tmp/gender_`o'.csv, key(id) value("`identity'") format(%25s)

  /* return bias coefficient with stars */
  return local bias_beta `int_est'
end

/**********************************END PROGRAM STORE_GENDER*******************************/

/* PROGRAM TO STORE RESULTS FROM REGRESSIONS FOR STATA-TEX */
cap prog drop store_religion
prog def store_religion
  {
    
    /* syntax */
    syntax, name(string) outcome(string) label(string)
    local o = "`outcome'"
    local col = "`name'"
    local lab = "`label'"
    
    /* store N */
    local obs `e(N)'

    /* store control mean */
    sum `o' if def_nonmuslim == 0 & judge_nonmuslim == 0 & e(sample) == 1
    local cont: di %9.3f `r(mean)'
    local cont_est "`cont'"     

    /* store effect of nonmuslim judge on muslim defendant */
    local jfm: di %9.3f _b["judge_nonmuslim"]
    local se: di %9.3f _se["judge_nonmuslim"]
    local jfmse: di %9.3f _se["judge_nonmuslim"]
    test judge_nonmuslim = 0
    local p: di %5.2f (`r(p)')
    count_stars, p(`p')
    local jfm_est "`jfm'`r(stars)'"    
    if `p' > 0.01 local jfm_est "`jfm'"
    local jfm_ci: di %5.2f invttail(e(df_r),0.025)*_se["judge_nonmuslim"]
    
    /* store effect of nonmuslim judge on nonmuslim defendant */
    local jff: di %9.3f (_b["judge_nonmuslim"] + _b["judge_def_nonmuslim"])
    lincom judge_nonmuslim + judge_def_nonmuslim 
    local se: di %9.3f `r(se)'
    local jffse: di %9.3f `r(se)'
    test judge_nonmuslim + judge_def_nonmuslim = 0
    local p: di %5.2f (`r(p)')
    count_stars, p(`p')
    local jff_est "`jff'`r(stars)'"    
    if `p' > 0.1 local jff_est "`jff'"
    lincom judge_nonmuslim + judge_def_nonmuslim
    local jff_ci: di %5.2f invttail(e(df_r),0.025)*(_se["judge_nonmuslim"] + _se["judge_def_nonmuslim"])
    
    /* store marginal effect of nonmuslim judge on nonmuslim defendant */
    local int: di %9.3f (_b["judge_def_nonmuslim"])
    local se: di %9.3f _se["judge_def_nonmuslim"]
    local intse: di %9.3f _se["judge_def_nonmuslim"]
    test judge_def_nonmuslim = 0
    local p: di %5.2f (`r(p)')
    count_stars, p(`p')
    local int_est "`int'`r(stars)'"
    if `p' > 0.1 local int_est "`int'"
    local int_ci: di %5.2f invttail(e(df_r),0.025)*_se["judge_def_nonmuslim"]

    /* display results */
    di  %20s "`jfm_est'" %20s "`jff_est'" %25s "`int_est'" %15s "`col'"
    
    local demo "Non-muslim"
    local nondemo "Muslim"
    local identity "religion"
    
    /* store results into csv */
    insert_into_file using $tmp/religion_`o'.csv, key(o) value("`o'") 
    insert_into_file using $tmp/religion_`o'.csv, key(label) value("`lab'") 
    insert_into_file using $tmp/religion_`o'.csv, key(demo) value("`demo'") 
    insert_into_file using $tmp/religion_`o'.csv, key(nondemo) value("`nondemo'") 
    insert_into_file using $tmp/religion_`o'.csv, key(jfm_`col') value("`jfm_est'") 
    insert_into_file using $tmp/religion_`o'.csv, key(jff_`col') value("`jff_est'") 
    insert_into_file using $tmp/religion_`o'.csv, key(cmint_`col') value("`int_est'") 
    insert_into_file using $tmp/religion_`o'.csv, key(sefjm_`col') value("`jfmse'") 
    insert_into_file using $tmp/religion_`o'.csv, key(sefjf_`col') value("`jffse'") 
    insert_into_file using $tmp/religion_`o'.csv, key(seint_`col') value("`intse'") 
    insert_into_file using $tmp/religion_`o'.csv, key(cons_`col') value("`cont_est'") format(%25s) 
    insert_into_file using $tmp/religion_`o'.csv, key(N_`col') value("`obs'") format(%25s)
    insert_into_file using $tmp/religion_`o'.csv, key(id) value("`identity'") format(%25s)
  }
  
end

/**********************************END PROGRAM STORE_RELIGION*******************************/

/*************************************************/
/* Define program to classify names in case data */
/*************************************************/

cap prog drop classify_case_name
prog def classify_case_name

  {
    syntax, name(string)

    /* lower name variable */
    gen name_original = lower(`name')
    
    /* get clean name for each original name */    
    merge m:1 name_original using $jdata/classification/pooled_names_clean_appended, keepusing(name) keep(master match) nogen

    /* rename this name variable */
    ren name name_clean
    drop name_original

    /* get religion */
    merge m:1 name_clean using $jdata/classification/pooled_names_clean_all_muslims, keep(master match) nogen keepusing(muslim)

    /* get gender */
    merge m:1 name_clean using $jdata/classification/pooled_names_clean_all_female, keep(master match) nogen keepusing(female)

    /* process classified variables */
    replace muslim = . if name_clean == ""
    gen `name'_muslim = .
    replace `name'_muslim = 1 if muslim >= 0.65 & !mi(muslim)
    replace `name'_muslim = 0 if muslim < 0.35 & !mi(muslim)
    replace `name'_muslim = -9999 if mi(name_clean)
    replace `name'_muslim = -9998 if mi(`name'_muslim) 

    replace female = . if name_clean == ""
    gen `name'_female = .
    replace `name'_female = 1 if female >= 0.65 & !mi(female)
    replace `name'_female = 0 if female < 0.35 & !mi(female)
    replace `name'_female = -9999 if mi(name_clean)
    replace `name'_female = -9998 if mi(`name'_female) 

    /* drop name variable */
    drop name_clean muslim female

    /* format demographic vars */
    cap label drop female
    label define female 0 "0 male" 1 "1 female" -9998 "-9998 unclear" -9999 "-9999 missing name"

    /* format demographic vars */
    cap label drop muslim
    label define muslim 0 "0 nonmuslim" 1 "1 muslim" -9998 "-9998 unclear" -9999 "-9999 missing name"

    foreach var of var *name_female {
      label values `var' female
    }

    foreach var of var *name_muslim {
      label values `var' muslim
    }
    
  }

end

/***************************************END PROGRAM CLASSIFY_CASE_NAME********************************************************/  

/********************************************************************************/
/* Define program to extract clean position and location from judge designation */
/********************************************************************************/

cap prog drop desgformat
prog def desgformat

  /* I: Sub-string harmonization in judge_desg variable */
  
  /* open the replacements file */
  cap file close fh
  file open fh using $jcode/b/fixes.csv, read

  /* read the first line */
  file read fh line

  /* loop until end of file */
  while r(eof) == 0 {

    /* split the line into tokens:
    1: incorrect string 3: desired string */
    tokenize "`line'", parse(",")

    /* display step being taken */
    di `"replace judge_desg = subinstr(judge_desg, "`3'", "`1'", .)"'
    replace judge_desg = subinstr(judge_desg, "`3'", "`1'", .)

    /* read the next line in the replacements file */
    file read fh line
  }

  file close fh

  /* II: Create position from judge_desg */
  
  /* create position 1 */
  gen position1 = ""

  /* loop over reference list of designations */
  cap file close fh
  file open fh using $jcode/b/designations.csv, read

  /* read the first line */
  file read fh line

  /* loop until end of file */
  while r(eof) == 0 {

    /* split the line into tokens*/
    tokenize "`line'", parse(",")

    /* populate position */
    dis `"  replace position1 = "`1'" if regexm(judge_desg, "`1'") == 1 "'
    replace position1 = "`1'" if regexm(judge_desg, "`1'") == 1 & position1 == ""

    /* remove position from judge designation */
    di `"replace judge_desg = subinstr(judge_desg, "`1'", "", .)"'
    replace judge_desg = subinstr(judge_desg, "`1'", "", .)

    /* read the next line in the replacements file */
    file read fh line
  }

  file close fh

  /* format position variable */
  replace position1 = trim(position1)

  /* populate common pending positions */
  replace position1 = "district court" if word(judge_desg, 1) == "dj" & position1 == ""
  replace position1 = "district court" if word(judge_desg, 1) == "district" & word(judge_desg, 2) == "judge" & position1 == ""
  replace position1 = "mm court" if regexm(judge_desg, "mm court") == 1 & mi(position1)
  replace position1 = "chief judicial magistrate" if judge_desg == "chief judicial magistrat"
  replace position1 = "district court" if judge_desg == "barasat district judge"

  /* trick to prevent mismatch between d&s court and s court/d&s court and s court */
  replace position1 = "district and sessions court" if inlist(position1, "district court", "sessions court")
  replace position1 = "city district and sessions court" if inlist(position1, "city district court", "city sessions court")
  
  /* random phrase that appears at the beginning of some designations */
  replace judge_desg = subinstr(judge_desg, "um ", "", 4) if word(judge_desg, 1) == "um"

  /* check that additional appears at the beginning of remaining string */
  gen pos1 = 1 if word(judge_desg, 1) == "additional"
  gen pos2 = 1 if word(judge_desg, 2) == "additional" & word(judge_desg, 1) != "and" & word(judge_desg, 1) != "cum"

  /* add prefix additional to position */
  replace position1 = "additional" + " " + position1 if pos1 == 1 | pos2 == 1 & !mi(position1)

  /* remove phrase additional from judge desg */
  replace judge_desg = subinstr(judge_desg, "additional", "", .) if pos1 == 1 | pos2 == 1 & !mi(position1)

  /* drop temp vars */
  drop pos1 pos2
  
  /* check that principal appears at the beginning of remaining string */
  gen pos1 = 1 if word(judge_desg, 1) == "principal"

  /* add prefix additional to position */
  replace position1 = "principal" + " " + position1 if pos1 == 1 & !mi(position1)

  /* remove phrase additional from judge desg */
  replace judge_desg = subinstr(judge_desg, "principal", "", .) if pos1 == 1 & !mi(position1)

  /* fix position for obs where judge desg is ahmedabad district */
  replace position1 = "district court" if judge_desg_raw == "ahmedabad district"

  /* clean up position1 variable */
  replace position1 = "labour court" if position1 == "labour"
  replace position1 = "rent tribunal" if position1 == "rent"
  replace position1 = "additional court" if position1 == "additional "
  
  /* extract roman numeral if it appears as the first word */
  gen roman = word(judge_desg, 1)

  gen no = roman if inlist(roman, "i", "ii", "iii", "iv", "v", "vi")
  replace no = roman if inlist(roman, "vii", "viii", "ix", "x", "xi", "xii")
  replace no = roman if inlist(roman, "xiii", "xiv", "xv", "xvi")

  /* convert roman to arabic */
  local rlist "i ii iii iv v vi vii viii ix x xi xii xiii xiv xv xvi"

  forval i = 1/16{
    local num : word `i' of `rlist'
    replace no = "`i'" if no == "`num'"
  }
  
  forval i = 1/16{
    replace no = "`i'" if regexm(roman, "court-`i'") == 1
  }
  
  /* concatenate number to beginning of position */
  replace position1 = no + "-" + position1 if !mi(no) & !mi(position1)
  
  /* clean up positions after looking at case-judge position key match */
  replace position1 = "civil court" if position1 == "principal civil court"
  replace position1 = "family court" if position1 == "principal family court"
  replace position1 = "mahila court" if position1 == "mahila court"
  replace position1 = "pricipal sessions judge" if position1 == "principal principal sessions judge"

  /* replace original judge designation if clean position variable is missing */
  replace position1 = judge_desg_raw if mi(position1)

end

/***************************************END PROGRAM DESGFORMAT********************************************************/


/*******************************************************/
/* Define program to check for overlap in judge tenure */
/*******************************************************/

cap prog drop check_overlap
prog def check_overlap

  /* sort observations */
  sort state_code dist_code court_no position tenure_start tenure_end

  /* generate group */
  egen group = group(state_code dist_code court_no position)

  /* re-sort data */
  sort group tenure_start tenure_end
  
  /* generate tenure difference */
  gen diff = tenure_end[_n-1] - tenure_start[_n]

  /* flag obs with overlap beyond 0 days */
  gen flag = 1 if diff > 0 & !mi(diff) &  group[_n] == group[_n-1]
  //& location[_n] == location[_n-1]

  /* flag the preceding obs too so that we can check the differences in the obs */
  replace flag = 2 if flag[_n+1] == 1 & flag[_n] == .

end

/* ****************END PROGRAM CHECK_OVERLAP ************ */

/*************************************************/
/* Define program to create crime type variables */
/*************************************************/

cap prog drop gen_crime_types
prog def gen_crime_types

  /* classify sections into offenses */
  do $jcode/b/classify_offenses.do
  
  /* create crime type dummies for sub-sample analyses */
  /* crime categories */
  foreach crime in person_crime property_crime other_crime murder women_crime religion {
    gen `crime' = .
  }

  /* generate dummy for person crime */
  /* homicide, dowry death, suicide, abetment of suicide, infanticide */
  /* hurt, confinement, assault, kidnapping, traficking, slabery, sexual assault */
  forval i = 14/21 {
    replace person_crime = 1 if offenses == `i'
  }

  /* generate dummy for property crime */
  /* theft,robbery,extortion,property,breach of trust,cheating,fraudulence */
  /* mischief, trespassing */
  forval i = 22/30{
    replace property_crime = 1 if offenses == `i'
  }
  
  /* generate dummy for crimes against women */
  foreach i in 312 313 314 354 354 366 375 376 498 {
    replace women_crime = 1 if section == "`i'" & act == "The Indian Penal Code"
  }

  /* generate dummy for all other crimes */
  forval i = 1/13{
    replace other_crime = 1 if offenses == `i'
  }

  forval i = 31/33{
    replace other_crime = 1 if offenses == `i'
  }

  forval i = 36/38{
    replace other_crime = 1 if offenses == `i'
  }

  /* some specific crime dummies */
  replace murder = 1 if offenses == 14
  replace religion = 1 if offenses == 13

  /* fix missing values for dummy vars */
  foreach x in person_crime property_crime murder religion women_crime other_crime {
    replace `x' = 0 if mi(`x') & !mi(offenses)
  }
  
  /* label variables */
  label var person_crime    "Person Crime" 
  label var property_crime  "Property Crime" 
  label var women_crime     "Crimes agains women"
  label var other_crime     "Other Crime" 
  
end

/**********************END PROGRAM GEN_CRIME_TYPES************************/

/*****************************************/
/* Define program to create justice vars */
/*****************************************/

cap prog drop create_justice_vars
prog def create_justice_vars

  /* bring in purpose name strings */
  merge m:1 purpose_name year using $jdata/keys/purpose_name_key, keep(master match) nogen keepusing(*name_s)

  /* bring in disposition name strings */
  merge m:1 disp_name year using $jdata/keys/disp_name_key, keep(master match) nogen keepusing(*name_s)

  /* bring in type name string */
  merge m:1 type_name year using $jdata/keys/type_name_key, keep(master match) nogen keepusing(*name_s)
  
  /*********************/
  /* Tag Bail Outcomes */
  /*********************/

  /* using purpose names */
  gen bail = 1 if purpose_name_s == "bail" 

  /* using disposition names */
  replace bail = 1 if regexm(disp_name_s, "bail") == 1

  /* using type names */
  replace type_name_s = lower(type_name_s)
  replace bail = 1 if regexm(type_name_s, "bail") == 1
  replace bail = 1 if regexm(type_name_s, "b.app.") == 1
  replace bail = 1 if regexm(type_name_s, "blapl") == 1
  replace bail = 1 if regexm(type_name_s, "b a") == 1
  replace bail = 1 if regexm(type_name_s, "a.b.a") == 1

  /* Bail granted outcome */
  gen bail_grant = 0 if bail == 1
    
  foreach o in allowed accepted award {
    replace bail_grant = 1 if disp_name_s == "`o'" & bail == 1
  }
  
  replace bail_grant = 1 if disp_name_s == "bail granted"
  
  /****************************/
  /* Drop procedural outcomes */
  /****************************/

  drop if disp_name_s == "procedural"
  drop if disp_name_s == "committed"
  drop if disp_name_s == "accepted" & bail != 1

  /* also drop if case is uncontested */  
  drop if disp_name_s == "uncontested"
  drop if disp_name_s == "disposed-otherwise"

  /* drop a few other situations that lead to an uncontested trial */
  drop if disp_name_s == "absconded"
  drop if disp_name_s == "died"
  
  /*******************************************/
  /* Outcome vars: positive_1 and positive_0 */
  /*******************************************/

  gen positive_0 = 0 // if disp_name_s != "disposition var missing"
  gen positive_1 = 1 // if disp_name_s != "disposition var missing"

  /* negative outcomes */
  foreach o in convicted confession remanded prison contest-allowed {
    replace positive_1 = 0 if disp_name_s == "`o'"
    replace positive_0 = 0 if disp_name_s == "`o'"
  } 

  replace positive_1 = 0 if disp_name_s == "plead guilty"
  replace positive_0 = 0 if disp_name_s == "plead guilty"
  replace positive_1 = 0 if disp_name_s == "plea bargaining"
  replace positive_0 = 0 if disp_name_s == "plea bargaining"
  
  /* positive outcomes */
  foreach o in dismissed reject cancelled acquitted withdrawn compounded probation stayed award quash {
    replace positive_1 = 1 if disp_name_s == "`o'"
    replace positive_0 = 1 if disp_name_s == "`o'"
  }     
  
  replace positive_1 = 1 if disp_name_s == "not press"
  replace positive_1 = 1 if disp_name_s == "258 crpc"
  replace positive_1 = 1 if disp_name_s == "appeal accepted"
  replace positive_0 = 1 if disp_name_s == "not press"
  replace positive_0 = 1 if disp_name_s == "258 crpc"
  replace positive_0 = 1 if disp_name_s == "appeal accepted"  

  /* code missings as positive or negative outcomes */
  gen ambiguous = (positive_1 + positive_0) == 1 // if disp_name_s != "disposition var missing"
  
  /*****************************/
  /* Not convicted 1/0 outcome */
  /*****************************/

  gen non_convicted = 1 // if disp_name_s != "disposition var missing"

  /* tag convicted */
  foreach o in convicted prison {
    replace non_convicted = 0 if disp_name_s == "`o'"
  }

  replace non_convicted = 0 if disp_name_s == "plead guilty"
  replace non_convicted = 0 if disp_name_s == "plea bargaining"

  label var non_convicted "not convicted"

  /*************************/
  /* Acquitted 1/0 outcome */
  /*************************/

  gen acquitted = 0 // if disp_name_s != "disposition var missing"

  replace acquitted = 1 if disp_name_s == "acquitted"
  replace acquitted = 1 if disp_name_s == "258 crpc"
  replace acquitted = 1 if disp_name_s == "dismissed"
  
  /* drop the bulky string vars */
  drop *name_s

  /* finally, create an outcome for decision within 6 months */
  gen duration = decision_date - filing_date
  gen decision =  duration <= 180

  /* set decision to missing if the filing date is too close to the end of the
     analysis to know if the case was resolved quickly. */
  replace decision = . if filing_date > mdy(6, 1, 2018)
  la var decision "Whether the case was decided within 6 months"
  drop duration
  
  /* generate additional controls */
  cap bys ddl_judge_id filing_year: gen case_load = _N
  cap bys ddl_judge_id: egen mean_annual_case = mean(case_load)
  cap gen tenure_length = tenure_end - tenure_start

  /* label these */
  cap la var mean_annual_case "Mean annual case load"
  cap la var tenure_length "Tenure length"

end

/**************************END PROGRAM CREATE_JUSTICE_VARS*****************/


/***************************************************/
/* Define program to create demographic dummy vars */
/***************************************************/

cap prog drop create_demo_dummy
prog def create_demo_dummy

  /* format demographic vars for analysis */
  /* gender */
  rename def_name_female def_female 
  replace def_female = . if def_female < 0 
  gen def_male = !(def_female) if def_female != . 

  /* religion */
  rename def_name_muslim def_muslim 
  replace def_muslim = . if def_muslim < 0 
  gen def_nonmuslim = !(def_muslim) if def_muslim != . 

  /* petitioner demographics */
  /* gender */
  rename pet_name_female pet_female 
  replace pet_female = . if pet_female < 0 
  gen pet_male = !(pet_female) if pet_female != . 

  /* religion */
  rename pet_name_muslim pet_muslim 
  replace pet_muslim = . if pet_muslim < 0 
  gen pet_nonmuslim = !(pet_muslim) if pet_muslim != . 

  /* gender for judges */
  cap rename female_class judge_female 
  cap replace judge_female = . if judge_female < 0 
  cap gen judge_male = !(judge_female) if judge_female != . 

  /* religion for judges */
  cap rename muslim_class judge_muslim 
  cap replace judge_muslim = . if judge_muslim < 0 
  cap gen judge_nonmuslim = !(judge_muslim) if judge_muslim != .

end

/***********************End program create_demo_dummy**********************/




/*****************************************************/
/* Define program to combine regression table panels */
/*****************************************************/

cap prog drop panelcombine
prog define panelcombine
  qui {
    syntax, use(str asis) paneltitles(str asis) columncount(integer) save(str asis) [CLEANup]
    preserve

    tokenize `"`paneltitles'"'
    //read in loop
    local num 1
    while "``num''"~="" {
      local panel`num'title="``num''"
      local num=`num'+1
    }


    tokenize `use'
    //read in loop
    local num 1
    while "``num''"~="" {
      tempfile temp`num'
      insheet using "``num''", clear
      save `temp`num''
      local max = `num'
      local num=`num'+1
    }

    local count = `columncount' + 1
    
    //conditional processing loop
    local num 1
    while "``num''"~="" {
      local panellabel : word `num' of `c(ALPHA)'
      use `temp`num'', clear
      if `num'==1 { //process first panel -- clip bottom
        drop if strpos(v1,"Note:")>0 | strpos(v1,"in parentheses")>0 | strpos(v1,"p<0")>0
        drop if v1=="\end{tabular}" | v1=="}"
        replace v1 = "\hline \multicolumn{`count'}{c}{ \linebreak \textit{Panel `panellabel': `panel1title'}} \\ \hline" if v1=="\hline" & _n<8
        replace v1 = "\hline" if v1=="\hline\hline" & _n>4 //this is intended to replace the bottom double line; more robust condition probably exists
      }
      else if `num'==`max' { //process final panel -- clip top
        //process header to drop everything until first hline
        g temp = (v1 == "\hline")
        replace temp = temp+temp[_n-1] if _n>1
        drop if temp==0
        drop temp
        
        replace v1 = " \multicolumn{`count'}{c}{\linebreak \textit{Panel `panellabel': `panel`num'title'}} \\ \hline" if _n==1
      }
      else { //process middle panels -- clip top and bottom
        //process header to drop everything until first hline
        g temp = (v1 == "\hline")
        replace temp = temp+temp[_n-1] if _n>1
        drop if temp==0
        drop temp
        
        replace v1 = " \multicolumn{`count'}{c}{\linebreak \textit{Panel `panellabel': `panel`num'title'}} \\ \hline" if _n==1
        drop if strpos(v1,"Note:")>0 | strpos(v1,"in parentheses")>0 | strpos(v1,"p<0")>0
        drop if v1=="\end{tabular}" | v1=="}"
        replace v1 = "\hline" if v1=="\hline\hline"
      }
      save `temp`num'', replace
      local num=`num'+1
    }

    use `temp1',clear
    local num 2
    while "``num''"~="" {
      append using `temp`num''
      local num=`num'+1
    }

    outsheet using `save', noname replace noquote


    if "`cleanup'"!="" { //erasure loop
      tokenize `use'
      local num 1
      while "``num''"~="" {
        erase "``num''"
        local num=`num'+1
      }
    }

    restore
  }
end

/***************************************END PROGRAM PANEL_COMBINE********************************************************/

/**********************************************************/
/* program get_string: get a string from a string table   */
/**********************************************************/
cap prog drop get_string
prog def get_string
  syntax varname
  tokenize `varlist'
  
  merge m:1 `1' year using $jdata/keys/`1'_key, keep(master match) nogen keepusing(*name_s)

end
/** END program get_string ********************************/

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
  local cont: di %9.4f `r(mean)'
  local cont_est "`cont'"     

  /* store effect of male judge on female defendant */
  local jfm: di %9.4f _b["judge_male"]
  local se: di %9.4f _se["judge_male"]
  local jfmse: di %9.4f _se["judge_male"]
  test judge_male = 0
  local p: di %9.4f (`r(p)')
  count_stars, p(`p')
  local jfm_est "`jfm'`r(stars)'"
  if `p' > 0.1 local jfm_est "`jfm'"
  local jfm_ci: di %9.4f invttail(e(df_r),0.025)*_se["judge_male"]
  
  /* store effect of male judge on male defendant */
  local jff: di %9.4f (_b["judge_male"] + _b["judge_def_male"])
  lincom judge_male + judge_def_male 
  local se: di %9.4f `r(se)'
  local jffse: di %9.4f `r(se)'
  test judge_male + judge_def_male = 0
  local p: di %9.4f (`r(p)')
  count_stars, p(`p')
  local jff_est "`jff'`r(stars)'"
  if `p' > 0.1 local jff_est "`jff'"
  lincom judge_male + judge_def_male
  local jff_ci: di %9.4f invttail(e(df_r),0.025)*(_se["judge_male"] + _se["judge_def_male"])
  
  /* store marginal effect of male judge on male defendant */
  local int: di %9.4f (_b["judge_def_male"])
  local se: di %9.4f _se["judge_def_male"]
  local intse: di %9.4f _se["judge_def_male"]
  test judge_def_male = 0
  local p: di %9.4f (`r(p)')
  count_stars, p(`p')
  local int_est "`int'`r(stars)'"
  if `p' > 0.1 local int_est "`int'"
  local int_ci: di %9.4f invttail(e(df_r),0.025)*_se["judge_def_male"]

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
  insert_into_file using $tmp/gender_`o'.csv, key(jfm_`col') value("`jfm_est'") format(%9.4f)
  insert_into_file using $tmp/gender_`o'.csv, key(jff_`col') value("`jff_est'") format(%9.4f)
  insert_into_file using $tmp/gender_`o'.csv, key(cmint_`col') value("`int_est'") format(%9.4f)
  insert_into_file using $tmp/gender_`o'.csv, key(sefjm_`col') value("`jfmse'") format(%9.4f)
  insert_into_file using $tmp/gender_`o'.csv, key(sefjf_`col') value("`jffse'") format(%9.4f)
  insert_into_file using $tmp/gender_`o'.csv, key(seint_`col') value("`intse'") format(%9.4f)
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
    local cont: di %9.4f `r(mean)'
    local cont_est "`cont'"     

    /* store effect of nonmuslim judge on muslim defendant */
    local jfm: di %9.4f _b["judge_nonmuslim"]
    local se: di %9.4f _se["judge_nonmuslim"]
    local jfmse: di %9.4f _se["judge_nonmuslim"]
    test judge_nonmuslim = 0
    local p: di %9.4f (`r(p)')
    count_stars, p(`p')
    local jfm_est "`jfm'`r(stars)'"    
    if `p' > 0.1 local jfm_est "`jfm'"
    local jfm_ci: di %9.4f invttail(e(df_r),0.025)*_se["judge_nonmuslim"]
    
    /* store effect of nonmuslim judge on nonmuslim defendant */
    local jff: di %9.4f (_b["judge_nonmuslim"] + _b["judge_def_nonmuslim"])
    lincom judge_nonmuslim + judge_def_nonmuslim 
    local se: di %9.4f `r(se)'
    local jffse: di %9.4f `r(se)'
    test judge_nonmuslim + judge_def_nonmuslim = 0
    local p: di %9.4f (`r(p)')
    count_stars, p(`p')
    local jff_est "`jff'`r(stars)'"    
    if `p' > 0.1 local jff_est "`jff'"
    lincom judge_nonmuslim + judge_def_nonmuslim
    local jff_ci: di %9.4f invttail(e(df_r),0.025)*(_se["judge_nonmuslim"] + _se["judge_def_nonmuslim"])
    
    /* store marginal effect of nonmuslim judge on nonmuslim defendant */
    local int: di %9.4f (_b["judge_def_nonmuslim"])
    local se: di %9.4f _se["judge_def_nonmuslim"]
    local intse: di %9.4f _se["judge_def_nonmuslim"]
    test judge_def_nonmuslim = 0
    local p: di %9.4f (`r(p)')
    count_stars, p(`p')
    local int_est "`int'`r(stars)'"
    if `p' > 0.1 local int_est "`int'"
    local int_ci: di %9.4f invttail(e(df_r),0.025)*_se["judge_def_nonmuslim"]

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
    insert_into_file using $tmp/religion_`o'.csv, key(jfm_`col') value("`jfm_est'") format(%9.4f) 
    insert_into_file using $tmp/religion_`o'.csv, key(jff_`col') value("`jff_est'") format(%9.4f)
    insert_into_file using $tmp/religion_`o'.csv, key(cmint_`col') value("`int_est'") format(%9.4f)
    insert_into_file using $tmp/religion_`o'.csv, key(sefjm_`col') value("`jfmse'") format(%9.4f)
    insert_into_file using $tmp/religion_`o'.csv, key(sefjf_`col') value("`jffse'") format(%9.4f)
    insert_into_file using $tmp/religion_`o'.csv, key(seint_`col') value("`intse'") format(%9.4f)
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

  /*****************************/
  /* Part I: Classify Offenses */
  /*****************************/

  /* classification is based on this document: */
  /* https://districts.ecourts.gov.in/sites/default/files/Act%20%26%20Sections_0_5_0.pdf */
  gen offenses = .
  
  /* abetment */
  forval i = 109/117 {
    replace offenses = 1 if strpos(section, "`i'")
  }

  /* criminal conspiracy */
  replace offenses = 2 if strpos(section, "120")

  /* against the state */
  forval i = 121/128{
    replace offenses = 3 if strpos(section, "`i'")
  }

  replace offenses = 3 if strpos(section, "130") 

  /* army, navy or force */
  forval i = 131/140{
    replace offenses = 4 if strpos(section, "`i'")
  }

  /* public tranquility */
  forval i = 141/160{
    replace offenses = 5 if strpos(section, "`i'")
  }

  /* public servants/election fraudulence */
  forval i = 161/171{
    replace offenses = 6 if strpos(section, "`i'")
  }

  /* contempt/messing with a public servant */
  forval i = 172/190{
    replace offenses = 7 if strpos(section, "`i'")
  }

  /* falsifying evidence/disrupting judicial process */
  forval i = 191/229{
    replace offenses = 8 if strpos(section, "`i'")
  }

  /* coins and stamps */
  forval i = 230/263{
    replace offenses = 9 if strpos(section, "`i'")
  }

  /* weights and measures */
  forval i = 264/267{
    replace offenses = 10 if strpos(section, "`i'")
  }

  /* public health safety */
  forval i = 268/289{
    replace offenses = 11 if strpos(section, "`i'")
  }

  /* obscenity, nuisance, and lotteries */
  forval i = 290/294{
    replace offenses = 12 if strpos(section, "`i'")
  }

  /* religious offense */
  forval i = 295/298{
    replace offenses = 13 if strpos(section, "`i'")
  }

  /* suicide, homicide, dowry death, abetment of suicide */
  forval i = 299/311{
    replace offenses = 14 if strpos(section, "`i'")
  }

  /* forced miscarriage and infanticide */
  forval i = 312/318{
    replace offenses = 15 if strpos(section, "`i'")
  }

  /* hurt */
  forval i = 319/338{
    replace offenses = 16 if strpos(section, "`i'")
  }

  /* confinement */
  forval i = 339/348{
    replace offenses = 17 if strpos(section, "`i'")
  }

  /* assault */
  forval i = 349/358{
    replace offenses = 18 if strpos(section, "`i'")
  }

  /* kidnapping */
  forval i = 359/366{
    replace offenses = 19 if strpos(section, "`i'")
  }

  forval i = 368/369{
    replace offenses = 19 if strpos(section, "`i'")
  }

  /* trafficking and slavery */
  replace offenses = 20 if strpos(section, "366") & strpos(section, "B") 
  replace offenses = 20 if strpos(section, "366") & strpos(section, "A") 

  forval i = 370/374{
    replace offenses = 20 if strpos(section, "`i'")
  }

  /* sexual assault */
  forval i = 375/377{
    replace offenses = 21 if strpos(section, "`i'")
  }

  replace offenses = 21 if strpos(section, "354")

  /* theft */
  forval i = 378/382{
    replace offenses = 22 if strpos(section, "`i'")
  }

  /* robbery/dacoity */
  forval i = 390/402{
    replace offenses = 23 if strpos(section, "`i'")
  }

  /* extortion */
  forval i = 383/389{
    replace offenses = 24 if strpos(section, "`i'")
  }

  /* property */
  forval i = 403/404{
    replace offenses = 25 if strpos(section, "`i'")
  }

  forval i = 410/414{
    replace offenses = 25 if strpos(section, "`i'")
  }

  /* criminal breach of trust */
  forval i = 405/409{
    replace offenses = 26 if strpos(section, "`i'")
  }

  /* cheating */
  forval i = 415/420{
    replace offenses = 27 if strpos(section, "`i'")
  }

  /* fraudulent deeds */
  forval i = 421/424{
    replace offenses = 28 if strpos(section, "`i'")
  }

  /* mischief */
  forval i = 425/440{
    replace offenses = 29 if strpos(section, "`i'")
  }

  /* trespass */
  forval i = 441/462{
    replace offenses = 30 if strpos(section, "`i'")
  }

  /* forgery of documents and accounts */
  forval i = 463/477{
    replace offenses = 31 if strpos(section, "`i'")
  }

  /* counterfeiting property or other marks */
  forval i = 478/489{
    replace offenses = 32 if strpos(section, "`i'")
  }

  /* breach of contracts of service */
  forval i = 490/492{
    replace offenses = 33 if strpos(section, "`i'")
  }

  /* marriage offences/adultery */
  forval i = 493/498{
    replace offenses = 34 if strpos(section, "`i'")
  }

  /* cruetly by husband relatives */
  replace offenses = 35 if strpos(section, "498") & strpos(section, "A")
  
  /* defamation */
  forval i = 499/502{
    replace offenses = 36 if strpos(section, "`i'")
  }

  /* intimidation */
  forval i = 503/510{
    replace offenses = 37 if strpos(section, "`i'")
  }

  /* commit offence  */
  replace offenses = 38 if strpos(section, "511")

  /* code of criminal procedure */
  replace offenses = 999 if act == "Code of Criminal Procedure"

  /*****************************************/
  /* END of mapping sections --> offenses  */
  /*****************************************/

  /*****************************************************/
  /* PART II: Create non-overlapping crime categories  */
  /*****************************************************/

  /* NOTE: Part I creates 38 + 1 offense categories (numbered 1-38 and 999 (code of criminal procedure) */
  /* we then use 9 of those categories for Fig.1 and Tables A4/A5 and bundle everything else in a 10th "all other" category  */
  /* Therefore, all the new crime indicator variables created below should encompass the 38 offense categories created in Part I  */
  global crime_categories sexual_assault violent_crime theft_dacoity peace marriage_offenses ///
      petty_theft person_crime property_crime murder women_crime religion

  /* create crime type dummies for sub-sample analyses */
  /* crime categories */
  foreach crime in  $crime_categories {
    gen `crime' = .
  }

  /* sexual assault */
  replace sexual_assault = 1 if offenses == 21

  /* violent crimes */
  replace violent_crime = 1 if inlist(offenses, 16, 18)

  /* violent theft_dacoity */
  replace theft_dacoity = 1 if inlist(offenses, 23, 24)

  /* disturbing public health/safety */
  replace peace = 1 if inlist(offenses, 5, 11, 12)

  /* marriage offenses */
  replace marriage_offenses = 1 if offenses == 34

  /* petty theft */
  replace petty_theft = 1 if offenses == 22

  /* murder, homicide, abetment of suicide, etc. */
  replace murder = 1 if offenses == 14

  /* religion-related crimes */
  replace religion = 1 if offenses == 13

  /* homicide, dowry death, suicide, abetment of suicide, infanticide */
  /* hurt, confinement, assault, kidnapping, traficking, slabery, sexual assault */
  forval i = 14/21 {
    replace person_crime = 1 if offenses == `i'
  }

  /* generate dummy for property crime */
  /* theft,robbery,extortion,property,breach of trust,cheating,fraudulence */
  /* mischief, trespassing */
  replace property_crime = 1 if inlist(offenses, 25, 28, 29, 30, 32)
  
  /* generate dummy for crimes against women */
  /* EI: removed 354, 375, 376 since those are mapped to offense == 21 which is the sexual assault category */
  /* EI: removed 498 since that's mapped to marriage offenses  */
  foreach i in 312 313 314 315 366  {
    replace women_crime = 1 if section == "`i'" & act == "The Indian Penal Code"
  }

  /* gen other crime separately so the loop below doesn't include it */
  gen other_crime = .
  
  /* fix missing values for dummy vars */
  foreach x in $crime_categories  {
    replace `x' = 0 if mi(`x') & !mi(offenses)

    replace other_crime = 0 if `x' == 1 
  }

  /*  indicator for all other crimes */
  replace other_crime = 1 if other_crime == . & !missing(offenses)

  /* create a dummy variable for all */
  gen all = 1

  /* label variables */
  label var person_crime        "Person Crime" 
  label var property_crime      "Property Crime" 
  label var women_crime         "Other crimes against women"
  label var murder              "Murder"
  label var sexual_assault      "Sexual Assault"
  label var violent_crime       "Violent crimes causing hurt"
  label var theft_dacoity       "Violent theft/dacoity"
  label var peace               "Disturbing public health/safety"
  label var marriage_offenses   "Marriage offenses"
  label var petty_theft         "Petty theft"
  label var other_crime         "Other Crime" 
  cap la var all                "Total"

  /* create categorical var containing all crimes  */
  gen crime_category = 1 if sexual_assault == 1
  replace crime_category = 2 if violent_crime == 1
  replace crime_category = 3 if theft_dacoity == 1
  replace crime_category = 4 if peace == 1
  replace crime_category = 5 if marriage_offenses == 1
  replace crime_category = 6 if petty_theft == 1
  replace crime_category = 7 if person_crime == 1
  replace crime_category = 8 if property_crime == 1
  replace crime_category = 9 if murder == 1
  replace crime_category = 10 if women_crime == 1
  replace crime_category = 11 if other_crime == 1
  replace crime_category = 12 if section == ""

  /* create value labels for each crime category */
  lab define crime_labels 1 "sexual assault" 2 "violent crime" 3 "theft/dacoity" 4 "disturbing public safety" ///
      5 "marriage offenses" 6 "petty theft" 7 "person crime" 8 "property crime" 9 "murder"  ///
      10 "other crimes against women" 11 "other crime" 12 "missing section"

  /* assign value label to numerical crime categories */
  lab val crime_category crime_labels
  
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
  replace bail = 1 if strpos(disp_name_s, "bail")

  /* using type names */
  replace type_name_s = lower(type_name_s)
  replace bail = 1 if strpos(type_name_s, "bail")
  replace bail = 1 if strpos(type_name_s, "b.app.")
  replace bail = 1 if strpos(type_name_s, "blapl")
  replace bail = 1 if strpos(type_name_s, "b a")
  replace bail = 1 if strpos(type_name_s, "a.b.a")

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

/**********************************************************/
/* program fix_names: force names into common spellings   */
/**********************************************************/
cap prog drop fix_names
prog def fix_names
  syntax varlist
  tokenize `varlist'

  replace `1' = "adhikari" if `1' == "adhikary"
  replace `1' = "agarwal" if `1' == "agrawal"
  replace `1' = "agarwal" if `1' == "aggarwal"
  replace `1' = "ahamad" if `1' == "ahamed"
  replace `1' = "ahamad" if `1' == "ahmad"
  replace `1' = "ahamad" if `1' == "ahmed"
  replace `1' = "begam" if `1' == "begum"
  replace `1' = "behera" if `1' == "bera"
  replace `1' = "bhat" if `1' == "bhatt"
  replace `1' = "bhosale" if `1' == "bhosle"
  replace `1' = "bhowmick" if `1' == "bhowmik"
  replace `1' = "bora" if `1' == "borah"
  replace `1' = "chand" if `1' == "chanda"
  replace `1' = "chaudhari" if `1' == "chaudhary"
  replace `1' = "chetri" if `1' == "chettri"
  replace `1' = "choudhary" if `1' == "choudhry"
  replace `1' = "choudhary" if `1' == "choudhury"
  replace `1' = "choudhary" if `1' == "chowdhury"
  replace `1' = "dahariya" if `1' == "dahiya"
  replace `1' = "dahariya" if `1' == "dahriya"
  replace `1' = "dube" if `1' == "dubey"
  replace `1' = "gouda" if `1' == "gowda"
  replace `1' = "haldar" if `1' == "halder"
  replace `1' = "husain" if `1' == "hussain"
  replace `1' = "jadav" if `1' == "jadhav"
  replace `1' = "kala" if `1' == "kale"
  replace `1' = "karthick" if `1' == "karthik"
  replace `1' = "krishna" if `1' == "krishnaiah"
  replace `1' = "krishna" if `1' == "krishnan"
  replace `1' = "kushwah" if `1' == "kushwaha"
  replace `1' = "mahesh" if `1' == "mahesha"
  replace `1' = "malik" if `1' == "mallick"
  replace `1' = "manjunath" if `1' == "manjunatha"
  replace `1' = "narain" if `1' == "narayan"
  replace `1' = "nigam" if `1' == "nikam"
  replace `1' = "panda" if `1' == "pande"
  replace `1' = "panda" if `1' == "pandey"
  replace `1' = "panda" if `1' == "pandy"
  replace `1' = "panda" if `1' == "pandya"
  replace `1' = "pandit" if `1' == "pandita"
  replace `1' = "panigrahi" if `1' == "panigrahy"
  replace `1' = "patel" if `1' == "patil"
  replace `1' = "pattanaik" if `1' == "pattnaik"
  replace `1' = "pavar" if `1' == "pawar"
  replace `1' = "rajasekar" if `1' == "rajasekhar"
  replace `1' = "sahoo" if `1' == "sahu"
  replace `1' = "sarma" if `1' == "sarmah"
  replace `1' = "satapathy" if `1' == "satpathy"
  replace `1' = "sethi" if `1' == "sethy"
  replace `1' = "shaik" if `1' == "shaikh"
  replace `1' = "shaik" if `1' == "sheik"
  replace `1' = "shukl" if `1' == "shukla"
  replace `1' = "suryavanshi" if `1' == "suryawanshi"
  replace `1' = "tiwari" if `1' == "tiwary"
  replace `1' = "tripathi" if `1' == "tripathy"
  
end
/** END program fix_names *********************************/

/********************************************************************************/
/* program set_festival_dates: creates variables for religious festival dates   */
/********************************************************************************/
cap prog drop set_festival_dates
prog def set_festival_dates
  /* rama navami */

  /* day of */
  gen rama_navami = 0
  replace rama_navami= 1 if year(decision_date) == 2010 & ((month(decision_date) == 03 & day(decision_date) == 24))
  replace rama_navami= 1 if year(decision_date) == 2011 & ((month(decision_date) == 04 & day(decision_date) == 12))
  replace rama_navami= 1 if year(decision_date) == 2012 & ((month(decision_date) == 04 & day(decision_date) == 01))
  replace rama_navami= 1 if year(decision_date) == 2013 & ((month(decision_date) == 04 & day(decision_date) == 19))
  replace rama_navami= 1 if year(decision_date) == 2014 & ((month(decision_date) == 04 & day(decision_date) == 08))
  replace rama_navami= 1 if year(decision_date) == 2015 & ((month(decision_date) == 03 & day(decision_date) == 28))
  replace rama_navami= 1 if year(decision_date) == 2016 & ((month(decision_date) == 04 & day(decision_date) == 15))
  replace rama_navami= 1 if year(decision_date) == 2017 & ((month(decision_date) == 04 & day(decision_date) == 04))
  replace rama_navami= 1 if year(decision_date) == 2018 & ((month(decision_date) == 03 & day(decision_date) == 25))
  
  
  /* week after */
  gen rama_navami_wa = 0
  replace rama_navami_wa= 1 if year(decision_date) == 2010 & ((month(decision_date) == 03 & day(decision_date) >= 24) | (month(decision_date) == 03 & day(decision_date) <= 31))
  replace rama_navami_wa= 1 if year(decision_date) == 2011 & ((month(decision_date) == 04 & day(decision_date) >= 12) | (month(decision_date) == 04 & day(decision_date) <= 19))
  replace rama_navami_wa= 1 if year(decision_date) == 2012 & ((month(decision_date) == 04 & day(decision_date) >= 01) | (month(decision_date) == 04 & day(decision_date) <= 08))
  replace rama_navami_wa= 1 if year(decision_date) == 2013 & ((month(decision_date) == 04 & day(decision_date) >= 19) | (month(decision_date) == 04 & day(decision_date) <= 26))
  replace rama_navami_wa= 1 if year(decision_date) == 2014 & ((month(decision_date) == 04 & day(decision_date) >= 08) | (month(decision_date) == 04 & day(decision_date) <= 15))
  replace rama_navami_wa= 1 if year(decision_date) == 2015 & ((month(decision_date) == 03 & day(decision_date) >= 28) | (month(decision_date) == 04 & day(decision_date) <= 04))
  replace rama_navami_wa= 1 if year(decision_date) == 2016 & ((month(decision_date) == 04 & day(decision_date) >= 15) | (month(decision_date) == 04 & day(decision_date) <= 22))
  replace rama_navami_wa= 1 if year(decision_date) == 2017 & ((month(decision_date) == 04 & day(decision_date) >= 04) | (month(decision_date) == 04 & day(decision_date) <= 11))
  replace rama_navami_wa= 1 if year(decision_date) == 2018 & ((month(decision_date) == 03 & day(decision_date) >= 25) | (month(decision_date) == 04 & day(decision_date) <= 01))
  
  /* month after */
  gen rama_navami_ma = 0
  replace rama_navami_ma= 1 if year(decision_date) == 2010 & ((month(decision_date) == 03 & day(decision_date) >= 24) | (month(decision_date) == 04 & day(decision_date) <= 24))
  replace rama_navami_ma= 1 if year(decision_date) == 2011 & ((month(decision_date) == 04 & day(decision_date) >= 12) | (month(decision_date) == 05 & day(decision_date) <= 12))
  replace rama_navami_ma= 1 if year(decision_date) == 2012 & ((month(decision_date) == 04 & day(decision_date) >= 01) | (month(decision_date) == 05 & day(decision_date) <= 01))
  replace rama_navami_ma= 1 if year(decision_date) == 2013 & ((month(decision_date) == 04 & day(decision_date) >= 19) | (month(decision_date) == 05 & day(decision_date) <= 19))
  replace rama_navami_ma= 1 if year(decision_date) == 2014 & ((month(decision_date) == 04 & day(decision_date) >= 08) | (month(decision_date) == 05 & day(decision_date) <= 08))
  replace rama_navami_ma= 1 if year(decision_date) == 2015 & ((month(decision_date) == 03 & day(decision_date) >= 28) | (month(decision_date) == 04 & day(decision_date) <= 28))
  replace rama_navami_ma= 1 if year(decision_date) == 2016 & ((month(decision_date) == 04 & day(decision_date) >= 15) | (month(decision_date) == 05 & day(decision_date) <= 15))
  replace rama_navami_ma= 1 if year(decision_date) == 2017 & ((month(decision_date) == 04 & day(decision_date) >= 04) | (month(decision_date) == 05 & day(decision_date) <= 04))
  replace rama_navami_ma= 1 if year(decision_date) == 2018 & ((month(decision_date) == 03 & day(decision_date) >= 25) | (month(decision_date) == 04 & day(decision_date) <= 25))
  
  /* holi */
  
  /* day of */
  gen holi = 0
  replace holi= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 03 & day(decision_date) == 01))
  replace holi= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 03 & day(decision_date) == 20))
  replace holi= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 03 & day(decision_date) == 08))
  replace holi= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 03 & day(decision_date) == 27))
  replace holi= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 03 & day(decision_date) == 17))
  replace holi= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 03 & day(decision_date) == 06))
  replace holi= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 03 & day(decision_date) == 24))
  replace holi= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 03 & day(decision_date) == 13))
  replace holi= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 03 & day(decision_date) == 02))
  
  /* week after */
  gen holi_wa = 0
  replace holi_wa= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 03 & day(decision_date) >= 01) | (month(decision_date) == 03 & day(decision_date) <= 08))
  replace holi_wa= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 03 & day(decision_date) >= 20) | (month(decision_date) == 03 & day(decision_date) <= 27))
  replace holi_wa= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 03 & day(decision_date) >= 08) | (month(decision_date) == 03 & day(decision_date) <= 15))
  replace holi_wa= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 03 & day(decision_date) >= 27) | (month(decision_date) == 04 & day(decision_date) <= 03))
  replace holi_wa= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 03 & day(decision_date) >= 17) | (month(decision_date) == 03 & day(decision_date) <= 24))
  replace holi_wa= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 03 & day(decision_date) >= 06) | (month(decision_date) == 03 & day(decision_date) <= 13))
  replace holi_wa= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 03 & day(decision_date) >= 24) | (month(decision_date) == 03 & day(decision_date) <= 31))
  replace holi_wa= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 03 & day(decision_date) >= 13) | (month(decision_date) == 03 & day(decision_date) <= 20))
  replace holi_wa= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 03 & day(decision_date) >= 02) | (month(decision_date) == 03 & day(decision_date) <= 09))
  
  /* month after */
  gen holi_ma = 0
  replace holi_ma= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 03 & day(decision_date) >= 01) | (month(decision_date) == 04 & day(decision_date) <= 01))
  replace holi_ma= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 03 & day(decision_date) >= 20) | (month(decision_date) == 04 & day(decision_date) <= 20))
  replace holi_ma= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 03 & day(decision_date) >= 08) | (month(decision_date) == 04 & day(decision_date) <= 08))
  replace holi_ma= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 03 & day(decision_date) >= 27) | (month(decision_date) == 04 & day(decision_date) <= 27))
  replace holi_ma= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 03 & day(decision_date) >= 17) | (month(decision_date) == 04 & day(decision_date) <= 17))
  replace holi_ma= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 03 & day(decision_date) >= 06) | (month(decision_date) == 04 & day(decision_date) <= 06))
  replace holi_ma= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 03 & day(decision_date) >= 24) | (month(decision_date) == 04 & day(decision_date) <= 24))
  replace holi_ma= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 03 & day(decision_date) >= 13) | (month(decision_date) == 04 & day(decision_date) <= 13))
  replace holi_ma= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 03 & day(decision_date) >= 02) | (month(decision_date) == 04 & day(decision_date) <= 02))
  
  /* diwali */
  
  /* day of */
  gen diwali = 0
  replace diwali= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 11 & day(decision_date) == 05))
  replace diwali= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 10 & day(decision_date) == 26))
  replace diwali= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 11 & day(decision_date) == 13))
  replace diwali= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 11 & day(decision_date) == 03))
  replace diwali= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 10 & day(decision_date) == 23))
  replace diwali= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 11 & day(decision_date) == 11))
  replace diwali= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 10 & day(decision_date) == 30))
  replace diwali= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 10 & day(decision_date) == 19))
  replace diwali= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 11 & day(decision_date) == 07))
  
  /* week after */
  gen diwali_wa = 0
  replace diwali_wa= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 11 & day(decision_date) >= 05) | (month(decision_date) == 11 & day(decision_date) <= 12))
  replace diwali_wa= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 10 & day(decision_date) >= 26) | (month(decision_date) == 11 & day(decision_date) <= 02))
  replace diwali_wa= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 11 & day(decision_date) >= 13) | (month(decision_date) == 11 & day(decision_date) <= 20))
  replace diwali_wa= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 11 & day(decision_date) >= 03) | (month(decision_date) == 11 & day(decision_date) <= 10))
  replace diwali_wa= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 10 & day(decision_date) >= 23) | (month(decision_date) == 10 & day(decision_date) <= 30))
  replace diwali_wa= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 11 & day(decision_date) >= 11) | (month(decision_date) == 11 & day(decision_date) <= 18))
  replace diwali_wa= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 10 & day(decision_date) >= 30) | (month(decision_date) == 11 & day(decision_date) <= 06))
  replace diwali_wa= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 10 & day(decision_date) >= 19) | (month(decision_date) == 10 & day(decision_date) <= 26))
  replace diwali_wa= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 11 & day(decision_date) >= 07) | (month(decision_date) == 11 & day(decision_date) <= 14))
  
  /* month after */
  gen diwali_ma = 0
  replace diwali_ma= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 11 & day(decision_date) >= 05) | (month(decision_date) == 12 & day(decision_date) <= 05))
  replace diwali_ma= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 10 & day(decision_date) >= 26) | (month(decision_date) == 11 & day(decision_date) <= 26))
  replace diwali_ma= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 11 & day(decision_date) >= 13) | (month(decision_date) == 12 & day(decision_date) <= 13))
  replace diwali_ma= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 11 & day(decision_date) >= 03) | (month(decision_date) == 12 & day(decision_date) <= 03))
  replace diwali_ma= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 10 & day(decision_date) >= 23) | (month(decision_date) == 11 & day(decision_date) <= 23))
  replace diwali_ma= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 11 & day(decision_date) >= 11) | (month(decision_date) == 12 & day(decision_date) <= 11))
  replace diwali_ma= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 10 & day(decision_date) >= 30) | (month(decision_date) == 11 & day(decision_date) <= 30))
  replace diwali_ma= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 10 & day(decision_date) >= 19) | (month(decision_date) == 11 & day(decision_date) <= 19))
  replace diwali_ma= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 11 & day(decision_date) >= 07) | (month(decision_date) == 12 & day(decision_date) <= 07))
  
  /* dasara */
  
  /* day of */
  gen dasara = 0
  replace dasara= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 10 & day(decision_date) == 17))
  replace dasara= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 10 & day(decision_date) == 06))
  replace dasara= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 10 & day(decision_date) == 24))
  replace dasara= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 10 & day(decision_date) == 13))
  replace dasara= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 10 & day(decision_date) == 03))
  replace dasara= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 10 & day(decision_date) == 22))
  replace dasara= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 10 & day(decision_date) == 11))
  replace dasara= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 09 & day(decision_date) == 30))
  replace dasara= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 10 & day(decision_date) == 19))
  
  /* week after */
  gen dasara_wa = 0
  replace dasara_wa= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 10 & day(decision_date) >= 17) | (month(decision_date) == 10 & day(decision_date) <= 24))
  replace dasara_wa= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 10 & day(decision_date) >= 06) | (month(decision_date) == 10 & day(decision_date) <= 13))
  replace dasara_wa= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 10 & day(decision_date) >= 24) | (month(decision_date) == 10 & day(decision_date) <= 31))
  replace dasara_wa= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 10 & day(decision_date) >= 13) | (month(decision_date) == 10 & day(decision_date) <= 20))
  replace dasara_wa= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 10 & day(decision_date) >= 03) | (month(decision_date) == 10 & day(decision_date) <= 10))
  replace dasara_wa= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 10 & day(decision_date) >= 22) | (month(decision_date) == 10 & day(decision_date) <= 29))
  replace dasara_wa= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 10 & day(decision_date) >= 11) | (month(decision_date) == 10 & day(decision_date) <= 18))
  replace dasara_wa= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 09 & day(decision_date) >= 30) | (month(decision_date) == 10 & day(decision_date) <= 07))
  replace dasara_wa= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 10 & day(decision_date) >= 19) | (month(decision_date) == 10 & day(decision_date) <= 26))
  
  /* month after */
  gen dasara_ma = 0
  replace dasara_ma= 1 if year(decision_date) ==  2010 & ((month(decision_date) == 10 & day(decision_date) >= 17) | (month(decision_date) == 11 & day(decision_date) <= 17))
  replace dasara_ma= 1 if year(decision_date) ==  2011 & ((month(decision_date) == 10 & day(decision_date) >= 06) | (month(decision_date) == 11 & day(decision_date) <= 06))
  replace dasara_ma= 1 if year(decision_date) ==  2012 & ((month(decision_date) == 10 & day(decision_date) >= 24) | (month(decision_date) == 11 & day(decision_date) <= 24))
  replace dasara_ma= 1 if year(decision_date) ==  2013 & ((month(decision_date) == 10 & day(decision_date) >= 13) | (month(decision_date) == 11 & day(decision_date) <= 13))
  replace dasara_ma= 1 if year(decision_date) ==  2014 & ((month(decision_date) == 10 & day(decision_date) >= 03) | (month(decision_date) == 11 & day(decision_date) <= 03))
  replace dasara_ma= 1 if year(decision_date) ==  2015 & ((month(decision_date) == 10 & day(decision_date) >= 22) | (month(decision_date) == 11 & day(decision_date) <= 22))
  replace dasara_ma= 1 if year(decision_date) ==  2016 & ((month(decision_date) == 10 & day(decision_date) >= 11) | (month(decision_date) == 11 & day(decision_date) <= 11))
  replace dasara_ma= 1 if year(decision_date) ==  2017 & ((month(decision_date) == 09 & day(decision_date) >= 30) | (month(decision_date) == 10 & day(decision_date) <= 30))
  replace dasara_ma= 1 if year(decision_date) ==  2018 & ((month(decision_date) == 10 & day(decision_date) >= 19) | (month(decision_date) == 11 & day(decision_date) <= 19))
  
  /* create combined variables for dasara and diwali dates */
  
  /* dasara + diwali - day of */
  gen dasara_diwali = 0
  replace dasara_diwali = (dasara == 1 | diwali == 1)
  
  /* dasara_wa + diwali_wa */
  gen dasara_diwali_wa = 0
  replace dasara_diwali_wa = (dasara_wa == 1 | diwali_wa == 1)
  
  /* dasara_wa + diwali_ma */
  gen dasara_diwali_ma = 0
  replace dasara_diwali_ma = (dasara_ma == 1 | diwali_ma == 1)
  
  /* create a variable for all hindu festivals combined */
  gen all_festivals = (dasara_diwali | rama_navami | holi)
  gen all_festivals_wa = (dasara_diwali_wa | rama_navami_wa | holi_wa)
  gen all_festivals_ma = (dasara_diwali_ma | rama_navami_ma | holi_ma)
  
  /* label vars */
  la var rama_navami "Day of festival"
  la var holi "Day of festival"
  la var dasara_diwali "Days of festival"
  la var rama_navami_wa "Week after festival"
  la var holi_wa "Week after festival"
  la var dasara_diwali_wa "Week after festival"
  la var rama_navami_ma "Month after festival"
  la var holi_ma "Month after festival"
  la var dasara_diwali_ma "Month after festival"
  la var all_festivals "Day of festival"
  la var all_festivals_wa "Week of festival"
  la var all_festivals_ma "Month of festival"

  /* manually set ramadan dates */
  gen ramadan = 0
  replace ramadan = 1 if (year(decision_date) == 2010) & (((month(decision_date) == 08) & (day(decision_date) >= 10)) | ((month(decision_date) == 09) & (day(decision_date) <= 09)))
  replace ramadan = 1 if (year(decision_date) == 2011) & (((month(decision_date) == 07) & (day(decision_date) >= 31)) | ((month(decision_date) == 08) & (day(decision_date) <= 30)))
  replace ramadan = 1 if (year(decision_date) == 2012) & (((month(decision_date) == 07) & (day(decision_date) >= 19)) | ((month(decision_date) == 08) & (day(decision_date) <= 18)))
  replace ramadan = 1 if (year(decision_date) == 2013) & (((month(decision_date) == 07) & (day(decision_date) >= 08)) | ((month(decision_date) == 08) & (day(decision_date) <= 07)))
  replace ramadan = 1 if (year(decision_date) == 2014) & (((month(decision_date) == 06) & (day(decision_date) >= 28)) | ((month(decision_date) == 07) & (day(decision_date) <= 28)))
  replace ramadan = 1 if (year(decision_date) == 2015) & (((month(decision_date) == 06) & (day(decision_date) >= 17)) | ((month(decision_date) == 07) & (day(decision_date) <= 17)))
  replace ramadan = 1 if (year(decision_date) == 2016) & (((month(decision_date) == 06) & (day(decision_date) >= 06)) | ((month(decision_date) == 07) & (day(decision_date) <= 05)))
  replace ramadan = 1 if (year(decision_date) == 2017) & (((month(decision_date) == 05) & (day(decision_date) >= 26)) | ((month(decision_date) == 06) & (day(decision_date) <= 24)))
  replace ramadan = 1 if (year(decision_date) == 2018) & (((month(decision_date) == 05) & (day(decision_date) >= 15)) | ((month(decision_date) == 06) & (day(decision_date) <= 14)))
  replace ramadan = 1 if (year(decision_date) == 2019) & (((month(decision_date) == 05) & (day(decision_date) >= 05)) | ((month(decision_date) == 06) & (day(decision_date) <= 03)))

end
/** END program set_festival_dates **********************************************/

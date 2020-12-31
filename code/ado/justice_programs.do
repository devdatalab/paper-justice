/********************************************************************************/
/* Define program to extract clean position and location from judge designation */
/********************************************************************************/

cap prog drop desgformat
prog def desgformat

  {
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
  }


end

/***************************************END PROGRAM DESGFORMAT********************************************************/


/*******************************************************/
/* Define program to check for overlap in judge tenure */
/*******************************************************/

cap prog drop check_overlap
prog def check_overlap

  {
    
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

  }

end

/* ****************END PROGRAM CHECK_OVERLAP ************ */

/*******************************************************/
/* Define program to prepare main dataset for analysis */
/*******************************************************/

cap prog drop prep_for_analysis
prog def prep_for_analysis

  {

    /* drop unnecessary vars */
    drop date_last_list date_of_decision date_of_filing 
    drop *day
    cap drop start end
    
    /* create offense dummies */
    tab offenses, gen(offense)

    /* format demographic vars for analysis */

    /* gender */
    rename female_class_l def_female 
    replace def_female = . if def_female < 0 
    gen def_male = !(def_female) if def_female != . 

    /* religion */
    rename muslim_class_l def_muslim 
    replace def_muslim = . if def_muslim < 0 
    gen def_nonmuslim = !(def_muslim) if def_muslim != . 

    /* gender for judges */
    rename female_class judge_female 
    replace judge_female = . if judge_female < 0 
    gen judge_male = !(judge_female) if judge_female !=. 

    /* religion for judges */
    rename muslim_class judge_muslim 
    replace judge_muslim = . if judge_muslim < 0 
    gen judge_nonmuslim = !(judge_muslim) if judge_muslim !=. 

    /* label variabes */
    do $jcode/b/label_justice_vars.do

    /****************************/
    /* create outcome variables */
    /****************************/

    /*********************/
    /* Tag Bail Outcomes */
    /*********************/

    /* using purpose names */
    gen bail = 1 if purpose_name == "bail" 

    /* using disposition names */
    replace bail = 1 if regexm(disp_name, "bail") == 1

    /* using type names */
    replace type_name = lower(type_name)
    replace bail = 1 if regexm(type_name, "bail") == 1
    replace bail = 1 if regexm(type_name, "b.app.") == 1
    replace bail = 1 if regexm(type_name, "blapl") == 1
    replace bail = 1 if regexm(type_name, "b a") == 1
    replace bail = 1 if regexm(type_name, "a.b.a") == 1

    /* Bail dismissed or granted */
    gen bail_grant = .

    foreach o in cancelled dismissed reject {
      replace bail_grant = 0 if disp_name == "`o'" & bail == 1
    }

    replace bail_grant = 0 if disp_name == "bail refused"

    foreach o in allowed accepted award {
      replace bail_grant = 1 if disp_name == "`o'" & bail == 1
    }

    replace bail_grant = 1 if disp_name == "bail granted"


    /************************************************/
    /* Tag all dispositions as positive or negative */
    /************************************************/

    gen negative = .

    /* negative outcomes */
    foreach o in dismissed reject convicted abated confession cancelled remanded prison fine {
      replace negative = 1 if disp_name == "`o'"
    }

    /* positive outcomes */
    foreach o in allowed acquitted withdrawn compromise accepted settled compounded probation stayed award quash{
      replace negative = 0 if disp_name == "`o'"
    }
    
    /* some more negative outcomes */
    replace negative = 1 if disp_name == "bail refused"
    replace negative = 1 if disp_name == "plead guilty"

    /* fine is a positive outcome in a bail hearing */
    replace negative = 0 if disp_name == "fine" & bail == 1
    replace negative = 0 if disp_name == "bail granted"
    replace negative = 0 if disp_name == "referred to lok adalat"
    replace negative = 0 if disp_name == "disposal in lok adalat"
    replace negative = 0 if disp_name == "not press"
    replace negative = 0 if disp_name == "258 crpc"

    /* a bail specific positive outcome */
    replace negative = 0 if regexm(disp_name_raw, "release") == 1 & bail == 1

    /* positive outcome one way */
    forval i = 0/1{
      gen positive_`i' = 1 if negative == 0
      replace positive_`i' = 0 if negative == 1
    }

    /* code missings as positive or negative outcomes */
    replace positive_1 = 1 if positive_1 == . & !mi(disp_name_raw)
    replace positive_0 = 0 if positive_0 == . & !mi(disp_name_raw)

    /*************************/
    /* Convicted 1/0 outcome */
    /*************************/

    gen convicted = .

    /* tag convicted */
    foreach o in convicted prison {
      replace convicted = 1 if disp_name == "`o'"
    }

    replace convicted = 1 if disp_name == "plead guilty"

    /* replace as 0 all other dispositions */
    replace convicted = 0 if !mi(disp_name_raw) & mi(convicted)

    /*************************/
    /* Acquitted 1/0 outcome */
    /*************************/

    gen acquitted = .

    foreach i in acquitted allowed {
      replace acquitted = 1 if disp_name == "`i'"
    }

    replace acquitted = 1 if disp_name == "258 crpc"
    replace acquitted = 0 if mi(acquitted) & !mi(disp_name_raw)

    /* generate fixed effect vars */
    egen loc_pos = group(state_code dist_code court_no position)
    egen loc = group(state_code dist_code court_no)
    egen loc_month = group(state_code dist_code court_no filing_year filing_month)
    egen loc_year = group(state_code dist_code court_no filing_year)
    egen acts = group(act section)

    /* create share of unclear outcomes at act-section level */
    gen unclear = 1 if mi(negative) & !mi(disp_name_raw) & bail != 1
    replace unclear = 0 if !mi(negative) & !mi(disp_name_raw) & bail != 1
    bys acts : egen unclear_perc = mean(unclear)
    drop unclear

    /* generate var for clustering standard erros */
    egen judge = group(state_code dist_code court_no position tenure_start tenure_end)

    /* label newly created variables */
    la var bail "Bail-related case (==1)"
    la var negative "Negative outcome (1/0)"
    la var convicted "Convicted (1/0)"
    la var loc_pos "location position fixed effect"
    la var acts "act section fixed effect"
    la var loc_month "court-year-month fixed effect"
    la var loc_year "court-year fixed effect"
    la var judge "unique id for judge dataset"
    la var loc "location/court fixed effect"
    la var unclear_perc "share of unclear outcomes at act-section level"

    /* order variables */
    order cino state_* dist_code district_name court_no court case_no court_name judge_desg_raw position, first
    order bail negative *muslim* *female* *male* type_name purpose_name* disp_name*, after(position)
    order date decision_date last_hearing filing_date *delay* date* *year, after(disp_name_raw)
    order cino act sect* bailable*, first

    /* create crime type dummies for sub-sample analyses */
    /* crime categories */
    foreach crime in person_crime property_crime other_crime murder women_crime religion {
      gen `crime' = .
    }

    /* generate dummy for person crime */
    /* homicide, dowry death, suicide, abetment of suicide, infanticide */
    /* hurt, confinement, assault, kidnapping, traficking, slabery, sexual assault */
    forval i = 14/21 {
      replace person_crime = 1 if offense`i' == 1
    }

    /* generate dummy for property crime */
    /* theft,robbery,extortion,property,breach of trust,cheating,fraudulence */
    /* mischief, trespassing */
    forval i = 22/30{
      replace property_crime = 1 if offense`i' == 1
    }
    
    /* generate dummy for crimes against women */
    foreach i in 312 313 314 354 354 366 375 376 498 {
      replace women_crime = 1 if section == "`i'"
    }

    /* generate dummy for all other crimes */
    forval i = 1/13{
      replace other_crime = 1 if offense`i' == 1
    }

    forval i = 31/33{
      replace other_crime = 1 if offense`i' == 1
    }

    forval i = 35/37{
      replace other_crime = 1 if offense`i' == 1
    }

    /* some specific crime dummies */
    replace murder = 1 if offense14 == 1
    replace religion = 1 if offense13 == 1

    /* fix missing values for dummy vars */
    foreach x in person_crime property_crime murder religion women_crime other_crime{
      replace `x' = 0 if mi(`x') & !mi(offense1)
    }
    
    /* label variables */
    label var person_crime    "Person Crime" 
    label var property_crime  "Property Crime" 
    label var women_crime     "Crimes agains women"
    label var other_crime     "Other Crime" 

    /* count the number of muslim/female judges within each fixed effect */
    gen drop  = 0
    foreach type in muslim nonmuslim female male {
      bys loc_month: egen lmcount_`type'_judge = sum(judge_`type')
      bys loc_year: egen lycount_`type'_judge = sum(judge_`type')
      bys loc_month: egen lmcount_`type'_def = sum(def_`type')
      bys loc_year: egen lycount_`type'_def = sum(def_`type')

      replace drop = 1 if lmcount_`type'_judge == 0 & lycount_`type'_judge == 0 & lmcount_`type'_def == 0 & lycount_`type'_def == 0
    }

    /* drop cases/locs that don't fit any of the inclusion criteria */
    drop if drop == 1

    /* drop if we don't observe judge gender or religion */
    drop if mi(judge_muslim) & mi(judge_male)

    /* drop if we don't observe defendant gender or religion */
    drop if mi(def_muslim) & mi(def_male)

    /* create a sample for each type / fixed effect */
    gen lm_religion = (lmcount_muslim_judge > 0) & (lmcount_nonmuslim_judge > 0)
    gen lm_gender = (lmcount_female_judge > 0) & (lmcount_male_judge > 0)
    gen ly_religion = (lycount_muslim_judge > 0) & (lycount_nonmuslim_judge > 0)
    gen ly_gender = (lycount_female_judge > 0) & (lycount_male_judge > 0)

    /* label fixed effects */
    la var lm_religion "Non-zero muslim & non-mus judges in court in a month"
    la var lm_gender "Non-zero female & male judges in a court in a month"
    la var ly_religion "Non-zero muslim & non-mus judges in court in a year"
    la var ly_gender "Non-zero female & male judges in a court in a year"

    /* reverse convicted so it points the same way -- pos effect = pos outcome */
    replace conv = 1 - conv
    ren convicted non_convicted
    label var non_convicted "not convicted"

    /* drop bulky variables */
    drop drop lmcount* lycount* res_name court_name state_name district_name pet_adv pet_name judge_desg_raw purpose_name*

    /* create interaction variables */
    gen judge_def_female = judge_female * def_female
    gen judge_def_muslim = judge_muslim * def_muslim
    gen judge_def_male = judge_male * def_male
    gen judge_def_nonmuslim = judge_nonmuslim * def_nonmuslim

    /* label vars */
    la var judge_def_female "Female judge and defendant"
    la var judge_def_muslim "Muslim judge and defendant"

  }

end

/***************************************END PROGRAM DESGFORMAT********************************************************/

/**************************************************************/
/* Define program to prepare event study dataset for analysis */
/**************************************************************/

cap prog drop prep_for_analysis_event
prog def prep_for_analysis_event

  {

    /* drop unnecessary vars */
    drop date_last_list date_of_decision date_of_filing 
    drop *day
    cap drop start end

    /* create offense dummies */
    tab offenses, gen(offense)

    /* format demographic vars for analysis */

    /* gender */
    rename female_class_l def_female 
    replace def_female = . if def_female < 0 
    gen def_male = !(def_female) if def_female != . 

    /* religion */
    rename muslim_class_l def_muslim 
    replace def_muslim = . if def_muslim < 0 
    gen def_nonmuslim = !(def_muslim) if def_muslim != . 

    /* label variabes */
    do $jcode/b/label_justice_vars_event.do

    /****************************/
    /* create outcome variables */
    /****************************/

    /*********************/
    /* Tag Bail Outcomes */
    /*********************/

    /* using purpose names */
    gen bail = 1 if purpose_name == "bail" 

    /* using disposition names */
    replace bail = 1 if regexm(disp_name, "bail") == 1

    /* using type names */
    replace type_name = lower(type_name)
    replace bail = 1 if regexm(type_name, "bail") == 1
    replace bail = 1 if regexm(type_name, "b.app.") == 1
    replace bail = 1 if regexm(type_name, "blapl") == 1
    replace bail = 1 if regexm(type_name, "b a") == 1
    replace bail = 1 if regexm(type_name, "a.b.a") == 1

    /* Bail dismissed or granted */
    gen bail_grant = .

    foreach o in cancelled dismissed reject {
      replace bail_grant = 0 if disp_name == "`o'" & bail == 1
    }

    replace bail_grant = 0 if disp_name == "bail refused"

    foreach o in allowed accepted award {
      replace bail_grant = 1 if disp_name == "`o'" & bail == 1
    }

    replace bail_grant = 1 if disp_name == "bail granted"


    /************************************************/
    /* Tag all dispositions as positive or negative */
    /************************************************/

    gen negative = .

    /* negative outcomes */
    foreach o in dismissed reject convicted abated confession cancelled remanded prison fine {
      replace negative = 1 if disp_name == "`o'"
    }

    /* positive outcomes */
    foreach o in allowed acquitted withdrawn compromise accepted settled compounded probation stayed award quash{
      replace negative = 0 if disp_name == "`o'"
    }
    
    /* some more negative outcomes */
    replace negative = 1 if disp_name == "bail refused"
    replace negative = 1 if disp_name == "plead guilty"

    /* fine is a positive outcome in a bail hearing */
    replace negative = 0 if disp_name == "fine" & bail == 1
    replace negative = 0 if disp_name == "bail granted"
    replace negative = 0 if disp_name == "referred to lok adalat"
    replace negative = 0 if disp_name == "disposal in lok adalat"
    replace negative = 0 if disp_name == "not press"
    replace negative = 0 if disp_name == "258 crpc"

    /* a bail specific positive outcome */
    replace negative = 0 if regexm(disp_name_raw, "release") == 1 & bail == 1

    /* positive outcome one way */
    forval i = 0/1{
      gen positive_`i' = 1 if negative == 0
      replace positive_`i' = 0 if negative == 1
    }

    /* code missings as positive or negative outcomes */
    replace positive_1 = 1 if positive_1 == . & !mi(disp_name_raw)
    replace positive_0 = 0 if positive_0 == . & !mi(disp_name_raw)

    /*************************/
    /* Convicted 1/0 outcome */
    /*************************/

    gen convicted = .

    /* tag convicted */
    foreach o in convicted prison {
      replace convicted = 1 if disp_name == "`o'"
    }

    replace convicted = 1 if disp_name == "plead guilty"

    /* replace as 0 all other dispositions */
    replace convicted = 0 if !mi(disp_name_raw) & mi(convicted)

    /*************************/
    /* Acquitted 1/0 outcome */
    /*************************/

    gen acquitted = .

    foreach i in acquitted allowed {
      replace acquitted = 1 if disp_name == "`i'"
    }

    replace acquitted = 1 if disp_name == "258 crpc"
    replace acquitted = 0 if mi(acquitted) & !mi(disp_name_raw)

    /* generate fixed effect vars */
    egen loc = group(state_code dist_code court_no)
    egen loc_month = group(state_code dist_code court_no filing_year filing_month)
    egen loc_year = group(state_code dist_code court_no filing_year)
    egen acts = group(act section)

    /* create share of unclear outcomes at act-section level */
    gen unclear = 1 if mi(negative) & !mi(disp_name_raw) & bail != 1
    replace unclear = 0 if !mi(negative) & !mi(disp_name_raw) & bail != 1
    bys acts : egen unclear_perc = mean(unclear)
    drop unclear

    /* label newly created variables */
    la var bail "Bail-related case (==1)"
    la var negative "Negative outcome (1/0)"
    la var convicted "Convicted (1/0)"
    la var acts "act section fixed effect"
    la var loc_month "court-year-month fixed effect"
    la var loc_year "court-year fixed effect"
    la var loc "location/court fixed effect"
    la var unclear_perc "share of unclear outcomes at act-section level"

    /* order variables */
    order cino state_* dist_code district_name court_no court_name judge_desg_raw position, first
    order bail negative *muslim* *female* *male* type_name purpose_name* disp_name*, after(position)
    order date decision_date last_hearing filing_date *delay* date* *year, after(disp_name_raw)
    order cino act sect* bailable*, first

    /* create crime type dummies for sub-sample analyses */
    /* crime categories */
    foreach crime in person_crime property_crime other_crime murder women_crime religion {
      gen `crime' = .
    }

    /* generate dummy for person crime */
    /* homicide, dowry death, suicide, abetment of suicide, infanticide */
    /* hurt, confinement, assault, kidnapping, traficking, slabery, sexual assault */
    forval i = 14/21 {
      replace person_crime = 1 if offense`i' == 1
    }

    /* generate dummy for property crime */
    /* theft,robbery,extortion,property,breach of trust,cheating,fraudulence */
    /* mischief, trespassing */
    forval i = 22/30{
      replace property_crime = 1 if offense`i' == 1
    }
    
    /* generate dummy for crimes against women */
    foreach i in 312 313 314 354 354 366 375 376 498 {
      replace women_crime = 1 if section == "`i'"
    }

    /* generate dummy for all other crimes */
    forval i = 1/13{
      replace other_crime = 1 if offense`i' == 1
    }

    forval i = 31/33{
      replace other_crime = 1 if offense`i' == 1
    }

    forval i = 35/37{
      replace other_crime = 1 if offense`i' == 1
    }

    /* some specific crime dummies */
    replace murder = 1 if offense14 == 1
    replace religion = 1 if offense13 == 1

    /* fix missing values for dummy vars */
    foreach x in person_crime property_crime murder religion women_crime other_crime{
      replace `x' = 0 if mi(`x') & !mi(offense1)
    }
    
    /* label variables */
    label var person_crime    "Person Crime" 
    label var property_crime  "Property Crime" 
    label var women_crime     "Crimes agains women"
    label var other_crime     "Other Crime" 
    label var religion        "Religious offenses"
    label var murder          "Murder"

    la var num_judges "No. of judges in court during the transition window"
    la var num_mus_judges "# Muslim judges in court during transition window"
    la var num_male_judges "# Male judges in court during transition window"
    la var num_female_judges "# Female judges in court during transition window"
    
    /* reverse convicted so it points the same way -- pos effect = pos outcome */
    replace conv = 1 - conv
    ren convicted non_convicted
    label var non_convicted "not convicted"

    /* drop bulky variables */
    drop pet_adv pet_name res_adv res_name court_name ///
        judge_desg_raw purpose_name* res_name judge_desg position district_name 

    
  }

end

/***************************************END PROGRAM PREP_FOR_ANALYSIS_EVENT********************************************************/

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

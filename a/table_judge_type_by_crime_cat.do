use $jdata/justice_analysis, clear

est clear

/* show distribution of female judges by crime category */
estpost tabstat judge_female, by(crime_category) s(mean semean) 
est store panel1

/* repeat for Muslim judges */
estpost tabstat judge_muslim, by(crime_category) s(mean semean) 
est store panel2

/* AP: I manually edited this ouput table to add some hlines and capitalize crime categories */

/* Table output is in $out/table_judges_by_crime_category.tex */

//esttab panel1 panel2 using "$tmp/table_judges_by_crime_category.tex", ///
//    cells("mean(fmt(%10.4f)) semean(fmt(%10.4f))") ///
//    collabels("Mean" "SE Mean") ///
//    mtitles("Judge Female" "Judge Muslim") ///
//    noobs nonumber nonote replace ///
//    fragment ///
//    prehead("\begin{tabular}{lcccc}") ///
//    posthead("\hline\hline") ///
//    prefoot("\hline") ///
//    postfoot("\hline\hline" "\end{tabular}")

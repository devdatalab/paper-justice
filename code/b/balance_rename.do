/* format variables for tables */
la var murder "Murder"
la var women_crime "Crimes against women"
la var offense16 "Violent crimes causing hurt"
la var offense21 "Sexual assault"
la var offense22 "Petty theft"
la var offense23 "Violent theft/dacoity"
la var offense30 "Trespass"
la var offense34 "Marriage offenses"
la var other "Other crimes"

/* combine all offenses to do with disturbing the public */
gen peace = offense5
replace peace = 1 if offense11 == 1
replace peace = 1 if offense12 == 1
drop offense5 offense11 offense12

/* combine public safety, obscenity, and  */
la var peace "Disturbed pub. health/tranquility"
cap la var all "Total"

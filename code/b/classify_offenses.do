/*********************/
/* classify offenses */
/*********************/
gen offenses = .

/* rules of classification */
/* based on this document: https://districts.ecourts.gov.in/sites/default/files/Act%20%26%20Sections_0_5_0.pdf */

/* abetment */
forval i = 109/117{
  replace offenses = 1 if regexm(section, "`i'") == 1
  }

/* criminal conspiracy */
replace offenses = 2 if regexm(section, "120") == 1

/* against the state */
forval i = 121/128{
  replace offenses = 3 if regexm(section, "`i'") == 1
  }

replace offenses = 3 if regexm(section, "130") == 1 

/* army, navy or force */
forval i = 131/140{
  replace offenses = 4 if regexm(section, "`i'") == 1
  }

/* public tranquility */
forval i = 141/160{
  replace offenses = 5 if regexm(section, "`i'") == 1
  }

/* public servants/election fraudulence */
forval i = 161/171{
  replace offenses = 6 if regexm(section, "`i'") == 1
  }

/* contempt/messing with a public servant */
forval i = 172/190{
  replace offenses = 7 if regexm(section, "`i'") == 1
  }

/* falsifying evidence/disrupting judicial process */
forval i = 191/229{
  replace offenses = 8 if regexm(section, "`i'") == 1
  }

/* coins and stamps */
forval i = 230/263{
  replace offenses = 9 if regexm(section, "`i'") == 1
  }

/* weights and measures */
forval i = 264/267{
  replace offenses = 10 if regexm(section, "`i'") == 1
  }

/* public health safety */
forval i = 268/289{
  replace offenses = 11 if regexm(section, "`i'") == 1
  }

/* obscenity, nuisance, and lotteries */
forval i = 290/294{
  replace offenses = 12 if regexm(section, "`i'") == 1
  }

/* religious offense */
forval i = 295/298{
  replace offenses = 13 if regexm(section, "`i'") == 1
  }

/* suicide, homicide, dowry death, abetment of suicide */
forval i = 299/311{
  replace offenses = 14 if regexm(section, "`i'") == 1
  }

/* forced miscarriage and infanticide */
forval i = 312/318{
  replace offenses = 15 if regexm(section, "`i'") == 1
  }

/* hurt */
forval i = 319/338{
  replace offenses = 16 if regexm(section, "`i'") == 1
  }

/* confinement */
forval i = 339/348{
  replace offenses = 17 if regexm(section, "`i'") == 1
  }

/* assault */
forval i = 349/358{
  replace offenses = 18 if regexm(section, "`i'") == 1
  }

/* kidnapping */
forval i = 359/366{
  replace offenses = 19 if regexm(section, "`i'") == 1
  }

forval i = 368/369{
  replace offenses = 19 if regexm(section, "`i'") == 1
  }

/* trafficking and slavery */
replace offenses = 20 if regexm(section, "366") == 1 & regexm(section, "B") == 1
replace offenses = 20 if regexm(section, "366") == 1 & regexm(section, "A") == 1

forval i = 370/374{
  replace offenses = 20 if regexm(section, "`i'") == 1
  }

/* sexual assault */
forval i = 375/377{
  replace offenses = 21 if regexm(section, "`i'") == 1
  }

replace offenses = 21 if regexm(section, "354") == 1

/* theft */
forval i = 378/382{
  replace offenses = 22 if regexm(section, "`i'") == 1
  }

/* robbery/dacoity */
forval i = 390/402{
  replace offenses = 23 if regexm(section, "`i'") == 1
  }

/* extortion */
forval i = 383/389{
  replace offenses = 24 if regexm(section, "`i'") == 1
  }

/* property */
forval i = 403/404{
  replace offenses = 25 if regexm(section, "`i'") == 1
  }

forval i = 410/414{
  replace offenses = 25 if regexm(section, "`i'") == 1
  }

/* criminal breach of trust */
forval i = 405/409{
  replace offenses = 26 if regexm(section, "`i'") == 1
  }

/* cheating */
forval i = 415/420{
  replace offenses = 27 if regexm(section, "`i'") == 1
  }

/* fraudulent deeds */
forval i = 421/424{
  replace offenses = 28 if regexm(section, "`i'") == 1
  }

/* mischief */
forval i = 425/440{
  replace offenses = 29 if regexm(section, "`i'") == 1
  }

/* trespass */
forval i = 441/462{
  replace offenses = 30 if regexm(section, "`i'") == 1
  }

/* forgery of documents and accounts */
forval i = 463/477{
  replace offenses = 31 if regexm(section, "`i'") == 1
  }

/* counterfeiting property or other marks */
forval i = 478/489{
  replace offenses = 32 if regexm(section, "`i'") == 1
  }

/* breach of contracts of service */
forval i = 490/492{
  replace offenses = 33 if regexm(section, "`i'") == 1
  }

/* marriage offences/adultery */
forval i = 493/498{
  replace offenses = 34 if regexm(section, "`i'") == 1
  }

/* cruetly by husband relatives */
replace offenses = 35 if regexm(section, "498") == 1 & regexm(section, "A") == 1

/* defamation */
forval i = 499/502{
  replace offenses = 36 if regexm(section, "`i'") == 1
  }

/* intimidation */
forval i = 503/510{
  replace offenses = 37 if regexm(section, "`i'") == 1
  }

/* commit offence  */
replace offenses = 38 if regexm(section, "511") == 1

/* code of criminal procedure */
replace offenses = 999 if act == "Code of Criminal Procedure"




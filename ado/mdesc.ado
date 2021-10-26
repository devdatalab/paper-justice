*! mdesc Version 2.1 dan_blanchette@unc.edu 25Aug2011 
*!      Rose Anne Medeiros            |           Dan Blanchette
*! Department of Sociology, Rice Univ | the carolina population center, unc-ch
*- made it so that output looks nicer when number of obs with missing values is 
*   greater then 99,999 and made some updates to the help file.
*  and made some changes that Nick Cox suggested.
* mdesc Version 2.0 dan_blanchette@unc.edu 10Jun2011 
* mdesc Version 1.0 Rose Anne Medeiros 18Jul2008
* Returns a table with number missing, total, and missing/total

program mdesc, rclass byable(recall)
version 10
    syntax [varlist] [if] [in] [, ABbreviate(integer 12) ANY ALL NOne ]

if !missing("`any'") + !missing("`all'") + !missing("`none'") > 1 {
  display as error "specify only the {opt any} option or the {opt all} option or the {opt none}"
  exit 198
}

local nvars : word count `varlist' 
if [!missing("`any'") | !missing("`all'")] & `nvars' == 1  {
  if !missing("`any'") {
    display as green "since only 1 variable was specified, the {opt any} option will be ignored"
    local any
  }
  else if !missing("`all'") {
    display as green "since only 1 variable was specified, the {opt all} option will be ignored"
    local all
  }
}

if `abbreviate' > 32 {
  local abbreviate= 32
}

local c1= 17
local c2= 16
local c3= 47
if `abbreviate' > 16 {
  local c1= `abbreviate' + 2
  local c2= `abbreviate' + 1
  local c3= `abbreviate' + 30
}

if !missing("`none'") {
  display as text _n "            " _column(`c1')"{c |}      None                        Percent              "
  display as text    "    Variable" _column(`c1')"{c |}     Missing          Total     Not Missing"
}
else {
  display as text _n "    Variable" _column(`c1')"{c |}     Missing          Total     Percent Missing"
}
display as text "{hline `c2'}{c +}{hline `c3'}"

// this generates a local macro called touse
marksample touse, novarlist
quietly: count  if `touse' == 1
tempvar total
scalar `total'= r(N)

if missing("`any'") & missing("`all'") & missing("`none'") {
  foreach var of local varlist {
     quietly {
         // tempvar mytemp
         // gen `mytemp'= missing(`var')
         count  if missing(`var') & `touse' == 1
         return scalar miss= r(N)
         // count  if `touse' == 1
         // return scalar total= r(N)
  	 return scalar total= scalar(`total')
         return scalar percent= (return(miss)/return(total) * 100)
         // drop `mytemp'
     }
         display as text %`=`c1'-2's abbrev("`var'",`abbreviate') _column(`c1')"{c |} " ///
           as result %11.0gc `return(miss)' "    "     ///
           %11.0gc `return(total)' "       " ///
           %8.2f `return(percent)'
         if return(miss) > 0 { 
           local miss_vars `miss_vars' `var'
         }
         return local miss_vars `miss_vars'
         if return(miss) == 0 { 
           local notmiss_vars `notmiss_vars' `var'
         }
         return local notmiss_vars `notmiss_vars'
  }
  display as text "{hline `c2'}{c +}{hline `c3'}"
}
else if !missing("`any'") {
  quietly {
    tempvar mytemp
    local n= 1
    foreach var of varlist `varlist' {
      if `n' == 1 {
        gen byte `mytemp'= 1  if missing(`var')
      }
      else {
        replace `mytemp'= 1  if missing(`var')
      }
      local n= `n' + 1
    }
    count  if `mytemp' == 1 & `touse' == 1
    return scalar miss= r(N)
    return scalar total= scalar(`total')
    return scalar percent= (return(miss)/return(total) * 100)
  }
  display as text %`=`c1'-2's abbrev("any vars",`abbreviate') _column(`c1')"{c |}    " ///
    as result %8.0gc `return(miss)' "    "     ///
    %8.0gc `return(total)' "       " ///
    %8.2f `return(percent)'
  display as text "{hline `c2'}{c +}{hline `c3'}"
}
else if !missing("`all'") {
  quietly {
    tempvar mytemp
    local n= 1
    foreach var of varlist `varlist' {
      if `n' == 1 {
        gen byte `mytemp'= 1  if missing(`var')
      }
      else {
        replace `mytemp'= .  if !missing(`var')
      }
      local n= `n' + 1
    }
    count  if `mytemp' == 1 & `touse' == 1
    return scalar miss= r(N)
    return scalar total= scalar(`total')
    return scalar percent= (return(miss)/return(total) * 100)
  }
  display as text %`=`c1'-2's abbrev("all vars",`abbreviate') _column(`c1')"{c |}    " ///
    as result %8.0gc `return(miss)' "    "     ///
    %8.0gc `return(total)' "       " ///
    %8.2f `return(percent)'
  display as text "{hline `c2'}{c +}{hline `c3'}"
}
else if !missing("`none'") {
  quietly {
    tempvar mytemp
    local n= 1
    foreach var of varlist `varlist' {
      if `n' == 1 {
        gen byte `mytemp'= 1  if !missing(`var')
      }
      else {
        replace `mytemp'= .  if missing(`var')
      }
      local n= `n' + 1
    }
    count  if `mytemp' == 1 & `touse' == 1
    return scalar miss= r(N)
    return scalar total= scalar(`total')
    return scalar percent= (return(miss)/return(total) * 100)
  }
  display as text %`=`c1'-2's abbrev("no vars",`abbreviate') _column(`c1')"{c |}    " ///
    as result %8.0gc `return(miss)' "    "     ///
    %8.0gc `return(total)' "       " ///
    %8.2f `return(percent)'
  display as text "{hline `c2'}{c +}{hline `c3'}"
}


end


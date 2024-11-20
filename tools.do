
global estout_params       cells(b(fmt(3) star) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) varlabels(_cons Constant) label stats(N r2, fmt(0 2)) collabels(none) style(tex) replace prehead("\setlength{\linewidth}{.1cm} \begin{center}" "\newcommand{\contents}{\begin{tabular}{l*{@M}{c}}" "\hline\hline") posthead(\hline) prefoot(\hline) postfoot("\hline" "\multicolumn{@span}{p{\linewidth}}{\$^{*}p<0.10, ^{**}p<0.05, ^{***}p<0.01\$} \\" "\multicolumn{@span}{p{\linewidth}}{\footnotesize \tablenote}" "\end{tabular} }" "\setbox0=\hbox{\contents}" "\setlength{\linewidth}{\wd0-2\tabcolsep-.25em} \contents \end{center}")
global estout_params_no_p  cells(b(fmt(3) star) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) varlabels(_cons Constant) label stats(N r2, fmt(0 2)) collabels(none) style(tex) replace prehead("\setlength{\linewidth}{.1cm} \begin{center}" "\newcommand{\contents}{\begin{tabular}{l*{@M}{c}}" "\hline\hline") posthead(\hline) prefoot(\hline) postfoot("\hline" "\multicolumn{@span}{p{\linewidth}}{}" "\end{tabular} }" "\setbox0=\hbox{\contents}" "\setlength{\linewidth}{\wd0-2\tabcolsep-.25em} \contents \end{center}")
global estout_params_np    cells(b(fmt(3) star) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) varlabels(_cons Constant) label stats(N r2, fmt(0 2)) collabels(none) style(tex) replace prehead("\setlength{\linewidth}{.1cm} \begin{center}" "\newcommand{\contents}{\begin{tabular}{l*{@M}{c}}" "\hline\hline") posthead(\hline)                 postfoot("\hline" "\multicolumn{@span}{p{\linewidth}}{\$^{*}p<0.10, ^{**}p<0.05, ^{***}p<0.01\$} \\" "\multicolumn{@span}{p{\linewidth}}{\footnotesize \tablenote}" "\end{tabular} }" "\setbox0=\hbox{\contents}" "\setlength{\linewidth}{\wd0-2\tabcolsep-.25em} \contents \end{center}")
global estout_params_scr   cells(b(fmt(3) star) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) varlabels(_cons Constant) label stats(N r2, fmt(0 2)) collabels(none)
global estout_params_txt   cells(b(fmt(3) star) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) varlabels(_cons Constant) label stats(N r2, fmt(0 2)) collabels(none) replace
global ep_txt $estout_params_txt
global estout_params_excel cells(b(fmt(3) star) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) varlabels(_cons Constant) label stats(N r2, fmt(0 2)) collabels(none) style(tab)  replace
global estout_params_html  cells(b(fmt(3) star) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) varlabels(_cons Constant) label stats(N r2, fmt(0 2)) collabels(none) style(html) replace prehead("<html><body><table style='border-collapse:collapse;' border=1") postfoot("</table></body></html>")
global estout_params_fstat cells(b(fmt(3) star) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) varlabels(_cons Constant) label stats(f_stat N r2, labels("F Statistic" "N" "R2" suffix(\hline)) fmt(%9.4g)) collabels(none) style(tex) replace prehead("\setlength{\linewidth}{.1cm} \begin{center}" "\newcommand{\contents}{\begin{tabular}{l*{@M}{c}}" "\hline\hline") posthead(\hline) prefoot(\hline) postfoot("\hline" "\multicolumn{@span}{p{\linewidth}}{$^{*}p<0.10, ^{**}p<0.05, ^{***}p<0.01$} \\" "\multicolumn{@span}{p{\linewidth}}{\footnotesize \tablenote}" "\end{tabular} }" "\setbox0=\hbox{\contents}" "\setlength{\linewidth}{\wd0-2\tabcolsep-.25em} \contents \end{center}")
global tex_p_value_line "\multicolumn{@span}{p{\linewidth}}{\$^{*}p<0.10, ^{**}p<0.05,^{***}p<0.01\$} \\"
global esttab_params       prehead("\setlength{\linewidth}{.1cm} \begin{center}" "\newcommand{\contents}{\begin{tabular}{l*{@M}{c}}" "\hline\hline") posthead(\hline) prefoot(\hline) postfoot("\hline" "\multicolumn{@span}{p{\linewidth}}{\footnotesize \tablenote}" "\end{tabular} }" "\setbox0=\hbox{\contents}" "\setlength{\linewidth}{\wd0-2\tabcolsep-.25em} \contents \end{center}")

cap pr drop set_log_time
pr def set_log_time
  di ""
end


  /**********************************************************************************************/
  /* program quireg : display a name, beta coefficient and p value from a regression in one line */
  /***********************************************************************************************/
  cap prog drop quireg
  prog def quireg, rclass
  {
    syntax varlist(fv ts) [pweight aweight] [if], [cluster(varlist) title(string) vce(passthru) noconstant s(real 40) absorb(varlist) disponly robust]
    tokenize `varlist'
    local depvar = "`1'"
    local xvar = subinstr("`2'", ",", "", .)

    if "`cluster'" != "" {
      local cluster_string = "cluster(`cluster')"
    }

    if mi("`disponly'") {
      if mi("`absorb'") {
        cap qui reg `varlist' [`weight' `exp'] `if',  `cluster_string' `vce' `constant' robust
        if _rc == 1 {
          di "User pressed break."
        }
        else if _rc {
          display "`title': Reg failed"
          exit
        }
      }
      else {
        /* if absorb has a space (i.e. more than one var), use reghdfe */
        if strpos("`absorb'", " ") {
          cap qui reghdfe `varlist' [`weight' `exp'] `if',  `cluster_string' `vce' absorb(`absorb') `constant'
        }
        else {
          cap qui areg `varlist' [`weight' `exp'] `if',  `cluster_string' `vce' absorb(`absorb') `constant' robust
        }
        if _rc == 1 {
          di "User pressed break."
        }
        else if _rc {
          display "`title': Reg failed"
          exit
        }
      }
    }
    local n = `e(N)'
    local b = _b[`xvar']
    local se = _se[`xvar']

    quietly test `xvar' = 0
    local star = ""
    if r(p) < 0.10 {
      local star = "*"
    }
    if r(p) < 0.05 {
      local star = "**"
    }
    if r(p) < 0.01 {
      local star = "***"
    }
    di %`s's "`title' `xvar': " %10.5f `b' " (" %10.5f `se' ")  (p=" %5.2f r(p) ") (n=" %6.0f `n' ")`star'"
    return local b = `b'
    return local se = `se'
    return local n = `n'
    return local p = r(p)
  }
  end
  /* *********** END program quireg **********************************************************************************************/


  /**********************************************************************************/
  /* program insert_est_into_file : *Inserts* a regression estimate to a csv file   */
  /* example: insert_est_into_file using $tmp/foo.csv, spec(main) b(treatment)

     - will add/replace the following four lines to foo.csv:
        "main_beta, 0.123"
        "main_starbeta, 0.123**"
        "main_p, 0.01"
        "main_se, 0.061"
    */
  /* alternately numbers can be suppled directly (no additional formatting will be done):
    insert_est_into_file using $tmp/foo.csv, spec(main) b(0.123) se(0.061) p(0.02) t(2.43)

    If you supply t(), then p() will be ignored and calculated with 1000 degrees of freedom.

    */

  /**********************************************************************************/
  cap prog drop insert_est_into_file
  prog def insert_est_into_file
  {
    syntax using/, b(string) spec(string) [se(string) p(string) t(string) n(string) r2(string)]

    /* validate what was passed in */
    if (!mi("`se'") & ((mi("`p'") & mi("`t'")) | mi("`n'"))) | (mi("`se'") & (!mi("`p'") | !mi("`t'") | !mi("`n'"))) {
        di "If you pass se() into insert_est_into_file(), you also need to pass n() and p() / t(), and vice versa"
        error 789
    }

    /* if se() is missing, we need to get these estimates from the last regression */
    if mi("`se'") {

      /* get number of observations */
      qui count if e(sample)
      local n: di %15.0f (`r(N)')

      /* get b and se from estimate */
      local beta: di %6.4f (_b["`b'"])
      local se: di %6.4f (_se["`b'"])
        local r2: di %5.2f (`e(r2)')

      /* get p value */
      qui test `b' = 0
      local p: di %5.2f (`r(p)')
      if "`p'" == "." {
        local p = 1
        local beta = 0
        local se = 0
      }
    }

    /* else, se() is not missing, and all parameters are already passed in */
    else {

      /* if p value is not passed in, calculate it from t stat */
      if mi("`p'") {
          local p: di %5.4f (ttail(1000, `t'))
      }
      local beta `b'

      /* make sure n is in right format */
      local n: di %1.0f (`n')
    }
    /* calculate starbeta from `p' */
    count_stars, p(`p')
    local starbeta "`beta'`r(stars)'"

    /* insert the estimates into the file given by `using' */
    insert_into_file using `using', key(`spec'_beta) value(`beta') format("%6.4f")
    insert_into_file using `using', key(`spec'_se) value(`se') format("%6.4f")
    insert_into_file using `using', key(`spec'_starbeta) value(`starbeta') format("%6.4f")
    insert_into_file using `using', key(`spec'_p) value(`p')format("%6.4f")
    insert_into_file using `using', key(`spec'_n) value(`n') format("%15.0f")

    /* r2 can be missing, so only insert if we got it */
    if !mi("`r2'") insert_into_file using `using', key(`spec'_r2) value(`r2')
  }
  end
  /* *********** END program insert_est_into_file ***************************************** */


  /***********************************************************************************/
  /* program obs_check : - Assert we have at least X obs in some subgroup            */
  /*                     - Count and return number of observations, with tagging     */
  /***********************************************************************************/
  cap prog drop obs_check
  prog def obs_check, rclass
  {
    syntax [if/], [n(integer 0) tag(varlist) unique(varlist)]

    /* set `if' variable to 1 if not specified */
    if mi(`"`if'"') {
      local if 1
    }

    /* tag observations if requested */
    cap drop __obs_check_tag
    if !mi("`tag'") {
      egen __obs_check_tag = tag(`tag') if `if'
    }
    else {
      gen __obs_check_tag = 1
    }

    /* count only obs unique on varlist if requested */
    cap drop __unique
    if !mi("`unique'") {
      bys `unique': gen __unique = _N == 1
    }
    else {
      gen __unique = 1
    }

    count if __obs_check_tag & __unique & `if'
    local count = r(N)

    if !mi("`n'") {
      assert `count' >= `n'
    }
    capdrop __obs_check_tag __unique
    return local N = `count'
  }
  end
  /* *********** END program obs_check ***************************************** */


  /**********************************************************************************/
  /* program append_to_file : Append a passed in string to a file                   */
  /**********************************************************************************/
  cap prog drop append_to_file
  prog def append_to_file
  {
    syntax using/, String(string) [format(string) erase]

    tempname fh

    cap file close `fh'

    if !mi("`erase'") cap erase `using'

    file open `fh' using `using', write append
    file write `fh'  `"`string'"'  _n
    file close `fh'
  }
  end
  /* *********** END program append_to_file ***************************************** */


  /**********************************************************************************/
  /* program append_est_to_file : Appends a regression estimate to a csv file       */
  /**********************************************************************************/
  cap prog drop append_est_to_file
  prog def append_est_to_file
  {
    syntax using/, b(string) Suffix(string)

    /* get number of observations */
    qui count if e(sample)
    local n: di %15.0f (`r(N)')

    /* get b and se from estimate */
    local beta = _b["`b'"]
    local se   = _se["`b'"]

    /* get p value */
    qui test `b' = 0
    local p = `r(p)'
    if "`p'" == "." {
      local p = 1
      local beta = 0
      local se = 0
    }
    append_to_file using `using', s("`beta',`se',`p',`n',`suffix'")
  }
  end
  /* *********** END program append_est_to_file ***************************************** */


  /**********************************************************************************/
  /* program drep : report duplicates                                               */
  /**********************************************************************************/
  cap prog drop drep
  prog def drep
  {
    syntax [varlist] [if]
    duplicates report `varlist' `if'
  }
  end
  /* *********** END program drep ************************************************** */



cap pr drop store_validation_data
pr def store_validation_data
  di ""
end


/***********************************************************************************************/
/* program name_clean : standardize format of indian place names before merging                */
/***********************************************************************************************/
capture program drop name_clean
program def name_clean
  {
    syntax varname, [dropparens GENerate(name) replace]
    tokenize `varlist'
    local name = "`1'"

    if mi("`generate'") & mi("`replace'") {
      display as error "name_clean: generate or replace must be specified"
      exit 1
    }

    /* if no generate specified, make replacements to same variable */
    if mi("`generate'") {
      local name = "`1'"
    }

    /* if generate specified, copy the variable and then slowly change it */
    else {
      gen `generate' = `1'
      local name = "`generate'"
    }

    qui {
      /* lowercase, trim, trim sequential spaces */
      replace `name' = trim(itrim(lower(`name')))

      /* parentheses should be spaced as follows: "word1 (word2)" */
      /* [ regex correctly treats second parenthesis with everything else in case it is missing ] */
      replace `name' = regexs(1) + " (" + regexs(2) if regexm(`name', "(.*[a-z])\( *(.*)")

      /* drop spaces before close parenthesis */
      replace `name' = subinstr(`name', " )", ")", .)

      /* name_clean removes ALL special characters including parentheses but leaves dashes only for -[0-9]*/
      /* parentheses are removed at the very end to facilitate dropparens and numbers changes */

      /* convert punctuation to spaces */
      /* we don't use regex here because we would need to loop to get all replacements made */
      replace `name' = subinstr(`name',"*"," ",.)
      replace `name' = subinstr(`name',"#"," ",.)
      replace `name' = subinstr(`name',"@"," ",.)
      replace `name' = subinstr(`name',"$"," ",.)
      replace `name' = subinstr(`name',"&"," ",.)
      replace `name' = subinstr(`name', "-", " ", .)
      replace `name' = subinstr(`name', ".", " ", .)
      replace `name' = subinstr(`name', "_", " ", .)
      replace `name' = subinstr(`name', "'", " ", .)
      replace `name' = subinstr(`name', ",", " ", .)
      replace `name' = subinstr(`name', ":", " ", .)
      replace `name' = subinstr(`name', ";", " ", .)
      replace `name' = subinstr(`name', "*", " ", .)
      replace `name' = subinstr(`name', "|", " ", .)
      replace `name' = subinstr(`name', "?", " ", .)
      replace `name' = subinstr(`name', "/", " ", .)
      replace `name' = subinstr(`name', "\", " ", .)
      replace `name' = subinstr(`name', `"""', " ", .)
        * `"""' this line to correct emacs syntax highlighting) '

      /* replace square and curly brackets with parentheses */
      replace `name' = subinstr(`name',"{","(",.)
      replace `name' = subinstr(`name',"}",")",.)
      replace `name' = subinstr(`name',"[","(",.)
      replace `name' = subinstr(`name',"]",")",.)
      replace `name' = subinstr(`name',"<","(",.)
      replace `name' = subinstr(`name',">",")",.)

      /* trim once now and again at the end */
      replace `name' = trim(itrim(`name'))

      /* punctuation has been removed, so roman numerals must be separated by spaces */

      /* to be replaced, roman numerals must be preceded by ward, pt, part, no or " " */

      /* roman numerals to digits when they appear at the end of a string */
      /* require a space in front of the ones that could be ambiguous (e.g. town ending in 'noi') */
      replace `name' = regexr(`name', "(ward ?| pt ?| part ?| no ?| )i$", "1")
      replace `name' = regexr(`name', "(ward ?| pt ?| part ?| no ?| )ii$", "2")
      replace `name' = regexr(`name', "(ward ?| pt ?| part ?| no ?| )iii$", "3")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?|no ?| )iv$", "4")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?|no ?| )iiii$", "4")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?|no ?)v$", "5")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?|no ?| )iiiii$", "5")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?| no ?| )vi$", "6")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?|no ?| )vii$", "7")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?|no ?| )viii$", "8")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?|no ?| )ix$", "9")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?| no ?| )x$", "10")
      replace `name' = regexr(`name', "(ward ?|pt ?|part ?|no ?| )xi$", "11")

      /* replace roman numerals in parentheses */
      replace `name' = subinstr(`name', "(i)",     "1", .)
      replace `name' = subinstr(`name', "(ii)",    "2", .)
      replace `name' = subinstr(`name', "(iii)",   "3", .)
      replace `name' = subinstr(`name', "(iv)",    "4", .)
      replace `name' = subinstr(`name', "(iiii)",  "4", .)
      replace `name' = subinstr(`name', "(v)",     "5", .)
      replace `name' = subinstr(`name', "(iiiii)", "5", .)

      /* prefix any digits with a dash, unless the number is right at the start */
      replace `name' = regexr(`name', "([0-9])", "-" + regexs(1)) if regexm(`name', "([0-9])") & mi(real(substr(`name', 1, 1)))

      /* but change numbers that are part of names to be written out */
      replace `name' = subinstr(`name', "-24", "twenty four", .)

      /* don't leave a space before a dash [the only dashes left were inserted by the # steps above] */
      replace `name' = subinstr(`name', " -", "-", .)

      /* standardize trailing instances of part/pt to " part" */
      replace `name' = regexr(`name', " pt$", " part")
      replace `name' = regexr(`name', " \(pt\)$", " part")
      replace `name' = regexr(`name', " \(part\)$", " part")

      /* take important words out of parentheses */
      replace `name' = subinstr(`name', "(urban)", "urban", .)
      replace `name' = subinstr(`name', "(rural)", "rural", .)
      replace `name' = subinstr(`name', "(east)", "east", .)
      replace `name' = subinstr(`name', "(west)", "west", .)
      replace `name' = subinstr(`name', "(north)", "north", .)
      replace `name' = subinstr(`name', "(south)", "south", .)

      /* drop anything in parentheses?  do it twice in case of multiple parentheses. */
      /* NOTE: this may result in excess matches. */
      if "`dropparens'" == "dropparens" {
        replace `name' = regexr(`name', "\([^)]*\)", "")
        replace `name' = regexr(`name', "\([^)]*\)", "")
        replace `name' = regexr(`name', "\([^)]*\)", "")
        replace `name' = regexr(`name', "\([^)]*\)", "")
      }

      /* drop the word "village" and "vill" */
      replace `name' = regexr(`name', " vill(age)?", "")

      /* after making all changes that rely on parentheses, remove parenthese characters */
      /* since names with parens are already formatted word1 (word2) replace as "" */
      replace `name' = subinstr(`name',"(","",.)
      replace `name' = subinstr(`name',")"," ",.)

      /* trim again */
      replace `name' = trim(itrim(`name'))
    }
  }
end
/* *********** END program name_clean ***************************************** */


  /**********************************************************************************/
  /* program disp_nice : Insert a nice title in stata window */
  /***********************************************************************************/
  cap prog drop disp_nice
  prog def disp_nice
  {
    di _n "+--------------------------------------------------------------------------------------" _n `"| `1'"' _n  "+--------------------------------------------------------------------------------------"
  }
  end
  /* *********** END program disp_nice ***************************************** */


  /*********************************************************************************************************/
  /* program ddrop : drop any observations that are duplicated - not to be confused with "duplicates drop" */
  /*********************************************************************************************************/
  cap prog drop ddrop
  cap prog def ddrop
  {
    syntax varlist(min=1) [if]

    /* do nothing if no observations */
    if _N == 0 exit

    /* `0' contains the `if', so don't need to do anything special here */
    duplicates tag `0', gen(ddrop_dups)
    drop if ddrop_dups > 0 & !mi(ddrop_dups)
    drop ddrop_dups
  }
end
/* *********** END program ddrop ***************************************** */


  /**********************************************************************************/
  /* program tag : Fast way to run egen tag(), using first letter of var for tag    */
  /**********************************************************************************/
  cap prog drop tag
  prog def tag
  {
    syntax anything [if]

    tokenize "`anything'"

    local x = ""
    while !mi("`1'") {

      if regexm("`1'", "pc[0-9][0-9][ru]?_") {
        local x = "`x'" + substr("`1'", strpos("`1'", "_") + 1, 1)
      }
      else {
        local x = "`x'" + substr("`1'", 1, 1)
      }
      mac shift
    }

    display `"RUNNING: egen `x'tag = tag(`anything') `if'"'
    egen `x'tag = tag(`anything') `if'
  }
  end
  /* *********** END program tag ***************************************** */


  /**********************************************************************************/
  /* program capdrop : Drop a bunch of variables without errors if they don't exist */
  /**********************************************************************************/
  cap prog drop capdrop
  prog def capdrop
  {
    syntax anything
    foreach v in `anything' {
      cap drop `v'
    }
  }
  end
  /* *********** END program capdrop ***************************************** */


  /**********************************************************************************/
  /* program group : Fast way to use egen group()                  */
  /**********************************************************************************/
  cap prog drop regroup
  prog def regroup
    syntax anything [if]
    group `anything' `if', drop
  end

  cap prog drop group
  prog def group
  {
    syntax anything [if], [drop, varname(string)]

    tokenize "`anything'"

    local x = ""
    while !mi("`1'") {

      if regexm("`1'", "pc[0-9][0-9][ru]?_") {
        local x = "`x'" + substr("`1'", strpos("`1'", "_") + 1, 1)
      }
      else {
        local x = "`x'" + substr("`1'", 1, 1)
      }
      mac shift
    }

   /* define new variable name */
   if "`varname'" == "" {
     local varname `x'group
   }

    if ~mi("`drop'") cap drop `varxname'

    display `"RUNNING: egen int `varname' = group(`anything')" `if''
    egen int `varname' = group(`anything') `if'


  }
  end
  /* *********** END program group ***************************************** */



cap pr drop graphout
pr def graphout
  syntax anything, [pdf QUIetly]
  tokenize `anything'
  graph export $out/`1'.pdf, replace
end


  /**************************************/
  /* program tstop: start a Stata timer   */
  /**************************************/
  cap prog drop tstop
  prog def tstop
    syntax [anything]

    if "`anything'" == "" {
      local anything 1
    }
    di "Stopping timer `anything'."
    timer off `anything'
    qui timer list `anything'
    local t = `r(t`anything')'
    if `t' < 60 {
      di "Timer `anything': `t' seconds."
    }
    else if `t' < 3600 {
      di "Timer `anything': " %5.2f (`t'/60) " minutes."
    }
    else if `t' < 86400 {
      di "Timer `anything': " %5.2f (`t'/3600) " hours."
    }
    else {
      di "Timer `anything': " %5.2f (`t'/86400) " days."
    }
  end
  /** END program tstop *******************/


  /**************************************/
  /* program tgo: start a Stata timer   */
  /**************************************/
  cap prog drop tgo
  prog def tgo
    syntax [anything]

    if "`anything'" == "" {
      local anything 1
    }
    di c(current_time) ": Starting timer `anything'."
    timer clear `anything'
    timer on `anything'
  end
  /** END program tgo *******************/



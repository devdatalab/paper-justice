
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



cap pr drop graphout
pr def graphout
  syntax anything, [pdf QUIetly]
  tokenize `anything'
  graph export $out/`1'.pdf, replace
end


  /******************************************************************************************************/
  /* program pyfunc: Run externally defined python function without silent failures.   */
  /******************************************************************************************************/
  /* note: pyfunc exists in ~/ddl/tools/do/ado/, which is auto-loaded on polaris */
  /****** END program pyfunc ****************/



cap pr drop store_validation_data
pr def store_validation_data
  di ""
end


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



cap pr drop set_log_time
pr def set_log_time
  di ""
end



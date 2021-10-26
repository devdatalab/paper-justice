
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


/******************************************************************************************************/
/* program pyfunc: Run externally defined python function without silent failures.   */
/******************************************************************************************************/
/* note: pyfunc exists in ~/ddl/tools/do/ado/, which is auto-loaded on polaris */
/****** END program pyfunc ****************/



cap pr drop graphout
pr def graphout
  syntax anything, [pdf QUIetly]
  tokenize `anything'
  graph export $out/`1'.pdf, replace
end


/**************************************************************************************************/
/* program rd : produce a nice RD graph, using polynomial (quartic default) for fits         */
/**************************************************************************************************/
global rd_start -250
global rd_end 250
cap prog drop rd
prog def rd
  {
    syntax varlist(min=2 max=2) [aweight pweight] [if], [degree(real 4) name(string) Bins(real 100) Start(real -9999) End(real -9999) start_line(real -9999) end_line(real -9999) MSize(string) YLabel(string) NODRAW bw xtitle(passthru) title(passthru) ytitle(passthru) xlabel(passthru) xline(passthru) absorb(string) control(string) xq(varname) cluster(passthru) xsc(passthru) yscale(passthru) fysize(passthru) fxsize(passthru) note(passthru) nofit]
    
    tokenize `varlist'
    local xvar `2'
    
    preserve

    /* Create convenient weight local */
    if ("`weight'"!="") local wt [`weight'`exp']

    /* get the weight variable itself by removing other elements of the expression */
    local wtvar "`wt'"
    foreach i in "=" "aweight" "pweight" "]" "[" " " {
      local wtvar = subinstr("`wtvar'", "`i'", "", .)
    }

    /* set start/end to global defaults (from include) if unspecified */
    if `start' == -9999 & `end' == -9999 {
      local start $rd_start
      local end   $rd_end
    }

    /* set the start and endline points to be the same as the scatter plot if not specified */
    //if `start_line' == -9999 {
      //  local start_line = `start'
      //}
    //if `end_line' == -9999 {
      //  local end_line = `end'
      //}

    if "`msize'" == "" {
      local msize small
    }
    
    if "`ylabel'" == "" {
      local ylabel ""
    }
    else {
      local ylabel "ylabel(`ylabel') "
    }
    
    if "`name'" == "" {
      local name `1'_rd
    }
    
    /* set colors */
    if mi("`bw'") {
      local color_b "red"
      local color_se "blue"
    }
    else {
      local color_b "black"
      local color_se "gs8"
    }
    
    if "`se'" == "nose" {
      local color_se "white"
    }
    
    capdrop pos_rank neg_rank xvar_index xvar_group_mean rd_bin_mean rd_tag mm2 mm3 mm4 l_hat r_hat l_se l_up l_down r_se r_up r_down total_weight rd_resid tot_mean
    qui {

      /* restrict sample to specified range */
      if !mi("`if'") {
        keep `if'
      }
      keep if inrange(`xvar', `start', `end')
      
      /* get residuals of yvar on absorbed variables */
      if !mi("`absorb'")  | !mi("`control'") {
        if !mi("`absorb'") {
          reghdfe `1' `control' `wt' `if', absorb(`absorb') resid
        }
        else {
          reg `1' `control' `wt' `if'
        }
        predict rd_resid, resid
        local 1 rd_resid
      }
      
      /* GOAL: cut into `bins' equally sized groups, with no groups crossing zero, to create the data points in the graph */
      if mi("`xq'") {
        
        /* count the number of observations with margin and dependent var, to know how to cut into 100 */
        count if !mi(`xvar') & !mi(`1') 
        local group_size = floor(`r(N)' / `bins')
        
        /* create ranked list of margins on + and - side of zero */
        egen pos_rank = rank(`xvar') if `xvar' > 0 & !mi(`xvar'), unique
        egen neg_rank = rank(-`xvar') if `xvar' < 0 & !mi(`xvar'), unique
        
        /* hack: multiply bins by two so this works */
        local bins = `bins' * 2
        
        /* index `bins' margin groups of size `group_size' */
        /* note this conservatively creates too many groups since 0 may not lie in the middle of the distribution */
        gen xvar_index = .
        forval i = 0/`bins' {
          local cut_start = `i' * `group_size'
          local cut_end = (`i' + 1) * `group_size'
          
          replace xvar_index = (`i' + 1) if inrange(pos_rank, `cut_start', `cut_end')
          replace xvar_index = -(`i' + 1) if inrange(neg_rank, `cut_start', `cut_end')
        }
      }
      /* on the other hand, if xq was specified, just use xq for bins */
      else {
        gen xvar_index = `xq'
      }
      
      /* generate mean value in each margin group */
      bys xvar_index: egen xvar_group_mean = mean(`xvar') if !mi(xvar_index)
      
      /* generate value of depvar in each X variable group */
      if mi("`weight'") {
        bys xvar_index: egen rd_bin_mean = mean(`1')
      }

      if "`weight'" != "" {
        bys xvar_index: egen total_weight = total(`wtvar')
        bys xvar_index: egen rd_bin_mean = total(`wtvar' * `1')
        replace rd_bin_mean = (rd_bin_mean / total_weight)
      }

      /* generate a tag to plot one observation per bin */
      egen rd_tag = tag(xvar_index)
      
      /* run polynomial regression for each side of plot */
      gen mm2 = `xvar' ^ 2
      gen mm3 = `xvar' ^ 3
      gen mm4 = `xvar' ^ 4
      
      /* set covariates according to degree specified */
      if "`degree'" == "4" {
        local mpoly mm2 mm3 mm4
      }
      if "`degree'" == "3" {
        local mpoly mm2 mm3
      }
      if "`degree'" == "2" {
        local mpoly mm2
      }
      if "`degree'" == "1" {
        local mpoly
      }

      reg `1' `xvar' `mpoly' `wt' if `xvar' < 0, `cluster'
      predict l_hat
      predict l_se, stdp
      gen l_up = l_hat + 1.65 * l_se
      gen l_down = l_hat - 1.65 * l_se
      
      reg `1' `xvar' `mpoly' `wt' if `xvar' > 0, `cluster'
      predict r_hat
      predict r_se, stdp
      gen r_up = r_hat + 1.65 * r_se
      gen r_down = r_hat - 1.65 * r_se
    }
    
    if "`fit'" == "nofit" {
      local color_b white
      local color_se white
    }
    
    /* fit polynomial to the full data, but draw the points at the mean of each bin */
    sort `xvar'
    
    twoway ///
        (line r_hat  `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_b') msize(vtiny)) ///
        (line l_hat  `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_b') msize(vtiny)) ///
        (line l_up   `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_se') msize(vtiny)) ///
        (line l_down `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_se') msize(vtiny)) ///
        (line r_up   `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_se') msize(vtiny)) ///
        (line r_down `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_se') msize(vtiny)) ///
        (scatter rd_bin_mean xvar_group_mean if rd_tag == 1 & inrange(`xvar', `start', `end'), xline(0, lcolor(black)) msize(`msize') color(black)),  `ylabel'  name(`name', replace) legend(off) `title' `xline' `xlabel' `ytitle' `xtitle' `nodraw' `xsc' `yscale' `fysize' `fxsize' `note' graphregion(color(white))
    restore
  }
end
/* *********** END program rd ***************************************** */

/*******************************************/
/* program store_paper_stat: description   */
/*******************************************/
cap prog drop store_paper_stat
prog def store_paper_stat

  di ""
end
/** END program store_paper_stat ***********/

/***************************************/
/* program set_log_time: description   */
/***************************************/
cap prog drop set_log_time
prog def set_log_time
  di ""
end
/** END program set_log_time ***********/


/************************************************************************/
/* program collapse_apply_labels: Apply saved var labels after collapse */
/************************************************************************/

/* apply retained variable labels after collapse */
cap prog drop collapse_apply_labels
prog def collapse_apply_labels
  {
    foreach v of var * {
      label var `v' "${l`v'__}"
      macro drop l`v'__
    }
  }
end
/* **** END program collapse_apply_labels ***************************** */


/**********************************************************************************/
/* program append_est_to_file : Appends a regression estimate to a csv file       */
/**********************************************************************************/
cap prog drop append_est_to_file
prog def append_est_to_file
  {
    syntax using/, b(string) Suffix(string)
    
    /* get number of observations */
    qui count if e(sample)
    local n = r(N)
    
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


/*********************************************************************************/
/* program winsorize: replace variables outside of a range(min,max) with min,max */
/*********************************************************************************/
cap prog drop winsorize
prog def winsorize
  {
    syntax anything,  [REPLace GENerate(name) centile]
    
    tokenize "`anything'"
    
    /* require generate or replace [sum of existence must equal 1] */
    if (!mi("`generate'") + !mi("`replace'") != 1) {
      display as error "winsorize: generate or replace must be specified, not both"
      exit 1
    }
    
    if ("`1'" == "" | "`2'" == "" | "`3'" == "" | "`4'" != "") {
      di "syntax: winsorize varname [minvalue] [maxvalue], [replace generate] [centile]"
      exit
    }
    if !mi("`replace'") {
      local generate = "`1'"
    }
    tempvar x
    gen `x' = `1'
    
    
    /* reset bounds to centiles if requested */
    if !mi("`centile'") {
      
      centile `x', c(`2')
      local 2 `r(c_1)'
      
      centile `x', c(`3')
      local 3 `r(c_1)'
    }
    
    di "replace `generate' = `2' if `1' < `2'  "
    replace `x' = `2' if `x' < `2'
    di "replace `generate' = `3' if `1' > `3' & !mi(`1')"
    replace `x' = `3' if `x' > `3' & !mi(`x')
    
    if !mi("`replace'") {
      replace `1' = `x'
    }
    else {
      generate `generate' = `x'
    }
  }
end
/* *********** END program winsorize ***************************************** */


/*************************************************************************************************/
/* program encode_string_to_key : Encode variables to numeric with string table in separate file */
/*************************************************************************************************/

/* This program takes a list of variables and encodes them numerically.
For each variable, a new .dta string table file is created with links to the original strings.

For a variable `myvar`, the string table will have:
mystring    int
myvar       strXX
count       int

The parameter keypath() specifies the root folder for the key, which will be
called keys/myvar_key.dta

SYNTAX: encode_string_to_key_secc varlist, keypath($iec/pc11/keys)
*/
cap prog drop encode_string_to_key
prog def encode_string_to_key
  syntax varlist, KEYPATH(string)

  /* loop over list of variables to encode */
  foreach var in `varlist' {

    /* show progress */
    di "encode_string_to_key(): Encoding variable `var'"

    /* remove leading and trailing spaces */
    qui replace `var' = trim(`var')

    /* preserve and limit to the data we will use-- just the varname */
    preserve
    keep `var'
    
    /* collapse to one row per value */
    gen count = 1
    gcollapse (sum) count, by(`var')
    
    /* sort and generate unique ids for unique values */
    sort `var'
    egen id = group(`var')

    /* remove trailing slash from key path if included */
    if regexm("`keypath'", "/$") {
      local keypath = regexr("`keypath'", "/$", "")
    }

    /* add /keys to the end of top path if path does not end in /keys folder */
    if !regexm("`keypath'", "/keys$") {
      local keypath "`keypath'/keys"
    }

    /* create /keys directory if doesn't exist */
    cap mkdir `keypath'

    /* rename so varname is the numeric id, and varname_s is the string */
    ren `var' `var'_s
    ren id `var'

    /* save the string table */
    di "Create string table `keypath'/`var'_key.dta with values of `keypath'"
    qui compress
    qui save `keypath'/`var'_key, replace

    /* restore the original dataset */
    restore
    
    /* replace original strings with encoding */
    ren `var' `var'_s
    qui merge m:1 `var'_s using `keypath'/`var'_key, keepusing(`var') nogen assert(match)
    drop `var'_s
  }
end

/* *********** END program encode_string_to_key *****************************************/


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
    syntax anything [if], [drop]
    
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
    
    if ~mi("`drop'") cap drop `x'group
    
    display `"RUNNING: egen int `x'group = group(`anything')" `if''
    egen int `x'group = group(`anything') `if'
  }
end
/* *********** END program group ***************************************** */


/*****************************************************************/
/* program collapse_save_labels: Save var labels before collapse */
/*****************************************************************/

/* save var labels before collapse, saving varname if no label */
cap prog drop collapse_save_labels
prog def collapse_save_labels
  {
    foreach v of var * {
      local l`v' : variable label `v'
      global l`v'__ `"`l`v''"'
      if `"`l`v''"' == "" {
        global l`v'__ "`v'"
      }
    }
  }
end
/* **** END program collapse_save_labels *********************** */


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



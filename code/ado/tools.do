qui {

  /* DDL STATA TOOLS */

  /* load masala-merge */
  do ~/ddl/masala-merge/masala_merge.do

  /* load stata-tex */
  do ~/ddl/stata-tex/stata-tex.do

  /* load matlab calling functions */
  do ~/ddl/tools/do/stata_matlab.do

  /* load some additional programs of use */
  do ~/ddl/tools/do/shrink_data
  do ~/ddl/tools/do/collapse_niccs.do
  do ~/ddl/tools/do/prep_for_distance_matrix.do
  do ~/ddl/tools/do/prog_replace_bad_coords.do

  /* include dataset building programs */
  do ~/ddl/tools/do/build_programs.do

  /* load validation tools */
  do ~/ddl/tools/do/data_validation_tools.do
  
  /* load clean graph scheme */
  // capture !rm -f ~/ado/personal/simplescheme.scheme

  // set scheme simplescheme
  capture copy ~/ddl/config/schemes/plotplain.scheme ~/ado/personal/, replace
  capture copy ~/ddl/config/schemes/plottig.scheme ~/ado/personal/, replace
  capture copy ~/ddl/config/schemes/simplescheme.scheme ~/ado/personal/, replace
  capture copy ~/ddl/config/schemes/pn.scheme ~/ado/personal/, replace
  capture copy ~/ddl/config/schemes/w538.scheme ~/ado/personal/, replace
  capture copy ~/ddl/config/schemes/bw538.scheme ~/ado/personal/, replace
  capture copy ~/ddl/config/schemes/g538.scheme ~/ado/personal/, replace
  cap set scheme simplescheme

  /* **** PROGRAM START **** <---- Don't change this line, the tools parser needs it! */
  

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


/**************************************************************************************************/
/* program rd_full_narrow : produces RD graph, with linear fit within bandwidth                   */
/**************************************************************************************************/
cap prog drop rd_full_narrow
prog def rd_full_narrow
  {
    syntax varlist(min=1 max=1) [if], [BANDwidth(real 0.051) name(string) Bins(real 100) Start(real -.50) End(real .50) MSize(string) YLabel(string) NODRAW bw xtitle(passthru) title(passthru) ytitle(passthru) xlabel(passthru) xline(passthru) xline(passthru) ]
    preserve
    if "`msize'" == "" {
      local msize tiny
    }

    if "`ylabel'" == "" {
      local ylabel ""
    }
    else {
      local ylabel "ylabel(`ylabel') "
    }

    if "`name'" == "" {
      local name `varlist'_rd
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

    foreach i in pos_rank neg_rank margin_index margin_group_mean rd_bin_mean rd_tag mm2 mm3 mm4 l_hat r_hat l_se l_up l_down r_se r_up r_down {
      cap drop `i'
    }

    /* restrict sample to specified range */
    if !mi("`if'") {
      drop `if'
    }
    keep if inrange(margin, `start', `end')

    /* GOAL: cut into `bins' equally sized groups, with no groups crossing zero, to create the data points in the graph */
    /* count the number of observations with margin and dependent var, to know how to cut into 100 */
    count if !mi(margin) & !mi(`varlist')
    local group_size = floor(`r(N)' / `bins')

    /* create ranked list of margins on + and - side of zero */
    egen pos_rank = rank(margin) if margin > 0 & !mi(margin), unique
    egen neg_rank = rank(-margin) if margin < 0 & !mi(margin), unique

    /* hack: multiply bins by two so this works */
    local bins = `bins' * 2

    /* index `bins' margin groups of size `group_size' */
    /* note this conservatively creates too many groups since 0 may not lie in the middle of the distribution */
    gen margin_index = .
    forval i = 0/`bins' {
      local cut_start = `i' * `group_size'
      local cut_end = (`i' + 1) * `group_size'

      replace margin_index = (`i' + 1) if inrange(pos_rank, `cut_start', `cut_end')
      replace margin_index = -(`i' + 1) if inrange(neg_rank, `cut_start', `cut_end')
    }

    /* generate mean value in each margin group */
    bys margin_index: egen margin_group_mean = mean(margin) if !mi(margin_index)

    /* generate value of depvar in each margin group */
    bys margin_index: egen rd_bin_mean = mean(`varlist')


    /* generate a tag to plot one observation per bin */
    egen rd_tag = tag(margin_index)

    /* calculate linear fits within bandwidth range */
    reg `varlist' margin if margin < 0 & abs(margin) < `bandwidth'
    predict l_hat if abs(margin) < `bandwidth'
    predict l_se if abs(margin) < `bandwidth', stdp
    gen l_up = l_hat + 1.65 * l_se
    gen l_down = l_hat - 1.65 * l_se

    reg `varlist' margin if margin > 0 & abs(margin) < `bandwidth'
    predict r_hat if abs(margin) < `bandwidth'
    predict r_se if abs(margin) < `bandwidth', stdp
    gen r_up = r_hat + 1.65 * r_se
    gen r_down = r_hat - 1.65 * r_se

    sort margin

    /* fit polynomial to the full data, but draw the points at the mean of each bin */
    sort margin
    twoway (line r_hat margin if inrange(margin, 0, .5) & !mi(`varlist'), color(`color_b') msize(vtiny)) ///
        (line l_hat margin if inrange(margin, -.5, 0) & !mi(`varlist'), color(`color_b') msize(vtiny)) ///
        (line l_up margin if inrange(margin, -.5, 0) & !mi(`varlist'), color(`color_se') msize(vtiny)) ///
        (line l_down margin if inrange(margin, -.5, 0) & !mi(`varlist'), color(`color_se') msize(vtiny)) ///
        (line r_up margin if inrange(margin, 0, .5) & !mi(`varlist'), color(`color_se') msize(vtiny)) ///
        (line r_down margin if inrange(margin, 0, .5) & !mi(`varlist'), color(`color_se') msize(vtiny)) ///
        (scatter rd_bin_mean margin_group_mean if rd_tag == 1 & inrange(margin, -.5, .5), xline(-`bandwidth' 0 `bandwidth', lcolor(`color_b')) msize(`msize') color(black)),  `ylabel'  name(`name', replace) legend(off) `title' `xline' `xlabel' `ytitle' `xtitle' `nodraw' graphregion(color(white))

    restore
  }
end
/* *********** END program rd_full_narrow ***************************************** */


/********************************************************************************/
/* program town_name_clean : extension of name_clean with town-specific changes */
/********************************************************************************/
/* clean town names using standard name_clean program + town-specific changes   */
/*   dropabbrev - always specify unless specific reason to keep civic status    */
/*   droppart - specify after inspecting 'part' 'minor/major part' instances    */
/*   dropstatus - specify for base town name, compatability to outside sources, */
/*                not for merging purposes                                      */
/*   dropcantt - drops ' cantonment$', separated from dropstatus for importance */
/*   dropparens - drops everything enclosed in parentheses                      */
/*                                                                              */
/* standard usage: town_name_clean pc01_town_name, droppart dropabbrev replace  */
cap prog drop town_name_clean
prog def town_name_clean
  {
    syntax varname, [dropparens droppart dropabbrev dropstatus dropcantt GENerate(name) replace]
    tokenize `varlist'
    local name = "`1'"

    /* if no generate specified, make replacements to same variable */
    if mi("`generate'") {
      local name = "`1'"
    }

    /* if generate specified, copy the variable and then slowly change it */
    else {
      gen `generate' = `1'
      local name = "`generate'"
    }

    /* call main name clean program */
    name_clean `name', replace `dropparens'

    /* standardize all town status abbreviations/occurences */

    /* standardize and write out all usages of Cantonment */
    replace `name' = regexr(`name', " cantonmen$", " cantonment")
    replace `name' = regexr(`name', " cantontment", " cantonment")
    replace `name' = regexr(`name', "cantt$", " cantonment")
    replace `name' = regexr(`name', " cant$", " cantonment")
    replace `name' = regexr(`name', " cantt ", " cantonment ")
    replace `name' = regexr(`name', " cantonment board", " cantonment")
    replace `name' = regexr(`name', " cb$", " cantonment") if !regexm(`name', "cantonment")
    replace `name' = regexr(`name', " c b$", " cantonment") if !regexm(`name', "cantonment")
    replace `name' = regexr(`name', " cb$", "") if regexm(`name', "cantonment")
    replace `name' = regexr(`name', " c b$", "") if regexm(`name', "cantonment")
    /* standardize mid-word cantonment usages for town names with trailing " part$" */
    replace `name' = regexr(`name', " cb", " cantonment") if !regexm(`name', "cantonment") & regexm(`name', "part")
    replace `name' = regexr(`name', " c b", " cantonment") if !regexm(`name', "cantonment") & regexm(`name', "part")
    replace `name' = regexr(`name', " cb", "") if regexm(`name', "cantonment") & regexm(`name', "part")
    replace `name' = regexr(`name', " c b", "") if regexm(`name', "cantonment") & regexm(`name', "part")

    /* write out important names */
    replace `name' = subinstr(`name', "metro", "metropolitan", .) if !regexm(`name', "metropolitan")
    replace `name' = subinstr(`name', " settlemen", " settlement", .) if !regexm(`name', "settlement")
    replace `name' = subinstr(`name', " settlem", " settlement", .) if !regexm(`name', "settlement")
    replace `name' = subinstr(`name', " settl", " settlement", .) if !regexm(`name', "settlement")
    replace `name' = regexr(`name', " ng$", " nagar")
    replace `name' = regexr(`name', "rly ", "railway ") if regexm(`name', "(\+| )+(rly )") | regexm(`name', "^rly ")

    /* write out important abbreviations */
    replace `name' = regexr(`name', "^n ", "north ") if regexm(`name', "^n [a-z][a-z]") & !regexm(`name', "n d") & !regexm(`name', "ndmc")
    replace `name' = regexr(`name', "b h e l ", "bharat heavy electricals")
    replace `name' = regexr(`name', "ltd ", "limited ")
    replace `name' = regexr(`name', " r f c$", " right flank colony")
    replace `name' = regexr(`name', " clny$", " colony")
    replace `name' = regexr(`name', " cly$", " colony")

    /* concat mid-name abbrevations */
    replace `name' = regexr(`name', " h q ", " hq ")
    replace `name' = regexr(`name', " m c ", " mc ")
    replace `name' = regexr(`name', " i o c ", " ioc ")
    replace `name' = regexr(`name', " d f ", " df ")
    replace `name' = regexr(`name', " t p ", " tp ")

    /* concat trailing abbreviations */
    replace `name' = regexr(`name', " i n a$", " ina")
    replace `name' = regexr(`name', " u a$", " ua")
    replace `name' = regexr(`name', " o g$", " og")

    /* remove trailing instances of "urban", differentiated from "suburban$" with a space */
    replace `name' = regexr(`name', " urban$", "")

    /* drop trailing circle, block, etc. */
    replace `name' = regexr(`name', " subdivision$", "")
    replace `name' = regexr(`name', " division$", "")
    replace `name' = regexr(`name', " div$", "")
    replace `name' = regexr(`name', " sub$", "")
    replace `name' = regexr(`name', " new$", "")

    /* standardize important prefixes: sas nagar (sas nagar mohali) */
    replace `name' = regexr(`name', "s a s nagar", "sas nagar")

    /* standardize important abbreviations: m, ina, ct */
    replace `name' = regexr(`name', " ina ina$", " ina")
    replace `name' = regexr(`name', " c t$", " ct")
    replace `name' = regexr(`name', " census town$", " ct")

    /* drop non-essential trailing abbreviations found in district/subdistrict and town names */
    replace `name' = regexr(`name', " s t$", "")
    replace `name' = regexr(`name', " st$", "")
    replace `name' = regexr(`name', " tc$", "")
    replace `name' = regexr(`name', " p s$", "")
    replace `name' = regexr(`name', " tp$", "")
    replace `name' = regexr(`name', " p$", "")
    replace `name' = regexr(`name', " t$", "")

    /* drop non-essential town-specific number/status abbreviations ex. "hq bl i-7" or "m corp part eb no-23" */
    replace `name' = regexr(`name', "( hq)(.*[a-z])(\-[0-9])", "")
    replace `name' = regexr(`name', "( m corp)(.*[a-z])(\-[0-9])", "")
    replace `name' = regexr(`name', "( m )(.*[a-z])(\-[0-9])(.*[0-9]$)", "")
    replace `name' = regexr(`name', "( ward)(.*)(\-([0-9]+)$)", "")
    replace `name' = regexr(`name', "( eb no)(.*)(\-([0-9]+)$)", "")
    replace `name' = regexr(`name', "( no)( |\-)+(i|1)+", "")

    /* standardize/replace unrecognized characters: "á"/ char\341 */
    qui charlist `name'
    replace `name' = subinstr(`name', "`=char(225)'", "a", .)
    replace `name' = subinstr(`name', "á", "a", .)

    /* drop dash off beginning of town name that starts with number */
    replace `name' = regexr(`name', "^\-", "")

    /* add option to drop trailing part instances before dropping town abbreviations */
    /* NOTE: only use this option after parts have been reviewed */
    if "`droppart'" == "droppart" {
      replace `name' = regexr(`name', " minor part$", "")
      replace `name' = regexr(`name', " major part$", "")
      replace `name' = regexr(`name', " part$", "")
    }

    /* drop civic status abbreviations specific only to town names, mostly non-essential */
    /* NOTE: this may result in excess matches or non-unique town names */
    if "`dropabbrev'" == "dropabbrev" {
      replace `name' = regexr(`name', " \+ og$", "")
      replace `name' = regexr(`name', "\+og$", "")
      replace `name' = regexr(`name', " og$", "")
      replace `name' = regexr(`name', " h q$", "")
      replace `name' = regexr(`name', " hq$", "")
      replace `name' = regexr(`name', " amc$", "")
      replace `name' = regexr(`name', " iw$", "")
      replace `name' = regexr(`name', " gp$", "")
      replace `name' = regexr(`name', " na$", "")
      replace `name' = regexr(`name', " nt$", "")
      replace `name' = regexr(`name', " np$", "")
      replace `name' = regexr(`name', " npp$", "")
      replace `name' = regexr(`name', " n$", "")
      replace `name' = regexr(`name', " nm$", "")
      replace `name' = regexr(`name', " ci$", "")
      replace `name' = regexr(`name', " cmc$", "")
      replace `name' = regexr(`name', " tmc$", "")
      replace `name' = regexr(`name', " tc$", "")
      replace `name' = regexr(`name', " m cl$", "")
      replace `name' = regexr(`name', " m corp$", "")
      replace `name' = regexr(`name', " mci$", "")
      replace `name' = regexr(`name', " mcl$", "")
      replace `name' = regexr(`name', " mc$", "") if !regexm(`name', "n d mc")
      replace `name' = regexr(`name', " m c$", "") if !regexm(`name', "n d m c")
      replace `name' = regexr(`name', " mb$", "")
      replace `name' = regexr(`name', " m$", "")
      replace `name' = regexr(`name', " its$", "")
      replace `name' = regexr(`name', " ts$", "")
      replace `name' = regexr(`name', " rs$", "")
      replace `name' = regexr(`name', " s$", "")
      replace `name' = regexr(`name', " nac$", "")
      replace `name' = regexr(`name', " vp$", "")
      replace `name' = regexr(`name', " v$", "")
    }

    /* drop all remaining instances of town civic status left after dropabbrev */
    /* drop abbreviations verified as non-essential for matching to outside sources (Google, WB, etc.) */
    /* but drop separately from dropabbrev, because these status abbreviations may be important for matching */
    /*   (Notes: dropped abbreviations have been inspected via Google Maps to ensure refer to the same town) */
    /*   (inspected: oil town -> oil OK, hindusthan cables OK, bokaro steel OK, remove township nta ina, etc. good) */
    /*   (need: " ioc$" (only remaining status abbrev)) */
    /*   (cantonment: " cantonment$" increases coordinate accuracy, recognized by outside sources, do not drop) */
    if "`dropstatus'" == "dropstatus" {
      di "Warning: Dropping all civic status abbreviations! (except 'cantonment$')"
      di "Dropping city, town, nta, spl, ct, right flank colony"
      di "Keeping township, ina, cantonment"
      di "These trailing abbreviations may be important for matching. Use only for outside sources."
      replace `name' = regexr(`name', " ct$", "")
      replace `name' = regexr(`name', " city$", "")
      replace `name' = regexr(`name', " limited township$", "")
      replace `name' = regexr(`name', " right flank colony township$", "")
      replace `name' = regexr(`name', " spl$", "")
      replace `name' = regexr(`name', " town$", "")
      replace `name' = regexr(`name', " nta$", "")
    }
    /* drop 'cantonment' status from end of town name separately from dropstatus due to importance of cantonment */
    /* if specified with dropabbrev + dropstatus, this removes all civic status, only remaining: ' ioc' */
    if "`dropcantt'" == "dropcantt" {
      di "Warning: Dropping ' cantonment' from town names!"
      di "Cantonment is usually important to identifying towns, not recommended."
      replace `name' = regexr(`name', " cantonment$", "")
    }

    /* write out and standardize important large town names after dropping abbreviations */
    /* standardize large towns by spelling out abbreviations */
    replace `name' = "new delhi municipal council" if `name' == "n d mc" | `name' == "n d m c" | `name' == "ndmc"
    replace `name' = "new delhi municipal council part" if ((regexm(`name', "n d m c") | regexm(`name', "ndmc")) & regexm(`name', " part$"))
    replace `name' = "delhi municipal corporation" if `name' == "dmc" | `name' == "dmc u" | `name' == "d m c"
    replace `name' = "delhi municipal corporation part" if (regexm(`name', "dmc") & regexm(`name', " part$"))
    replace `name' = "greater hyderabad municipal corporation" if `name' == "ghmc"
    replace `name' = "greater hyderabad municipal corporation part" if `name' == "ghmc part"
    replace `name' = "greater visakhapatnam municipal corporation" if `name' == "gvmc"
    replace `name' = "greater visakhapatnam municipal corporation part" if `name' == "gvmc part"
    replace `name' = "bruhat bengaluru mahanagara palike" if `name' == "bbmp"
    replace `name' = "bruhat bengaluru mahanagara palike part" if `name' == "bbmp part"

    /* trim */
    replace `name' = trim(itrim(`name'))
  }
end

/** END program town_name_clean ************************************************************/

/*******************************************************************************************/
/* program village_name_clean : extension of name_clean with some village-specific stuff  */
/*******************************************************************************************/
cap prog drop village_name_clean
prog def village_name_clean
  {
    syntax varname, [dropparens GENerate(name) replace]
    tokenize `varlist'
    local name = "`1'"

    /* if no generate specified, make replacements to same variable */
    if mi("`generate'") {
      local name = "`1'"
    }

    /* if generate specified, copy the variable and then slowly change it */
    else {
      gen `generate' = `1'
      local name = "`generate'"
    }

    /* call main name clean program */
    name_clean `name', replace `dropparens'

    /* run village-specific changes */
    /* drop trailing "p s " */
    replace `name' = regexr(`name', " p s$", "")

    /* drop trailing circle, taluk, etc. */
    replace `name' = regexr(`name', "circle$", "")
    replace `name' = regexr(`name', "taluk$", "")
    replace `name' = regexr(`name', " sub div$", "")
    replace `name' = regexr(`name', " sub division$", "")
    replace `name' = regexr(`name', "subdivision$", "")
    replace `name' = regexr(`name', "division$", "")
    replace `name' = regexr(`name', "nagar$", "") if strlen(`name') > 5

    /* trim  */
    replace `name' = trim(`name')
  }
end
/** END program village_name_clean ************************************************************/

/*******************************************************************************************/
/* program con_name_clean : extnesion of name_clean with some constituency-specific stuff  */
/*******************************************************************************************/
capture program drop con_name_clean
program def con_name_clean
  {
    /* note no dropparens passthru since con names must have parentheses */
    syntax varname, [GENerate(name) replace]
    tokenize `varlist'
    local name = "`1'"

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
      name_clean `name', replace
      
      /* correct common errors */
      replace `name' = regexr(`name', "\(st$", "(st)")
      replace `name' = regexr(`name', "\(sc$", "(sc)")
      replace `name' = regexr(`name', "\($", "")
      
      /* clean roman numerals when parenthesis follows the number (e.g. (sc) ) */
      replace `name' = regexr(`name', " +\(?i\)? \(",   "-1 (")
      replace `name' = regexr(`name', " +\(?ii\)? \(",  "-2 (")
      replace `name' = regexr(`name', " +\(?iii\)? \(", "-3 (")
      replace `name' = regexr(`name', " +\(?iv\)? \(",  "-4 (")
      replace `name' = regexr(`name', " +\(?v\)? \(",   "-5 (")
      
      /* cut trailing SC/ST/BL */
      // replace ac_name = regexs(1) if regexm(ac_name, "^(.*) st$")
      // replace ac_name = regexs(1) if regexm(ac_name, "^(.*) sc$")
      // replace ac_name = regexs(1) if regexm(ac_name, "^(.*) bl$")
      /* concerns: creates some duplicates: kalyanpur, mahuva, shahpura, bishnupur */
      
      /* trim  */
      replace `name' = trim(`name')
    }
  }
end
/** END program con_name_clean ************************************************************/



/**********************************************************************************/
/* program clean_roman_numerals : convert roman numerals into a standard format */
/***********************************************************************************/
cap prog drop clean_roman_numerals
prog def clean_roman_numerals

    syntax varname, [group(varlist) REPLace GENerate(name)]

    /* require generate or replace [sum of existence must equal 1] */
    if (!mi("`generate'") + !mi("`replace'") != 1) {
      display as error "clean_roman_numerals: generate or replace must be specified, not both"
      exit 1
    }

    tempvar g

    /* create a single group for full sample if group not specified */
    if mi("`group'") {
      gen `g' = 1
    }
    /* otherwise create single group variable */
    else {
      egen `g' = group(`group')
    }
    local group `g'

    /* sort by group and varlist */
    sort `group' `varlist'

    /* tag to avoid sending duplicates */
    tempvar tag
    egen `tag' = tag(`group' `varlist')

    /* outsheet group and strings for python */
    tempfile py_in
    tempfile py_out
    outsheet `group' `varlist' using `py_in' if `tag', comma replace nonames
    outsheet `group' `varlist' using $tmp/foo.csv if `tag', comma replace nonames

    /* call roman numeral fixing function in python */
    shell python ~/ddl/tools/py/scripts/fix_roman_numerals.py -i `py_in' -o `py_out'

    /* prep results for merging */
    preserve
    cap insheet using `py_out', clear nonames
    if _rc {

      display "No roman numerals to replace"
      if !mi("`generate'") {
        gen `generate' = `varlist'
      }
      exit
    }
    ren v1 `group'
    ren v2 `varlist'

    tempvar stub roman_numeral
    ren v3 `stub'
    ren v4 `roman_numeral'

    tempfile romans
    save `romans', replace
    restore

    /* merge results */
    merge m:1 `group' `varlist' using `romans'
    assert _merge != 2
    drop _merge

    tempvar result
    gen `result' = `varlist'
    replace `result' = `stub' + "-" + string(`roman_numeral') if !mi(`stub') & !mi(`roman_numeral')

    /* move result to generate or replace */
    if mi("`generate'") {
      replace `1' = `result'
    }
    else {
      gen `generate' = `result'
    }

    drop `stub' `roman_numeral' `result' `g'

end
/* *********** END program clean_roman_numerals ***************************************** */


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
/* program dtag : shortcut duplicates tag */
/***********************************************************************************/
cap prog drop dtag
prog def dtag
  {
    syntax varlist [if]
    duplicates tag `varlist' `if', gen(dup)
    sort `varlist'
    tab dup
  }
end
/* *********** END program dtag ***************************************** */


/************************************************************************************************/
/* Keniston's aminmerge functions are deprecated. Leave wrappers in case someone runs old code. */
cap prog drop fast_aminmerge
prog def fast_aminmerge
  {
    disp_nice "PLEASE DON'T USE THIS FUNCTION. USE masala_merge INSTEAD!"
    barf
  }
end
cap prog drop fast_aminmerge2
prog def fast_aminmerge2
  {
    disp_nice "PLEASE DON'T USE THIS FUNCTION. USE masala_merge INSTEAD!"
    barf
  }
end
/************************************************************************************************/

cap prog drop gen_groups
program gen_groups
  {
    syntax varlist(min = 2), Generate(name)
    /* syntax:
    gen_groups a b c [etc], gen(final_group)
    */

    /* split variables into local macros */
    tokenize `varlist'

    /* generate group list, and store number of groups in `num_groups' */
    local num_groups = 0
    while "`1'" != "" {
      local num_groups = `num_groups' + 1
      local G`num_groups' = "`1'"
      mac shift
    }

    /* initialize new group variable to have n distinct groups */
    gen `generate' = _n
    tempvar tmp
    tempvar count

    /* create a variable to track the number of changes made in last round */
    local maxc = 1

    /* loop until a round goes by with nothing changing */
    while `maxc' > 0 {
      local maxc = 0

      /* loop over each group variable */
      forval j = 1/`num_groups' {
        di "i = `num_groups', j = `j'"

        /* group the outcome variable according to groups defined by the current group index */
        bys `G`j'': egen `tmp' = max(`generate') if !mi(`G`j'')

        /* count the number of changes that were made */
        gen `count' = `generate' - `tmp' if !mi(`tmp')
        count if `count' != 0 & !mi(`count')
        di "`r(N)' changes made."
        local maxc = max(`maxc', r(N))

        /* write data to outcome group variable */
        replace `generate' = `tmp' if !mi(`tmp')

        /* drop temporary files */
        drop `tmp' `count'
      }
    }

    /* re-order outcome variable so groups are sequential and start with 1 */
    egen `tmp' = group(`generate')
    replace `generate' = `tmp'
    drop `tmp'
  }
end



/* pn_heatmap

USAGE: pn_heatmap latitude longitude, heat(varname) [name(name) msize(name)]

*/
cap prog drop pn_heatmap
prog def pn_heatmap
  {
    syntax varlist(min=2 max=2) [using/] [if], Heat(name) [Name(name) MSize(name) cmd xlabel(passthru) ylabel(passthru) xscale(passthru) xtitle(passthru) ytitle(passthru) yscale(passthru) graphregion(passthru)]

    /* display syntax */
    di "varlist: `varlist',  heat: `heat' " _n
    di `"using: `using'"'

    /* set default name vars if empty */
    if ("`name'" == "") {
      local name = "pn_heatmap"
    }
    if ("`msize'" == "") {
      local msize = "vtiny"
    }

    /* manage if statement since we need  '&', not 'if' */
    // if ("`if'" != "") {
      //   local if = "& `if'"
      // }

    /* show command if requested */
    if !mi("`cmd'") {
      di `"cap drop pnp                                                                                                 "'
      di `"egen pnp = cut(`heat') `if', group(10)                                                                       "'
      di `"twoway (scatter `varlist' if pnp == 0, msize(`msize') mcolor("0 0 0"))  ///                                  "'
          di `"  (scatter `varlist' if pnp == 1, msize(`msize') mcolor("35 0 0"))  ///                                      "'
          di `"  (scatter `varlist' if pnp == 2, msize(`msize') mcolor("65 0 0"))  ///                                      "'
          di `"  (scatter `varlist' if pnp == 3, msize(`msize') mcolor("90 0 0"))  ///                                      "'
          di `"  (scatter `varlist' if pnp == 4, msize(`msize') mcolor("120 10 10"))  ///                                   "'
          di `"  (scatter `varlist' if pnp == 5, msize(`msize') mcolor("145 20 20"))  ///                                   "'
          di `"  (scatter `varlist' if pnp == 6, msize(`msize') mcolor("170 30 30"))  ///                                   "'
          di `"  (scatter `varlist' if pnp == 7, msize(`msize') mcolor("195 40 40"))  ///                                   "'
          di `"  (scatter `varlist' if pnp == 8, msize(`msize') mcolor("220 50 50"))  ///                                   "'
          di `"  (scatter `varlist' if pnp == 9, msize(`msize') mcolor("255 60 60") name(`name', replace)   ), legend(off)  "'
    }

    /* split numeric variable into 10 pieces */
    cap drop pnp
    egen pnp = cut(`heat') `if', group(10)

    /* draw the heatmap [from blue to red] */
    twoway (scatter `varlist' if pnp == 0, msize(`msize') mcolor("0 0 0"))  ///
        (scatter `varlist' if pnp == 1, msize(`msize') mcolor("35 0 0"))  ///
        (scatter `varlist' if pnp == 2, msize(`msize') mcolor("65 0 0"))  ///
        (scatter `varlist' if pnp == 3, msize(`msize') mcolor("90 0 0"))  ///
        (scatter `varlist' if pnp == 4, msize(`msize') mcolor("120 10 10"))  ///
        (scatter `varlist' if pnp == 5, msize(`msize') mcolor("145 20 20"))  ///
        (scatter `varlist' if pnp == 6, msize(`msize') mcolor("170 30 30"))  ///
        (scatter `varlist' if pnp == 7, msize(`msize') mcolor("195 40 40"))  ///
        (scatter `varlist' if pnp == 8, msize(`msize') mcolor("220 50 50"))  ///
        (scatter `varlist' if pnp == 9, msize(`msize') mcolor("255 60 60") ///
        name(`name', replace)   ), xtitle(`xtitle') ytitle(`ytitle') `xlabel' `ylabel' `xscale' `yscale' `graphregion' legend(off) xscale(off) yscale(off)

    drop pnp
    if ("`using'" != "") {
      di "exporting `using'..." _n
      graph export `using', replace
    }
    else {
      di "not saving anything"
    }
  }
end

cap prog drop list_state_ids
prog def list_state_ids
  set more off
  preserve
  use $keys/pc01_state_key.dta, clear
  sort pc01_state_id
  list pc01_state_id pc01_state_name, clean noobs
  restore
end

cap prog drop list_nic_codes
prog def list_nic_codes
  preserve
  use $keys/NIC_w_names, clear
  set linesize 255
  sort NIC
  list NIC NIC_name, clean noobs
  restore
end

cap prog drop list_nic_classes
prog def list_nic_classes
  {
    di "           1               activities of private households"
    di "           2                                             ag"
    di "           3                                   construction"
    di "           4                                          crazy"
    di "           5                                      education"
    di "           6                          extraterritorial orgs"
    di "           7                             finance - informal"
    di "           8                               finance - normal"
    di "           9                                           fish"
    di "          10                         health and social work"
    di "          11                         hotels and restaurants"
    di "          12                 manufacturing - food and drink"
    di "          13                          manufacturing - heavy"
    di "          14                          manufacturing - light"
    di "          15                       manufacturing - textiles"
    di "          16                                 mining - heavy"
    di "          17                                 mining - light"
    di "          18                     other community activities"
    di "          19                          public administration"
    di "          20   real estate, renting and business activities"
    di "          21                             trade - automotive"
    di "          22                                 trade - retail"
    di "          23                              trade - wholesale"
    di "          24          transport, storage and communications"
    di "          25                                      utilities"
  }
end

/***********************************************************/
/* program get_state_names : merge in statenames using ids */
/***********************************************************/
/* get state names ( y(91) if want 1991 ids ) */
cap prog drop get_state_names
prog def get_state_names
  {
    syntax , [Year(string)]

    /* default is 2001 */
    if mi("`year'") {
      local year 01
    }

    /* merge to the state key on state id */
    merge m:1 pc`year'_state_id using $keys/pc`year'_state_key, gen(_gsn_merge) keepusing(pc`year'_state_name) update replace

    /* display state ids that did not match the key */
    di "These ids were not found in the key: "
    cap noi table pc`year'_state_id if _gsn_merge == 1

    /* drop places that were only in the key */
    di _n "Dropping states only in the key, not in master data..."
    drop if _gsn_merge == 2
    drop _gsn_merge
  }
end
/** END program get_state_names ************************************************************/

/****************************************************************/
/* program get_state_ids : merge in state_ids using state_names */
/****************************************************************/
/* get state ids ( y(91) if want 1991 ids ) */
cap prog drop get_state_ids
prog def get_state_ids
  {
    syntax , [Year(string)]

    /* default is 2001 */
    if mi("`year'") {
      local year 01
    }

    /* merge to the state key on state name */
    merge m:1 pc`year'_state_name using $keys/pc`year'_state_key, gen(_gsn_merge) update replace

    /* display state names that did not match the key */
    di "unmatched names: "
    cap noi table pc`year'_state_name if _gsn_merge == 1

    /* drop places that were only in the key */
    drop if _gsn_merge == 2
    drop _gsn_merge

  }
end
/** END program get_state_ids ************************************************************/


/***********************************************************************************/
/* program twoway_rb : undocmented program */
/***********************************************************************************/
cap prog drop twoway_rb
prog def twoway_rb

  syntax varlist(min=2), if_black(string) if_red(string) [msize(string)]

  if "`msize'" == "" {
    local msize "vtiny"
  }

  di "twoway (scatter `varlist' if `if_black', color(black) msize(vtiny)) (scatter `varlist' if `if_red', color(red) msize(`msize'))"
  twoway (scatter `varlist' if `if_black', color(black) msize(`msize')) (scatter `varlist' if `if_red', color(red) msize(`msize'))

end
/** END program twoway_rb ************************************************************/

/***********************************************************************************/
/* program gen_location_fe : generate state district and subdistrict fixed effects */
/***********************************************************************************/
cap prog drop gen_location_fe
prog def gen_location_fe
  {
    syntax , [nosubd] [Year(string)]

    cap drop state_id
    cap drop dist_id
    cap drop subd_id

    if ("`year'" == "") {
      local year = "01"
    }

    /* generate f.e. */
    destring pc`year'_state_id, gen(state_id)
    destring pc`year'_district_id, gen(dist_id)
    replace dist_id = state_id * 1000 + dist_id

    /* generate subd effect unless told not to */
    if ("`subd'" != "nosubd") {
      destring pc`year'_subdistrict_id, gen(subd_id)
      replace subd_id = dist_id * 1000 + subd_id
    }

    foreach var of varlist *_id {
      label var `var' ""
    }
  }
end
/** END program gen_location_fe ************************************************************/


/**********************************************************************************/
/* program gen_vars : Generate a list of stata vars as missing */
/***********************************************************************************/
cap prog drop gen_vars
prog def gen_vars
  {
    syntax namelist

    foreach i in `namelist' {
      gen `i' = .
    }
  }
end
/* *********** END program gen_vars ***************************************** */


/**********************************************************************************/
/* program sumstatout : Generate a table of summary statistics                    */
/***********************************************************************************/
cap prog drop sumstatout
prog def sumstatout
  {
    syntax varlist using/, Group(varname)



    /* store variable labels in order of varlist */
    // local varlist = "emp_NICC23 emp_NICC24 emp_NICC25"
    local label_list = "x"
    foreach i in `varlist' {

      local tmp: var label `i'

      local label_list `label_list' "`tmp'"
    }

    // di `"LABEL LIST IS `label_list'"'

    /* generate a unique identifier */
    tempvar unique_id
    gen `unique_id' = _n

    /* keep what we want */
    keep `varlist' `group' `unique_id'

    /* prefix everything in varlist so we have a stub to reshape on */
    local j = 100
    foreach i in `varlist' {

      gen foo`j' = `i'

      local j = `j' + 1
    }

    /* reshape data so everything is one variable, with varnames identified by column foo_ */
    reshape long foo, string i(`unique_id') j(v)

    label var v "Variable"

    /* relabel variables */
    local label_foo_str = "label define bar "
    local j = 100

    local num_vars : word count `label_list'

    forval i=1/`num_vars' {
      local k = `i' + 1
      local cur_label: word `k' of `label_list'
      // di "CUR LABEL IS `cur_label'"

      local label_foo_str `label_foo_str' `j' "`cur_label'"
      local j = `j' + 1
    }
    // di `"LABEL DEFINE COMMAND: `label_foo_str'"'
    `label_foo_str'

    destring v, replace
    label values v bar


    /* produce the desired table */
    table v `group', c(mean foo)

    /* run tabout */
    local tabout_str tabout v `group' using `using', cells(mean foo) font(bold) format(0c) bt cl1(2-4) clab(_) ptotal(none) h3(nil) replace style(tex) topf(~/ddl/tools/tex/top.tex) botf(~/ddl/tools/tex/bot.tex) sum topstr(8cm)

    di `"tabout command: `tabout_str'"'
    `tabout_str'
    restore
  }
end
/* *********** END program sumstatout ***************************************** */





/**********************************************************************************/
/* program show_coef : show coef of interest from a regression in a single line   */
/***********************************************************************************/
cap prog drop show_coef
prog def show_coef
  {
    syntax name, [Title(string)]
    local b = _b[`namelist']
    local se: di %3.2f _se[`namelist']

    qui test `namelist' = 0

    local star = ""
    if r(p) <= 0.1  local star = "*"
    if r(p) <= 0.05 local star = "**"
    if r(p) <= 0.01 local star = "***"

    di %20s "`title' " "b: " %8.3f `b' " (" `se' ")  p: " %-4.2f `r(p)' "`star'"
  }
end
/* *********** END program show_coef ***************************************** */

/**********************************************************************************/
/* program count_stars : return a string with the right number of stars           */
/**********************************************************************************/
cap prog drop count_stars
prog def count_stars, rclass
  {
    syntax, p(real)
    local star = ""
    if `p' <= 0.1  local star = "*"
    if `p' <= 0.05 local star = "**"
    if `p' <= 0.01 local star = "***"
    return local stars = "`star'"
  }
end
/* *********** END program count_stars ***************************************** */


/**********************************************************************************/
/* program box_plot : set of programs to produce box plot from a set of regs */
/***********************************************************************************/
cap prog drop box_prep
cap prog drop box_store_reg
cap prog drop box_show
prog def box_prep
  {
    foreach i in box_row_number box_up box_down box_b box_se box_label {
      cap drop `i'
    }
    gen box_row_number = _n
    gen box_up = .
    gen box_down = .
    gen box_b = .
    gen box_se = .
    gen box_label = ""
  }
end

prog def box_store_reg
  {
    syntax name, [Label(string)] Row(real)
    replace box_b = _b["`namelist'"] if box_row_number == `row'
    replace box_se = _se["`namelist'"] if box_row_number == `row'
    replace box_down = box_b - 1.64 * box_se if box_row_number == `row'
    replace box_up = box_b + 1.64 * box_se if box_row_number == `row'

    if "`label'" != "" {
      replace box_label = "`label'" if box_row_number == `row'
    }
  }
end

prog def box_show
  {
    syntax, [Filename(string) Graphname(string) YTitle(string) XName(string) Title(string) XScale(string) YScale(string)]

    /* fill in default graph name if missing */
    if "`graphname'" == "" {
      local graphname "Boxplot"
    }

    /* set up x scale */
    if "`xscale'" != "" {
      local xscale = "xscale(range(`xscale'))"
    }

    if "`yscale'" != "" {
      local yscale = "yscale(range(`yscale'))"
    }

    /* set up x axis */
    if "`xname'" != "" {
      local xname xtitle("`xname'")
    }
    else {
      local xname xscale(off) xtitle("")
      local xscale ""
    }

    /* drop the graph */
    twoway (rcap box_up box_down box_row_number if !mi(box_b)) (scatter box_b box_row_number if !mi(box_b), mlabel(box_label) mlabpos(7) legend(off) `xname' ytitle(`ytitle')  name(`graphname', replace)), title("`title'") yline(0) `xscale' `yscale' graphregion(color(white))

    /* export graph if applicable, and convert eps to pdf */
    if "`filename'" != "" {
      graph export `filename'.eps, replace
      shell epstopdf `filename'.eps
    }

  }
end
/* *********** END program box_plot ***************************************** */

/**********************************************************************************/
/* program count_group : Count number of groups of some kind of observation        */
/***********************************************************************************/
cap prog drop count_group
prog def count_group, rclass
  {
    syntax varlist
    egen __cg_tag = tag(`varlist')
    count if __cg_tag
    local a = `r(N)'
    drop __cg_tag
    return scalar N=`a'
  }
end
/* *********** END program count_group ***************************************** */


/**********************************************************************************/
/* program draw_reg : Draw prediction of a reg with some raw pmgsy data           */
/***********************************************************************************/
cap prog drop draw_reg
prog def draw_reg
  {
    syntax varlist(min=2 max=2), [threshold real 1000]
    tokenize `varlist'

    foreach i in yhat {
      cap drop `i'
    }

    predict yhat if e(sample)

    /* limit number of yhat observations to 500 */
    qui {
      set more off
      count if !mi(yhat)
      while (r(N) > 500) {
        replace yhat = . if !mi(yhat) & uniform() < 0.1
        count if !mi(yhat)
      }
    }

    scatter yhat `2' if !mi(yhat), msize(vtiny) xline(`threshold')

  }
end
/* *********** END program draw_reg ***************************************** */

/**********************************************************************************/
/* program svn_update */
/***********************************************************************************/
cap prog drop svn_update
prog def svn_update
  {
    shell svn update ~/iecmerge
  }
end
/* *********** END program svn_update ***************************************** */

/**********************************************************************************/
/* program normalize: demean and scale by standard deviation */
/***********************************************************************************/
cap prog drop normalize
prog def normalize
  {
    syntax varname, [REPLace GENerate(name)]
    tokenize `varlist'

    /* require generate or replace [sum of existence must equal 1] */
    if ((!mi("`generate'") + !mi("`replace'")) != 1) {
      display as error "normalize: generate or replace must be specified, not both"
      exit 1
    }

    tempvar tmp

    cap drop __mean __sd
    egen __mean = mean(`1')
    egen __sd = sd(`1')
    gen `tmp' = (`1' - __mean) / __sd
    drop __mean __sd

    /* assign created variable based on replace or generate option */
    if "`replace'" == "replace" {
      replace `1' = `tmp'
    }
    else {
      gen `generate' = `tmp'
    }
  }
end
/* *********** END program normalize ***************************************** */


/**********************************************************************************/
/* program median_dummy: create dummy for variable above median value */
/***********************************************************************************/
cap prog drop median_dummy
prog def median_dummy
  {
    syntax varname, Generate(name)
    egen tmp100 = median(`varlist')
    gen `generate' = `varlist' >= tmp100 if !mi(`varlist')
    drop tmp100
  }
end
/* *********** END program median_dummy ***************************************** */


/**********************************************************************************/
/* program discretize: create dummies for percentile groups of a variable range */
/***********************************************************************************/
cap prog drop discretize
prog def discretize
  {
    syntax varname [if], stub(name) bins(integer)
    tempvar tmp
    egen `tmp' = cut(`varlist') `if', group(`bins')
    qui tab `tmp',  gen(`stub')
  }
end
/* *********** END program discretize ***************************************** */


/**********************************************************************************/
/* program gen_fe: create fixed effects variables for a varlist */
/***********************************************************************************/
cap prog drop gen_fe
prog def gen_fe
  {
    syntax varlist, stub(name)
    tempvar tmp
    egen `tmp' = group(`varlist')
    qui tab `tmp',  gen(`stub')
  }
end
/* *********** END program gen_fe ***************************************** */


/**********************************************************************************/
/* program flag_outliers : Mark outliers */
/***********************************************************************************/
cap prog drop flag_outliers
prog def flag_outliers
  {
    syntax varlist(min=1), range(numlist) [badvar(name)] [pct] [drop]

    if mi("`badvar'") {
      local badvar __bad
      cap drop __bad
    }

    tokenize `range'

    /* create flag variable if it doesn't exist yet */
    cap gen `badvar' = 0
    assert inlist(`badvar', 0, 1)

    foreach var of varlist `varlist' {

      if !mi("`pct'") {
        qui centile `var', centile(`1' `2')
        di "Flagging observations of `var' not in range(`r(c_1)', `r(c_2)')..."
        replace `badvar' = 1 if !inrange(`var', `r(c_1)', `r(c_2)') & !mi(`var')
      }
      else {
        di "Flagging observations of `var' not in range(`1', `2')..."
        replace `badvar' = 1 if !inrange(`var', `1', `2') & !mi(`var')
      }
    }
    if !mi("`drop'") {
      drop if `badvar' == 1
      drop `badvar'
    }
  }
end
/* *********** END program flag_outliers ***************************************** */

/**********************************************************************************/
/* program estmod_list_fix : make listtex output look nice */
/***********************************************************************************/
cap prog drop estmod_list_fix
prog def estmod_list_fix
  {
    syntax using/

    shell python ~/ddl/tools/py/scripts/est_modify.py -c clean_list -i `using' -o `using'
  }
end
/* *********** END program estmod_list_fix ***************************************** */

/****************************************************************************************/
/* program estmod_long_list_fix : make listtex output look nice and span multiple pages */
/****************************************************************************************/
cap prog drop estmod_long_list_fix
prog def estmod_long_list_fix
  {
    syntax using/

    shell python ~/ddl/tools/py/scripts/est_modify.py -c clean_long_list -i `using' -o `using'
  }
end
/* *********** END program estmod_long_list_fix ***************************************** */

/**********************************************************************************/
/* program estmod_footer : add a footer row to an estout set */
/***********************************************************************************/
cap prog drop estmod_footer
prog def estmod_footer
  syntax using/, cstring(string)
  
  /* add .tex suffix to using if not there */
  if !regexm("`using'", "\.tex$") local using `using'.tex
  
  shell python ~/ddl/tools/py/scripts/est_modify.py -c footer -i `using' -o `using' --cstring "`cstring'"
end
/* *********** END program estmod_footer ***************************************** */

/**********************************************************************************/
/* program estmod_header : add a header row to an estout set */
/***********************************************************************************/
cap prog drop estmod_header
prog def estmod_header
  syntax using/, cstring(string)
  
  /* add .tex suffix to using if not there */
  if !regexm("`using'", "\.tex$") local using `using'.tex
  
  shell python ~/ddl/tools/py/scripts/est_modify.py -c header -i `using' -o `using' --cstring "`cstring'"
end
/* *********** END program estmod_header ***************************************** */

/**********************************************************************************/
/* program estmod_row_highlight : highlight a coef row in an estout set */
/***********************************************************************************/
cap prog drop estmod_row_highlight
prog def estmod_row_highlight
  {
    syntax using/, coef(string) color(string)

    /* add .tex suffix to using if not there */
    if !regexm("`using'", "\.tex$") local using `using'.tex

    shell python ~/ddl/tools/py/scripts/est_modify.py -c highlight_row -i `using' -o `using' --color "`color'" --coef "`coef'"
  }
end
/* *********** END program estmod_row_highlight ***************************************** */


/**********************************************************************************/
/* program estmod_col_div : put in a column divider */
/***********************************************************************************/
cap prog drop estmod_col_div
prog def estmod_col_div
  {
    syntax using/, COLumn(integer)

    /* add .tex suffix to using if not there */
    if !regexm("`using'", "\.tex$") local using `using'.tex

    shell python ~/ddl/tools/py/scripts/est_modify.py -c col_div -i `using' -o `using' --column "`column'"
  }
end
/* *********** END program estmod_col_div ***************************************** */

/**********************************************************************************/
/* program show_mismatch : Insert description here */
/***********************************************************************************/
cap prog drop show_mismatch
prog def show_mismatch
  {
    syntax varlist, file1(string) file2(string)

    /* open the first file and make it unique on varlist */
    use `file1', clear
    keep `varlist'
    duplicates drop `varlist', force

    /* merge on varlist to the second file, allowing second file to not be duplicate */
    merge 1:m `varlist' using `file2'

    duplicates drop `varlist' _merge, force

    /* sort and display */
    sort `varlist' _merge
    list `varlist' _merge
  }
end
/* *********** END program show_mismatch ***************************************** */

/**********************************************************************************/
/* program gen_kernel : Insert description here */
/***********************************************************************************/
cap prog drop gen_kernel
prog def gen_kernel
  {
    syntax varname, Bandwidth(real) GENerate(name)

    tokenize `varlist'
    gen `generate' = ((`bandwidth' - abs(`1')) / `bandwidth') * (abs(`1') < `bandwidth')

  }
end
/* *********** END program gen_kernel ***************************************** */

/**********************************************************************************/
/* program set_rseed : Insert description here */
/***********************************************************************************/
cap prog drop set_rseed
prog def set_rseed
  {
    /* generate a seed based on millisecond timer */
    shell ~/ddl/tools/sh/get_rseed.sh >$iec/output/tmp/rseed

    /* read seed into a local variable */
    preserve
    insheet using $iec/output/tmp/rseed., clear
    local x = v1
    restore

    /* set random number seed */
    di "Setting random number seed to `x'"
    set seed `x'
  }
end
/* *********** END program set_rseed ***************************************** */

/**********************************************************************************/
/* program collapse_ec : Collapse new economic census to one row per location     */
/* sample uses:
- full collapse:
collapse_ec, year(05) tru(urban)
- keep NIC in long format:
collapse_ec, year(05) tru(urban) keeplong(NIC)
- keep NIC and size_group in long:
collapse_ec, year(05) tru(urban) keeplong(NIC size_group)
- make NIC wide, keep size groups
collapse_ec, year(05) tru(urban) keeplong(NIC size_group) keepwide(NIC)
- if you want wide by two groups, need to run the function twice:
use ec05u_collapsed_new, clear
keep if ec05_state_id == "02"

keep *id gov NIC size_group ec05_emp_all ec05_count_all

// e.g. get NIC / size_group into wide format
collapse_ec, year(05) tru(urban) keeplong(size_group) keepwide(NIC)

ren ec05_emp_all* ec05_emp_all_NIC*_
ren ec05_count_all* ec05_count_all_NIC*_

// now get size group into wide format
collapse_ec, year(05) tru(urban) keepwide(size_group)
*/
/**********************************************************************************/
cap prog drop collapse_ec
prog def collapse_ec
  {
    syntax, year(string) TRU(string) [KEEPWIDE(varlist) KEEPLONG(string) OUTfile(string) INfile(string)]

    /* check input parameters and set defaults */
    if !inlist("`year'", "90", "98", "05") {
      display as error "year must be 90, 98 or 05"
      exit 1
    }

    if "`outfile'" == "" {
      local outfile $tmp/ec`year'_`tru'_collapsed
    }

    /* set collapse ids */
    if "`tru'" == "rural" {
      if "`year'" == "90" | "`year'" == "98" {
        local ids ec`year'_state_id ec`year'_district_id ec`year'_subdistrict_id ec`year'_village_id
      }
      else if "`year'" == "05" {
        local ids ec05_state_id ec05_village_id
      }
    }
    else if "`tru'" == "urban" {
      local ids ec`year'_state_id ec`year'_district_id ec`year'_town_id
    }
    else {
      display as error "tru must be urban or rural"
      exit 1
    }

    /* TO DO: if we're keeping long, we just use a longer collapse
    list.  1. add variables in keeplong to `ids'. Everything else
    stays the same.  */
    if !mi("`keeplong'") {
      local ids `ids' `keeplong'
    }

    /* TO DO: if we're keeping wide, first collapse over everything else
    (remove widevars from ids as above), and then run a reshape. */
    if !mi("`keepwide'") {

      // first make sure the things we want wide are not collapsed. then do a reshape below
      local ids `ids' `keepwide'
    }

    /* if there's an infile, load it, without a clear to avoid erroneous use */
    if !mi("`infile'") {
      use "`infile'"
    }

    /* TO DO:
    - can you do wide and long?  probably.
    - how should we think about interactions?  we may want NICs in wide, and GOV in wide
    */


    /* run collapse over categories we no longer want */
    di c(current_time)
    disp_nice "COLLAPSE COMMAND: collapse (sum) ec`year'_emp_* (sum) ec`year'_count_*, by(`ids')"
    collapse (sum) ec`year'_emp_* (sum) ec`year'_count_*, by(`ids')
    di c(current_time)

    /* now reshape if we wanted something in wide format */
    if !mi("`keepwide'") {

      /* now remove wide variables from ids */
      tokenize `keepwide'
      if !mi("`2'") {
        display as error "Can only keep one wide variable at this point. Sorry."
        exit 1
      }
      local i = 1

      /* loop over all tokens */
      while !mi("``i''") {

        /* remove this wide variable from id list */
        local ids = subinstr("`ids'", "``i''", "", .)

        /* increment token counter */
        local i = `i' + 1
      }

      di c(current_time)
      disp_nice "RESHAPE COMMAND: reshape wide ec`year'_emp_* ec`year'_count_*, i(`ids') j(`keepwide')"
      reshape wide ec`year'_emp_* ec`year'_count_*, i(`ids') j(`keepwide')
      di c(current_time)
    }

    compress
    save `outfile', replace

  }
end
/* *********** END program collapse_ec ***************************************** */

/**********************************************************************************/
/* program find_prog : Find a Stata program and show its syntax or source               */
/***********************************************************************************/
cap prog drop find_prog
prog def find_prog
  {
    syntax anything, [Full Syntax]
    tokenize `anything'
    
    if !mi("`syntax'") {
      shell python ~/ddl/tools/py/scripts/parse_ddl_tools.py syntax -p `1'
    }
    else if !mi("`full'") {
      shell python ~/ddl/tools/py/scripts/parse_ddl_tools.py source -p `1'
    }
    else {
      shell python ~/ddl/tools/py/scripts/parse_ddl_tools.py header -p `1'
    }
  }
end
/* *********** END program find_prog ***************************************** */

/**********************************************************************************/
/* program topcode_pct : top and bottom code variables with percentages */
/***********************************************************************************/
/* purpose is to quickly top- and bottom-code a variable by percentages. if you enter */
/* the same variable in gen as in varname, you'll replace values rather than creating */
/* a new var */
cap prog drop topcode_pct
prog def topcode_pct
  {
    syntax varname, BOT(real) TOP(real) GENerate(string)
    tokenize `varlist'
    _pctile `1', p(`bot' `top')
    cap gen `generate' = `1'
    replace `generate' = r(r1) if `generate' < r(r1) & !mi(`generate')
    replace `generate' = r(r2) if `generate' > r(r2) & !mi(`generate')
  }
end
/* *********** END program topcode_pct ***************************************** */

/**********************************************************************************/
/* program get_ecol_header_string : Returns a string "(1) (2) (3) ..." matching
the number of stored estimates.
*/
/***********************************************************************************/
cap prog drop get_ecol_header_string
prog def get_ecol_header_string, rclass
  {
    syntax

    /* get number of last estimate from ereturn */
    local s = substr("`e(_estimates_name)'", 4, .)
    local cstring = ""

    /* build string "(1) (2) (3) ..." */
    forval i = 1/`s' {
      local cstring = `" `cstring' "(`i')" "'
    }
    return local col_headers = `"`cstring'"'
  }
end
/* *********** END program get_ecol_header_string ***************************************** */

/**********************************************************************************/
/* program estout_default : Run default estout command with (1), (2), etc. column headers.
Generates a .tex and .html file. "using" should not have an extension.
*/
/***********************************************************************************/
cap prog drop estout_default
prog def estout_default
  {
    syntax [anything] using/ , [KEEP(passthru) MLABEL(passthru) ORDER(passthru) TITLE(passthru) HTMLonly PREFOOT(passthru) EPARAMS(string)]

    /* if mlabel is not specified, generate it as "(1)" "(2)" */
    if mi(`"`mlabel'"') {

      /* run script to get right number of column headers that look like (1) (2) (3) etc. */
      get_ecol_header_string

      /* store in a macro since estout is rclass and blows away r(col_headers) */
      local mlabel `"mlabel(`r(col_headers)')"'
    }

    /* if keep not specified, set to the same as order */
    if mi("`keep'") & !mi("`order'") {
      local keep = subinstr("`order'", "order", "keep", .)
    }

    /* set eparams string if not specified */
    //   if mi(`"`eparams'"') {
      //     local eparams `"$estout_params"'
      //   }

    /* if prefoot() is specified, pull it out of estout_params */
    if !mi("`"prefoot"'") {
      local eparams = subinstr(`"$estout_params"', "prefoot(\hline)", `"`prefoot'"', .)
    }

    //  if !mi("`prefoot'") {
      //    local eparams = subinstr(`"`eparams'"', "prefoot(\hline)", `"`prefoot'"', .)
      // }
    //  di `"`eparams'"'

    /* output tex file */
    if mi("`htmlonly'") {
      // di `" estout using "`using'.tex", `mlabel' `keep' `order' `title' `eparams' "'
      estout `anything' using "`using'.tex", `mlabel' `keep' `order' `title' `eparams'
    }

    /* output html file for easy reading */
    estout `anything' using "`using'.html", `mlabel' `keep' `order' `title' $estout_params_html

    /* if HTMLVIEW is on, copy the html file to caligari/ */
    if ("$HTMLVIEW" == "1") {

      /* make sure output folder exists */
      cap confirm file ~/public_html/html/
      if _rc shell mkdir ~/public_html/html/

      /* copy the file to HTML folder */
      shell cp  `using'.html ~/public_html/html/

      /* strip path component from the link */
      local filepart = regexr("`using'", ".*/", "")
      if !strpos("`using'", "/") local filepart `using'
      local linkpath "http://caligari.dartmouth.edu/~`c(username)'/html/`filepart'.html"
      di "View table at `linkpath'"
    }
  }
end

/* *********** END program estout_default ***************************************** */

/********************************************/
/* program estouts: estout to screen only   */
/********************************************/
cap prog drop estouts
prog def estouts
  {
    estout, $estout_params_scr
  }
end
/** END program estouts *********************/


/**********************************************************************************/
/* program write_data_dict : Writes a data dictionary file from a data file       */
/**********************************************************************************/
cap prog drop write_data_dict
prog def write_data_dict
  {
    syntax using, [REPLACE]

    /* open data dictionary csv file with the file handle "fh" */
    cap file close fh
    file open fh `using', write `replace'

    /* Write the column labels */
    file write fh `"Variable Name,"'
    file write fh `"Variable Label,"'
    file write fh `"Variable Type,"'
    file write fh `"No. Non-Missing Obs.,"'
    file write fh `"No. Unique Values,"'
    file write fh `"Min,"'
    file write fh `"Max,"'
    file write fh `"Mean,"'
    file write fh `"Standard Dev.,"'
    file write fh `"10 %-ile,"'
    file write fh `"25 %-ile,"'
    file write fh `"50 %-ile,"'
    file write fh `"75 %-ile,"'
    file write fh `"90 %-ile,"'
    file write fh `"Mean strlen,"'
    file write fh `"Max strlen"'
    file write fh _n

    /* loop over all variables */
    foreach v of varlist * {

      /* write the variable name to the file */
      file write fh `""`v'","'

      /* get the variable's label into the local macro v_label */
      local v_label : variable label `v'

      /*If there are commas in the label, remove them*/
      /*replace v_label = subinstr(v_label, ",", "", .)*/

      /* write the variable label to the output file */
      file write fh `""`v_label'","'

      /* write the variable's type into the local macro v_type */
      local v_type : type `v'

      /* write the variable type into the output file */
      file write fh `""`v_type'","'

      /* write number of observations to output file */
      count if !mi(`v')
      file write fh "`r(N)',"

      /* write number of unique values. requires installation of stata command: distinct. (ssc install distinct) */
      capture distinct `v'
      file write fh "`r(ndistinct)',"

      /* write min, max, mean, sd for numeric variables */
      sum `v'
      file write fh "`r(min)',"
      file write fh "`r(max)',"
      file write fh "`r(mean)',"
      file write fh "`r(sd)',"

      /* write percentiles for numeric variables */
      centile `v', centile(10 25 50 76 90)
      file write fh "`r(c_1)',"
      file write fh "`r(c_2)',"
      file write fh "`r(c_3)',"
      file write fh "`r(c_4)',"
      file write fh "`r(c_5)',"

      /* if the variable is a string, count the number of characters */
      capture confirm string variable `v'
      if !_rc {
        tempvar length
        gen `length' = length(`v')
        sum `length' if !mi(`v')
        file write fh "`r(mean)',`r(max)'"
        drop `length'
      }
      else {
        file write fh ","
      }

      /* write a newline (otherwise all these values will be on one line) */
      file write fh _n
    }

    file close fh

  }
end
/* *********** END program write_data_dict ***************************************** */


/**********************************************************************************/
/* program dreps : describe dups - duplicates list with additional fields        */
/**********************************************************************************/
cap prog drop dreps
prog def dreps
  {
    syntax [varlist] [if/], [list(varlist)]

    /* handle if */
    if mi("`if'") {
      local if 1
    }

    /* set varlist for duplicates function */
    local duplicates `varlist'

    /* tag duplicate observations */
    tempname dupvar
    duplicates tag `duplicates' if `if', gen(`dupvar')

    /* pull `varlist' out of `list' so we can list(*) */
    tokenize "`varlist'"
    while (!mi("`1'")) {

      /* if current varlist item in `list' */
      if strpos("`list'", "`1'") {

        /* remove it */
        local list = subinstr(" `list' ", " `1' ", " ", .)
      }

      mac shift
    }

    /* sort by duplicate vars and then specified vars to list */
    sort `duplicates' `list'
    list `duplicates' `list' if `dupvar' & `if', sepby(`duplicates')

    /* clean up and exit */
    drop `dupvar'
  }
end
/* *********** END program dreps ***************************************** */

/**********************************************************************************/
/* program replace_strings : Make a list of replacements to a string variable based
on an external file.                                  */
/*           FILE FORMAT: [old_name]=[new_name]=[groupvar1]=[groupvar2]=... */
/***********************************************************************************/
cap prog drop replace_strings
prog def replace_strings
  {
    syntax varname(min=1 max=1), stringfile(string) [group(varlist)]

    display as error "This program is obsolete. Use synonym_fix() from masala-merge.do instead."
    exit 123

  }
end
/* *********** END program replace_strings ***************************************** */

/******************************************************************************************************************************/
/* program name_clean_merge_target : Creates a name-cleaned version of a file, usually one that is going to be a merge target */
/******************************************************************************************************************************/
cap prog drop name_clean_merge_target
prog def name_clean_merge_target
  {
    syntax anything, infile(string) outfile(string) [dropparens(passthru) replace]

    preserve
    use `infile', clear

    tokenize `anything'

    /* loop over vars in varlist */
    while ("`1'" != "") {

      name_clean `1', gen(`1'_fm) `dropparens'

      mac shift
    }

    save `outfile', `replace'
    restore
  }
end
/* *********** END program name_clean_merge_target ***************************************** */

/**********************************************************************************/
/* program set_dartmouth_paths : Redefine dise globals for sharing with Anjali    */
/**********************************************************************************/
cap prog drop set_dartmouth_paths
prog def set_dartmouth_paths
  {
    global roads "$iec2/dise"
  }
end
/* *********** END program set_dartmouth_paths ***************************************** */

/**********************************************************************************/
/* program get_con_id_from_village : Matches villages to con_id_joint. Takes year
into account and matches both pre- and
post-delimitation.

Requires variable year, pc01_state_id, pc01_village_id

NOTE: THIS PROGRAM IS INCOMPLETE. PLEASE COMPLETE IT!
*/
/***********************************************************************************/
cap prog drop get_con_id_from_village
prog def get_con_id_from_village
  {

    confirm variable year pc01_state_id pc01_village_id

    /* get post-2008 constituency ids for these PC villages */
    merge m:1 pc01_state_id pc01_village_id using $keys/village_con_key_2008, keepusing(con_id08) gen(_merge08)
    drop if _merge08 == 2
    replace con_id08 = "" if year < 2008

    /* get pre-2008 con_ids for PC villages */
    merge m:1 pc01_state_id pc01_village_id using $keys/village_con_key_2007, keepusing(con_id) gen(_merge07)
    drop if _merge07 == 2
    replace con_id = "" if year > 2007

    /* merge with election_long using con_id_joint */
    gen con_id_joint = con_id if year <= 2007
    replace con_id_joint = con_id08 if year > 2007 & !mi(year)
  }
end
/* *********** END program get_con_id_from_village ***************************************** */

/**********************************************************************************/
/* program store_coef : Stores a single coefficient in a file for latex to pick up */
/***********************************************************************************/

cap prog drop store_coef
prog def store_coef
  {

    syntax anything, File(string) [Format(string) Percent String]

    /* set default format */
    if "`format'" == "" {
      local format "%2.0f"
    }

    if "`percent'" != "" {
      local percent "\%"
    }

    /* open the output file */
    cap file close fh
    file open fh using "`file'", write replace
    if !mi("`string'") {
      file write fh "`anything'"
    }
    else {
      file write fh `format' (`anything') "`percent'"
    }
    file close fh

  }
end
/* *********** END program store_coef ***************************************** */

/***********************************************************************************************/
/* program syn_fix_place_names : Run known replacements for state,dist,subdistrict,block names */
/***********************************************************************************************/
cap prog drop syn_fix_place_names
prog def syn_fix_place_names
  {
    syntax varname, [REPLace GENerate(name) place(string) group(varlist)] year(string)

    tokenize `varlist'
    tempvar result

    disp_nice "THIS PROGRAM IS DEPRECATED. Use masala-merge/str_fix instead!"
    
    /* force existence of merge variable */
    cap confirm var _merge
    if !_rc {
      display as error "syn_fix_place_names ERROR: _merge already exists"
      exit 123
    }

    /* require generate or replace [sum of existence must equal 1] */
    if (!mi("`generate'") + !mi("`replace'") != 1) {
      display as error "synonym_fix: generate or replace must be specified, not both"
      exit 1
    }

    /* store intermediate results in temporary var */
    gen `result' = trim(lower(`1'))

    /* set target group variables to pass to synonym_fix and fix_spelling, target group incorporates all names of larger units than place */
    if "`place'" == "district" {
      local targetgroup pc`year'_state_name
    }
    if "`place'" == "subdistrict" | "`place'" == "block" {
      local targetgroup pc`year'_state_name pc`year'_district_name
    }

    /* if group is not specified set group to the default target group */
    if mi("`group'") {
      local group `targetgroup'
    }

    /* run against standard replacement files */
    synonym_fix `result', synfile(~/ddl/core/ecpc/pc`year'/place_synonyms/pc`year'_`place'_fixes.csv) replace targetfield(pc`year'_`place'_name) group(`group') targetgroup(`targetgroup')

    /* run fix_spelling, only if place dictionary exists: */
    local key_file $keys/pc`year'_`place'_key.dta
    cap confirm file `key_file'
    if !_rc {

      /* fix spelling errors */
      fix_spelling `result', srcfile(`key_file') replace targetfield(pc`year'_`place'_name) group(`group') targetgroup(`targetgroup')
    }
    else {
      display "`key_file' does not exist, so not running fix_spelling"
    }

    /* move result to generate or replace */
    if mi("`generate'") {
      replace `1' = `result'
    }
    else {
      gen `generate' = `result'
    }

    /* drop temporary variable created */
    drop `result'
  }
  end
  /* *********** END program syn_fix_place_names ***************************************** */

  /**********************************************************************************/
  /* program pyreg : runs a python stata loop */
  /***********************************************************************************/
  cap prog drop pyreg
  prog def pyreg
  {
    syntax, xml(string) html(string)
    di c(current_time)
    di `"shell python ~/ddl/tools/py/scripts/reg_search.py -o ~/public_html/`html'.html -d $tmp/`html'.do -c $tmp/`html'.csv -x `xml'.xml"'
    shell python ~/ddl/tools/py/scripts/reg_search.py -o ~/public_html/`html'.html -d $tmp/`html'.do -c $tmp/`html'.csv -x `xml'.xml

    disp_nice "Running regressions"
    do $tmp/`html'.do
    di c(current_time)
  }
  end
  /* *********** END program pyreg ***************************************** */

  /**********************************************************************************/
  /* program graphout : Export graph to public_html/png and pdf form                */
  /* defaults:
     - on Dartmouth RC, exports a .png to ~/public_html/png/ only
     - on MacOS, exports a pdf to $tmp
*/
  
  /* options:
     - pdf: export a pdf to $out
     - pdfout(path): specifies an alternate filename or path for the pdf
                     i.e.:  mv file.pdf `pdfout'
*/
  /**********************************************************************************/
  cap prog drop gt
  prog def gt
  {
    syntax anything, [pdf pdfout(passthru)]
    graphout `1', `pdf' `pdfout'
  }
  end

  cap prog drop graphout
  prog def graphout
    
    syntax anything, [small png pdf pdfout(string) QUIet rescale(real 100)]

    /* strip space from anything */
    local anything = subinstr(`"`anything'"', " ", "", .)

    /* break if pdf is specified but not $out not defined */
    if mi("$out") & !mi("`pdf'") {
      disp as error "graphout FAILED: global \$out must be defined if 'out' is specified."
      exit 123
    }

    /* make everything quiet from here */
    qui {

      /* always start with an eps file to $tmp */
      graph export `"$tmp/`anything'.eps"', replace 
      local linkpath `"$tmp/`anything'.eps"'

      /* if small is specified, specify size */
      if "`small'" == "small" {
        local size 480x480
      }

      if "`small'" == ""{
        local size 960x960
      }
      
      /* if "pdf" is specified, send a PDF to $out */
      if "`pdf'" == "pdf" {

        /* convert the eps to pdf in the $tmp folder */
        // noi di "Converting EPS to PDF..."
        shell epstopdf $tmp/`anything'.eps

        /* now move it to its destination, which is $out or `pdfout' */
        if mi("`pdfout'")  local out $out
        if !mi("`pdfout'") local out `pdfout'
        shell mv $tmp/`anything'.pdf `out'
          
        /* set output path for link */
        local linkpath `out'/`anything'.pdf
      }

      /* if on a mac, convert to a pdf in $tmp and kill the eps */
      if ("$macos" == "1") {
        shell epstopdf $tmp/`anything'.eps
        cap erase $tmp/`anything'.eps
        if mi("`pdf'") local linkpath $tmp/`anything'.pdf

        if "$machine" == "paul_office" {
          shell mv `linkpath' ~/Dropbox/tmp
          local linkpath ~/Dropbox/tmp/`anything'.pdf
        }
      }
        
      /* if we are not on macos (i.e. we are on RC), export a png file to ~/public_html */
      if ("$macos" != "1") {

        /* create a large png and move to public_html/png */
        shell convert -size `size' -resize `size' -density 300 $tmp/`anything'.eps $tmp/`anything'.png

        /* if png is specified, save png to out folder */
        if ("`png'" != "") {
          cap erase $out/`anything'.png
          shell convert $tmp/`anything'.png -resize `rescale'% $out/`anything'.png
        }
        
        /* if public_html/png folder exists, move it there */
        cap confirm file ~/public_html/png
        if !_rc {
          shell mv $tmp/`anything'.png ~/public_html/png/`anything'.png
        }
        local linkpath "http://caligari.dartmouth.edu/~`c(username)'/png/`anything'.png"
        if ("$tmp" == "/scratch/pn") local linkpath "http://rcweb.dartmouth.edu/~`c(username)'/png/`anything'.png"
        

      }
        
      /* output a link to the image destination path */
      if mi("`quiet'") {
        shell echo "View graph at `linkpath'"
      }
    }

  end
  /* *********** END program graphout ***************************************** */

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

  /**********************************************************************************/
  /* program def_delims : Define which years and states are in new and old delim    */
  /**********************************************************************************/
  cap prog drop def_delims
  prog def def_delims
  {
    syntax, [state(varname)]
    if mi("`state'") local state pc01_state_name
    cap drop delim_new
    gen delim_new = 0
    replace delim_new = 1 if year > 2007 & !mi(year)
    replace delim_new = 0 if year == 2008 & inlist(`state', "meghalaya", "tripura")
  }
  end
  /* *********** END program def_delims ***************************************** */

  /***********************************************************************/
  /* program graphout_cleanup : Delete .eps and .png created in graphout */
  /***********************************************************************/
  cap prog drop graphout_cleanup
  prog def graphout_cleanup
  {
    /* program force deletes all files created in graphout (.eps + .png or .pdf) */
    /* syntax matches graphout, syntax: graphout_cleanup graphname */
    /* as graphout, graphname should have no file extension, name only */
    syntax anything[, files(string)]

    /* strip spaces from anything */
    local anything = subinstr(`"`anything'"', " ", "", .)

    /* break if $cleanout not defined */
    if mi("$cleanout") {
      disp as error "graphout failed: global \$cleanout must be defined."
      exit 123
    }

    /* display files being deleted and force remove files */
    display "Cleaning up graphs..."
    if mi("`files'") {
      display `"Deleting $cleanout/`anything'.eps"'
      shell rm -f $cleanout/`anything'.eps
      display `"Deleting ~/public_html/png/`anything'.png"'
      shell rm -f ~/public_html/png/`anything'.png
      display `"Deleting $cleanout/`anything'.pdf"'
      shell rm -f $cleanout/`anything'.pdf
    }
    else if !mi("`files'") {
      if regexm("`files'", "eps") {
        display `"Deleting $cleanout/`anything'.eps"'
        shell rm -f $cleanout/`anything'.eps
      }
      if regexm("`files'", "png") {
        display `"Deleting ~/public_html/png/`anything'.png"'
        shell rm -f ~/public_html/png/`anything'.png
      }
      if regexm("`files'", "pdf") {
        display `"Deleting $cleanout/`anything'.pdf"'
        shell rm -f $cleanout/`anything'.pdf
      }
    }
  }
  end
  /* *********** END program graphout_cleanup ************************** */

  /***************************************************************************************/
  /* program encode_string_to_key_secc : Encode variables to numeric separating key w/ values */
  /***************************************************************************************/
/* NOTE: THIS PROGRAM IS OBSOLETE, BUT RETAINED FOR COMPATIBILITY WITH OLD BUILDS.
         THIS VERSION CREATES SUBOPTIMAL STRING TABLES WITH CONFUSING VARNAMES. */

/* program replaces specified variables with numeric encoding in active set */
  /* creating external key linking raw numeric ids to raw string value */

  /* SYNTAX: encode_string_to_key_secc varlist, keypath($iec/pc11/keys) */
  /* keypath specifies top path to save keys to, and will create /keys directory if */
  /* the path specified does not end in this folder name so that all encoded keys */
  /* are always saved to a folder /keys */

  cap prog drop encode_string_to_key_secc
  prog def encode_string_to_key_secc
  {
    syntax varlist, KEYPATH(string)

    /* drop raw_id to use for numeric ids */
    cap drop __raw_id

    /* loop over all variables to encode */
    foreach var in `varlist' {

      /* display current variable encoding to user */
      di "Encoding var: `var'"

      /* remove leading and trailing spaces */
      qui replace `var' = trim(`var')

      /* replace any missing values with -9999 value */
      cap replace `var' = "-9999" if `var' == ""

      /* generate unique ids for unique values */
      egen __raw_id = group(`var')

      /* count number of observations by unique value */
      bysort __raw_id: egen count = count(__raw_id)

      /* tag one observations per unique string */
      egen tag = tag(`var')

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

      /* export raw id - string correspondence keys */
      di "Storing key in `keypath'/`var'_key.dta"
      preserve
      ren __raw_id raw_id
      keep raw_id `var' count tag
      keep if tag == 1
      drop tag
      compress
      save `keypath'/`var'_key.dta, replace
      restore

      /* replace original strings with encoding */
      drop `var'
      ren __raw_id `var'

      /* drop variables no longer needed */
      drop tag count
    }

    /* compress active data file after encoding */
    compress *

  }
  end
  /* *********** END program encode_string_to_key_secc *****************************************/

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

  /***********************************************************************************/
  /* program con_part_get_con_id_joint : Gets con_id_joint from con_part_id and year */
  /***********************************************************************************/
  cap prog drop con_part_get_con_id_joint
  prog def con_part_get_con_id_joint
  {
    cap drop delim_new
    cap drop con_id_joint

    /* get state id from con_part_id if we don't have it yet */
    cap confirm var pc01_state_name
    if _rc {
      cap drop pc01_state_id
      gen pc01_state_id = substr(con_part_id, 1, 2)
      get_state_names
    }
    def_delims
    gen     con_id_joint = substr(con_part_id, 1, 7) if delim_new == 0
    replace con_id_joint = substr(con_part_id, 9, .) if delim_new == 1
  }
  end
  /* *********** END program con_part_get_con_id_joint ***************************************** */

  /*****************************************************************************/
  /* program con_id_joint_get_con_part_id : Gets con_part_id from con_id_joint */
  /*****************************************************************************/
  cap prog drop con_id_joint_get_con_part_id
  prog def con_id_joint_get_con_part_id
  {
    cap gen con_id   = con_id_joint if strlen(con_id_joint) == 7
    cap gen con_id08 = con_id_joint if strlen(con_id_joint) == 12

    preserve
    keep if !mi(con_id)
    count
    local con_id_count = `r(N)'
    save $tmp/tmp_parts_con_ids, replace
    restore

    preserve
    keep if !mi(con_id08)
    count
    local con_id08_count = `r(N)'
    save $tmp/tmp_parts_con_id08s, replace
    restore

    /* open con part data */
    use $keys/con_part_key, clear
    keep con_part_id con_id con_id08 village_count town_count
    save $tmp/con_parts, replace

    /* merge first half data */
    if `con_id_count' > 0 {
      joinby con_id using $tmp/tmp_parts_con_ids, unmatched(both)
      drop if _merge == 1
      save $tmp/__first_half, replace
    }

    /* merge second half data */
    if `con_id08_count' > 0 {
      use $tmp/con_parts, clear
      joinby con_id08 using $tmp/tmp_parts_con_id08s, unmatched(both)
      drop if _merge == 1

      /* append first half data */
      append using $tmp/__first_half
    }

    drop if mi(con_part_id)

    /* swap master / using in merge since we started with con_parts */
    recode _merge 1=2 2=1
    tab _merge
    drop _merge
  }
  end
  /* *********** END program con_id_joint_get_con_part_id ***************************************** */

  /**********************************************************************************/
  /* program grep : Runs grep in the OS */
  /***********************************************************************************/
  cap prog drop grep
  prog def grep
  {
    syntax anything
    shell grep -s `anything'
  }
  end
  /* *********** END program grep ***************************************** */

  /**********************************************************************************/
  /* program dirs : Runs dirs in the OS */
  /***********************************************************************************/
  cap prog drop dirs
  prog def dirs
  {
    shell dirs
  }
  end
  /* *********** END program dirs ***************************************** */

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

  /********************************************************************************************/
  /* program is_unique : Asserts that a variable combination uniquely identifies observations */
  /********************************************************************************************/
  cap prog drop is_unique
  prog def is_unique
  {
    syntax varlist
    bys `varlist': assert _N == 1
  }
  end
  /* *********** END program is_unique ***************************************** */

  /**************************************************************************************************/
  /* program app : short form of append_to_file: app $f, s(foo) == append_to_file using $f, s(foo) */
  /**************************************************************************************************/
  cap prog drop app
  prog def app
  {
    syntax anything, s(passthru) [format(passthru) erase(passthru)]
    append_to_file using `anything', `s' `format' `erase'
  }
  end
  /* *********** END program app ***************************************** */

  /**********************************************************************************/
  /* program disp_est : Display a post-reg estimate on the screen                   */
  /**********************************************************************************/
  cap prog drop disp_est
  prog def disp_est
  {
    syntax, b(string) [title(string)]

    /* get number of observations */
    qui count if e(sample)
    local n = r(N)

    /* get b and se from estimate */
    local beta = _b["`b'"]
    local se   = _se["`b'"]

    /* get p value */
    qui test `b' = 0
    local p = `r(p)'
    if "`p'" == "," {
      local p = 1
    }

    count_stars, p(`p')

    di %30s "`title' `b': " %10.5f `beta' " (" %10.5f `se' ")  (p=" %5.2f `p' ") (n=" %6.0f `n' ")`r(stars)'"
  }
  end
  /* *********** END program disp_est ***************************************** */

  /**********************************************************************************/
  /* program gen_bimaru : Creates bimaru and bimaru2 variables from state names     */
  /**********************************************************************************/
  cap prog drop gen_bimaru
  prog def gen_bimaru
  {
    /* define bimaru */
    global new_states_str `" "jharkhand", "chhattisgarh", "uttarakhand" "'
    global new_states_var  jharkhand, chhattisgarh, uttarakhand
    global bimaru_states_str `" "bihar", "madhya pradesh", "uttar pradesh", "rajasthan", "orissa" "'
    global bimaru_states_var  bihar, madhya pradesh, uttar pradesh, rajasthan, orissa

    gen bimaru = inlist(pc01_state_name, $bimaru_states_str)
    gen bimaru2 = inlist(pc01_state_name, $bimaru_states_str) | inlist(pc01_state_name, $new_states_str)
  }
  end
  /* *********** END program gen_bimaru ***************************************** */

  /******************************************************************/
  /* program rebuild_codemap : Rebuild codemap and directory tree   */
  /******************************************************************/
  cap prog drop rebuild_codemap
  prog def rebuild_codemap
  {
    /* Generate folder tree structure */
    di "Generating directory trees..."
    shell tree $iec  -d -L 4 -H . >$tmp/iec.html
    shell tree $iec1 -d -L 4 -H . >$tmp/iec1.html
    shell tree $iec2 -d -L 4 -H . >$tmp/iec2.html

    shell echo "<h1>iec</h1> " >$tmp/iec_header.txt
    shell echo "<h1>iec1</h1>"  >$tmp/iec1_header.txt
    shell echo "<h1>iec2</h1>"  >$tmp/iec2_header.txt

    shell cat $tmp/iec_header.txt $tmp/iec.html $tmp/iec1_header.txt $tmp/iec1.html $tmp/iec2_header.txt $tmp/iec2.html >~/public_html/iec_tree.html

    di "Generating codemap..."
    shell python ~/ddl/tools/py/scripts/codemap.py

    /* copy text code map to $iec/output/pn */
    copy ~/public_html/code_tree.txt $iec/output/pn/, replace

  }
  end
  /* *********** END program rebuild_codemap ***************************************** */

  /**********************************************************************************/
  /* program collapse_graph_mean : Generate a mobility over time graph                   */

  /*

  Parameters:
  - varname: variable to plot
  - over(age_group) -- defines the x axis variable -- this is what we collapse on
  - by(dataset)     -- optionally overlay graphs according to this variable. [overlay will be 0, 1, 2...]
  - [aw=wt]         -- pass this through to collapse
  - xtitle, ytitle, xlabel, ylabel -- passthru

  */


  /***********************************************************************************/
  cap prog drop collapse_graph_mean
  prog def collapse_graph_mean
  {
    syntax varname [aweight pweight] [if/], over(varname) graphname(string) [by(varname) xtitle(passthru) ytitle(passthru) xlabel(passthru) ylabel(passthru) pdf title(passthru) subtitle(passthru) order(string) xlabel(passthru)]

    capdrop row_number __over __by __b __se __b_low __b_high __byvar
    /* make if work even if not specified */
    if mi("`if'") {
      local if 1
    }

    /* if "by" is missing, just create a placeholder */
    if mi("`by'") {
      gen __byvar = 1
      local by __byvar
    }

    tokenize `varlist'

    /* set ytitle to variable label if not specified */
    if mi("`ytitle'") {
      local ytitle : variable label `1'
      local ytitle ytitle(`ytitle')
    }

    /* create weighting local macro */
    if !mi("`weight'") {
      local wt [`weight'`exp']
    }

    /* prepare data for storage */
    gen row_number = _n
    gen __over = .
    gen __by = .
    gen __b = .
    gen __se = .
    local r 1
    levelsof `over', local(overs)
    foreach over_val in `overs' {
      di "Calculating means for bin `over_val'..."
      qui {
        levelsof `by', local(bys)
        foreach by_var in `bys' {

          /* get mean and semean via regression */
          cap reg `1' `wt' if `by' == `by_var' & `over' == `over_val' & `if'

          /* store estimates, if successful */
          if !_rc {
            replace __b = _b[_cons] if row_number == `r'
            replace __se = _se[_cons] if row_number == `r'
            replace __over = `over_val' if row_number == `r'
            replace __by = `by_var' if row_number == `r'
          }

          /* update row counter */
          local r = `r' + 1
        }
      }
    }

    /* transfer x variable name to over */
    local xl : variable label `over'
    label var __over "`xl'"

    /* store number of categories */
    qui sum `by'
    local num_categories = (`r(max)' - `r(min)') + 1

    /* set grayscale values, depending on number of categories */
    if `num_categories' == 1 {
      local gs1 gs8
    }
    if `num_categories' == 2 {
      local gs1 black
      local gs2 gray
    }
    if `num_categories' == 3 {
      local gs1 gs2
      local gs2 gs6
      local gs3 gs10
    }
    if `num_categories' == 4 {
      local gs1 gs2
      local gs2 gs6
      local gs3 gs10
      local gs4 gs14
    }
    if `num_categories' == 5 {
      local gs1 gs2
      local gs2 gs5
      local gs3 gs8
      local gs4 gs11
      local gs5 gs14
    }

    local lpattern1 line
    local lpattern2 dash
    local lpattern3 dash_dot

    local mpattern1 O
    local mpattern2 T
    local mpattern3 S

    /* generate standard error bounds for each estimate */
    gen __b_low =  __b - 1.96 * __se
    gen __b_high = __b + 1.96 * __se

    /* generate the subgraph for each group in the sample */
    local graph_list
    local legend
    local legend_count 1

    local count = 1
    levelsof `by', local(categories)
    if !mi("`order'") {
      local categories `order'
    }
    foreach i in `categories' {
      local graph`i' (rline __b_low __b_high __over if __by == `i', lpattern(`lpattern`count'') lcolor(`gs`count'')) (scatter __b __over if __by == `i', mcolor(`gs`count'') msymbol(`mpattern`count'') msize(small))

      /* add the graph to the full graph list */
      local graph_list `graph_list' `graph`i''

      /* ADD A LEGEND COMMAND FOR THIS ENTRY */
      /* figure out label name for "by" field */
      local labelname: value label `by'

      /* get variable label */
      if !mi("`labelname'") {
        local label : label `labelname' `i'
        local legend `legend' label(`legend_count' "`label'")
        local legend_count = `legend_count' + 2
      }
      local count = `count' + 1

    }

    /* finalize legend */
    local legend legend(`legend' order(1 3 5 7))

    /* no legend if "by" not specified */
    if "`by'" == "__byvar" {
      local legend legend(off)
    }

    /* store the full graph command */
    local graph_cmd twoway `graph_list', graphregion(color(white))  `xtitle' `ytitle' `legend'  xlabel(1955(10)1985) `ylabel' `title' `subtitle' legend(lcolor(white)) ylabel(#3) name(`graphname', replace)

    /* display graph command, then generate the graph */
    di `"RUNNING: `graph_cmd'"'
    `graph_cmd'

    graphout `graphname', `pdf' large
  }
  end
  /* *********** END program collapse_graph_mean ***************************************** */

  /**********************************************************************************/
  /* program collapse_graph_reg : Generate a mobility over time graph                   */

  /*

  Parameters:
  - varname: variable to plot
  - over(age_group) -- defines the x axis variable -- this is what we collapse on
  - by(dataset)     -- optionally overlay graphs according to this variable. [overlay will be 0, 1, 2...]
  - [aw=wt]         -- pass this through to collapse
  - xtitle, ytitle, xlabel, ylabel -- passthru

  */


  /***********************************************************************************/
  cap prog drop collapse_graph_reg
  prog def collapse_graph_reg
  {
    syntax varlist [aweight pweight] [if/], over(varname) graphname(string) [by(varname) xtitle(passthru) ytitle(passthru) xlabel(passthru) ylabel(passthru) pdf title(passthru) subtitle(passthru) order(string)]

    capdrop row_number __over __by __b __se __b_low __b_high __byvar
    /* make if work even if not specified */
    if mi("`if'") {
      local if 1
    }

    /* if "by" is missing, just create a placeholder */
    if mi("`by'") {
      gen __byvar = 1
      local by __byvar
    }

    tokenize `varlist'

    /* set ytitle to variable label if not specified */
    if mi("`ytitle'") {
      local ytitle : variable label `1'
      local ytitle ytitle(`ytitle')
    }

    /* create weighting local macro */
    if !mi("`weight'") {
      local wt [`weight'`exp']
    }

    /* prepare data for storage */
    gen row_number = _n
    gen __over = .
    gen __by = .
    gen __b = .
    gen __se = .
    local r 1
    levelsof `over', local(overs)
    foreach over_val in `overs' {
      di "Calculating means for bin `over_val'..."
      qui {
        levelsof `by', local(categories)
        /* override the order if passed in */
        if !mi("`order'") {
          local categories `order'
        }
        foreach by_var in `categories' {

          /* get mean and semean via regression */
          cap reg `varlist' `wt' if `by' == `by_var' & `over' == `over_val' & `if'

          /* store estimates, if successful */
          if !_rc {
            replace __b = _b[`2'] if row_number == `r'
            replace __se = _se[`2'] if row_number == `r'
            replace __over = `over_val' if row_number == `r'
            replace __by = `by_var' if row_number == `r'
          }

          /* update row counter */
          local r = `r' + 1
        }
      }
    }

    /* transfer x variable name to over */
    local xl : variable label `over'
    label var __over "`xl'"

    /* store number of categories */
    qui sum `by'
    local num_categories = (`r(max)' - `r(min)') + 1

    /* set grayscale values, depending on number of categories */
    if `num_categories' == 1 {
      local gs1 gs8
    }
    if `num_categories' == 2 {
      local gs1 gs6
      local gs2 gs12
    }
    if `num_categories' == 3 {
      local gs1 gs4
      local gs2 gs8
      local gs3 gs12
    }
    if `num_categories' == 4 {
      local gs1 gs2
      local gs2 gs6
      local gs3 gs10
      local gs4 gs14
    }
    if `num_categories' == 5 {
      local gs1 gs2
      local gs2 gs5
      local gs3 gs8
      local gs4 gs11
      local gs5 gs14
    }

    /* generate standard error bounds for each estimate */
    gen __b_low =  __b - 1.96 * __se
    gen __b_high = __b + 1.96 * __se

    /* generate the subgraph for each group in the sample */
    local graph_list
    local legend
    local legend_count 1

    local count = 1
    levelsof `by', local(categories)
    /* override the order if passed in */
    if !mi("`order'") {
      local categories `order'
    }
    foreach i in `categories' {

      local graph`i' rarea __b_low __b_high __over if __by == `i', color(`gs`count'')) (scatter __b __over, mcolor(black) msize(small))

    /* add the graph to the full graph list */
    local graph_list `graph_list' `graph`i''

    /* ADD A LEGEND COMMAND FOR THIS ENTRY */
    /* figure out label name for "by" field */
    local labelname: value label `by'

    /* get variable label */
    if !mi("`labelname'") {
      local label : label `labelname' `i'
      local legend `legend' label(`legend_count' "`label'")
      local legend_count = `legend_count' + 2
      local count = `count' + 1
    }

    /* finalize legend */
    local legend legend(`legend' order(1 3 5 7))
    
    /* no legend if "by" not specified */
    if "`by'" == "__byvar" {
      local legend legend(off)
    }
    
    /* store the full graph command */
    local graph_cmd twoway `graph_list', xscale(rev) graphregion(color(white)) `title' `subtitle' `xlabel' `ylabel' `xtitle' `ytitle' `legend'  name(`graphname', replace)
    
    /* display graph command, then generate the graph */
    di `"RUNNING: `graph_cmd'"'
    `graph_cmd'
    
    graphout `graphname', `pdf'
  }
end
/* *********** END program collapse_graph_reg ***************************************** */

/***********************************************************************************/
/* program csv_to_html : Inputs an external csv file and writes it as an HTML file */
/***********************************************************************************/
cap prog drop csv_to_html
prog def csv_to_html
{
  syntax, CSV(string) HTML(string)
  cap erase `html'
  append_to_file using `html', s(`"<html><head><link rel="stylesheet" type="text/css" href="style.css"></head><body>"')

  shell echo "<table>" >>`html' ; while read INPUT ; do echo "<tr><td>\${INPUT//,/</td><td>}</td></tr>" >> `html' ; done < `csv' ; echo "</table>" >>`html'
  append_to_file using `html', s(`"</body></html>"')

  /* replace the first TD line with TH */
  shell sed -i '3s/td>/th>/g' `html'
}
end
/* *********** END program csv_to_html ***************************************** */

/********************************************************************************************/
/* program supergroups : Inputs two varialbes and generates a new varialbe for super-groups */
/********************************************************************************************/
cap prog drop supergroups
prog def supergroups
{
  syntax varlist(min=2 max=2), GENerate(name)

  tokenize `varlist'

  quietly {
    tempvar G1 G2 G
    /* generate group identifiers for input variables */
    egen `G1' = group(`1')
    egen `G2' = group(`2')

    /* for each old group, assign maximum of the second group indeitifier number to G */
    bys `G1': egen `G' = max(`G2')

    local c1 = 1
    local c2 = 1

    while `c1' & `c2' {
      di "`c1' `c2'"
      tempvar temp sam
      bys `G2': egen `temp' = max(`G')
      gen `sam' = `G' - `temp'
      count if `sam' ~= 0
      local c1 = r(N)
      replace `G' = `temp'
      drop `temp' `sam'

      bys `G1': egen `temp' = max(`G')
      gen `sam' = `G' - `temp'
      count if `sam' ~= 0
      local c2 = r(N)
      replace `G' = `temp'
      drop `temp' `sam'
    }

    /* generate group identifier for super-group */
    egen `generate' = group(`G')
  }
}
end
/***** END program supergroups ****************/

/**********************************************************************************/
/* program gen_ihs : Insert description here */
/***********************************************************************************/
cap prog drop gen_ihs
prog def gen_ihs
{
  syntax varlist
  foreach v in `varlist' {
    gen ihs_`v' = ln(`v' + sqrt(1 + `v' ^ 2))
  }
}
end
/* *********** END program gen_ihs ***************************************** */


/**************************************************************************************************/
/* program gnu_parallelize : put together the parallelization of a section of code in bash    */
/**************************************************************************************************/

/* this program writes a few temp files and calls GNU parallel to run
a program in parallel. assumes your program takes a `group' and a
`directory' option. by: TL */

/*
a hypothetical example call of this would be: gnu_parallelize, max_cores(5) program(gen_data.do) \\\
input_txt($tmp/par_info.txt) progloc($tmp) options(group state) maxvar pre_comma diag

see the memo
"2018-07-30 TL memo on brute force parallelization in stata" for more
information.

BUGS:
- only checks errors in one log file
- extract_prog requires PRECISELY our program template ("prog def" --> "END PROGRAM")

*/
cap prog drop gnu_parallelize
prog def gnu_parallelize

  /* progloc is required if the program isn't in the default stata path. */
  syntax , MAX_jobs(real) PROGram(string) [INput_txt(string) OPTions(string) progloc(string) PRE_comma RMtxt DIAGnostics trace tracedepth(real 2) manual_input static_options(string) EXTRACT_prog PREP_input_file(string) retries(integer 3) maxvar progress slackbot]

  /* hack: print a warning for deprecated maxvar option that will eventually be removed */
  if !mi("`maxvar'") {
    disp_nice "WARNING: maxvar is a deprecated option; maxvar is set to 30,000 by default"
  }
  
  /* create a random number that will serve as our job ID for this random task */
  !shuf -i 1-10000 -n 1 >> $tmp/randnum.txt

  /* read that random number into a stata macro */
  file open myfile using "$tmp/randnum.txt", read
  file read myfile line
  local randnum "`line'"
  file close myfile

  /* remove the temp file */
  rm $tmp/randnum.txt

  /* display our temporary do file location */
  di "----------------------------------------------------------------------------------"
  di "Program: `program'"
  di "Parameter file: `input_txt'"
  di "Dofile: $tmp/parallelizing_dofile_`randnum'.do"
  di "Logs: $tmp/gnupar_`randnum'/log*.log"
  di "----------------------------------------------------------------------------------"

  /* if we want slack notifications but don't have the global set, throw an error */
  if !mi("`slackbot'") & mi("$slackkey"){
    disp "ERROR: to use slackbot gnupar notifications, please set $slackkey global to your desired Slack app API key"
    error 123
  }
    
  /* if we want a notificiation, send the start announcement */
  if !mi("`slackbot'") & !mi("$slackkey"){
    slack ":building_construction: GNUPAR job monitoring start: *`program'* _(logs in $tmp/gnupar_`randnum')_ ... $S_TIME"
  }

  /* initialize a temporary dofile that will run the data generation for
  a single group */
  cap file close group_dofile
  file open group_dofile using "$tmp/parallelizing_dofile_`randnum'.do", write replace
  
  /* if we want a more diagnostic log, set trace on */
  if !mi("`trace'") {
    file write group_dofile "set trace on" _n
    file write group_dofile "set tracedepth `tracedepth'" _n
  }
  
  /* fill out the temp dofile. if we want to prepare the inputs
  (groups) into a text file, do so */
  if !mi("`prep_input_file'") {
    prep_gnu_parallel_input_file $tmp/gnu_parallel_input_file_`randnum'.txt, in(`prep_input_file')
    local input_txt $tmp/gnu_parallel_input_file_`randnum'.txt
  }
  
  /* stick in the dofile header from an external file */
  /* (using an external file because it's hard to write backticks from stata) */
  /* first, add a global to the dofile so we know the random number */
  file write group_dofile "global randnum `randnum'" _n
  file close group_dofile
  shell cat ~/ddl/tools/do/gnu_parallel_header.tpl >>$tmp/parallelizing_dofile_`randnum'.do
  
  /* reopen group dofile for stata */
  file open group_dofile using "$tmp/parallelizing_dofile_`randnum'.do", write append
  
  /* load in the program if necessary. */
  if !mi("`progloc'") {
    
    /* if we want the program to be extracted from a larger do-file,
    then do so */
    if !mi("`extract_prog'") {
      
      /* use program in tools.do to extract program to temp, saving
      in $tmp/tmp_prog_extracted_`randnum'.do */
      extract_collapse_prog `program', progloc("`progloc'") randnum("`randnum'")
      if !mi("`diagnostics'") {
        file write group_dofile "do $tmp/tmp_prog_extracted_`randnum'.do" _n
      }
      else {
        file write group_dofile "qui do $tmp/tmp_prog_extracted_`randnum'.do" _n
      }
    }
    /* if no extraction needed, then use the program location */
    else if mi("`extract_prog'")  {
      if !mi("`diagnostics'") {
        file write group_dofile "do `progloc'" _n
      }
      else {
        file write group_dofile "qui do `progloc'" _n
      }
    }
  }
  
  /* check if a manual override has been specified. if so, we need to
  get the complete program call lines in from our manual_override
  .txt, and call them one by one. */
  if !mi("`manual_input'") {
    
    /* step 1: count the number of program calls we need to make. */
    file open txtlines using `input_txt', read
    local num_lines = 1
    file read txtlines line
    while r(eof)==0 {
      file read txtlines line
      /* check if there's an empty line (somtimes happens at the end -
      assumes no missing lines in the middle*/
      if !mi("`line'") {
        local num_lines = `num_lines' + 1
      }
    }
    file close txtlines
    
    /* step 2: write a sequence, one number per line, of 1:count in a
    separate text file */
    file open index_seq using $tmp/index_sequence_`randnum'.txt, write replace
    forval line = 1/`num_lines' {
      file write index_seq "`line'" _n
    }
    file close index_seq
    
    /* step 3: change input_txt to this sequence, so gnu_parallelize
    will read our 1:count .txt file line by line, and save our old
    input file to pass to the program call */
    local manual_inputs `input_txt'
    local input_txt $tmp/index_sequence_`randnum'.txt
    
    /* step 4: tell our temporary do file to read the manual_override
    program call using a specific index line */
    file write group_dofile "file open manual_lines using `manual_inputs', read" _n
    file write group_dofile "local index_counter = 1" _n
    file write group_dofile "file read manual_lines line" _n
    file write group_dofile "while r(eof)==0 {" _n
    file write group_dofile "if `index_counter"
    file write group_dofile "' == 1"
    file write group_dofile " {" _n
    file write group_dofile "local program_command `line"
    file write group_dofile "'" _n
    file write group_dofile "}" _n
    file write group_dofile "file read manual_lines line" _n
    file write group_dofile "local index_counter = `index_counter"
    file write group_dofile "' + 1" _n
    file write group_dofile "}" _n
    file write group_dofile "file close manual_lines" _n

    /* step 5: execute this manual program call  */
    file write group_dofile "`program_command"
    file write group_dofile "'" _n
    file write group_dofile "cap log close" _n
    file close group_dofile
    
    /* step 6: put the command to remove this temporary index text file into a local */
    local remove_manual_index "rm `input_txt'"
  }

  /* if we don't have manual override, we need to assemble the program
  call using shell variables from our input .txt file */
  if mi("`manual_input'") {
    
    /* having a first pre-comma (varlist or otherwise) shifts all the
    variables coming in from cat - so need two loops here */
    file write group_dofile "`program' " 
    if !mi("`pre_comma'") {

      /* all following options will be passed from the shell in
      sequence, as they are read from the text file. if there is a
      pre-comma argument, that will take the position `1' and the other
      options will start at `2' */
      local option_index 2

      /* write out any arguments before the options, which will be
      couched in the bash var `1' */
      file write group_dofile "\`1"
      file write group_dofile "'"
    }

    /* if no initial vars, start at 1 */
    else {
      local option_index 1
    }

    /* if there are options, add the comma. */
    if !mi("`options'") {
      file write group_dofile ","
    }

    /* now deal with the options */
    foreach option in `options' {

      /* write the option name */
      file write group_dofile " `option'("

      /* write the option variable index number */
      file write group_dofile "\``option_index'"
      file write group_dofile"'"
      file write group_dofile ")"

      /* bump up the index for the next loop through */
      local option_index = `option_index' + 1
    }

    /* if there are additional static options across all lines, add those here */
    file write group_dofile " `static_options'"
    
    /* now finish the program call line and close the script. */
    file write group_dofile _n
    file write group_dofile "cap log close" _n
    file close group_dofile
  }
  
  /* save working directory, then change to scratch */
  local workdir `c(pwd)'
  qui cd $tmp

  /* remove any previous iterations of the job log */
  cap rm $tmp/parlog.log

  /* handle the progress option */
  if !mi("`progress'") local progress "--progress"

  /* use the script we just wrote - in parallel! */
  /* "stata -e" means "run in batch mode and then exit stata */
//  !cat `input_txt' | parallel --resume-failed --joblog $tmp/parlog.log --retries `retries' --progress --gnu --delay 2.5 -j `max_jobs' "stata -e do parallelizing_dofile_`randnum' {}"
//  !cat `input_txt' | parallel --progress --gnu --delay 2.5 -j `max_jobs' "stata -e do parallelizing_dofile_`randnum' {}"
  !cat `input_txt' | parallel `progress' --gnu --delay 2.5 -j `max_jobs' "stata -e do parallelizing_dofile_`randnum' {}"

  /* remove our text file, if specified */
  if !mi("`rmtxt'") {
    rm `input_txt'
  }

  /* remove log and dofile, if specified */
  if mi("`diagnostics'") {
    rm parallelizing_dofile_`randnum'.do
  }

  /* remove the manual override's temporary index file - if not
  needed, this is just an empty local */
  //`remove_manual_index'
  
  /* change back to working directory */
  qui cd `workdir'

  /* CHECKING IF THE PARALLEL PROGRAMS RAN CORRECTLY */
      
  /* grep the log file for an error code, and fail if we triggered one */
  shell grep -B 5 "r([0-9]*);" $tmp/gnupar_`randnum'/log*.log   | sed -s "s#/scratch.*log_##g" | sed -s "s#_+\.log##g" >$tmp/error`randnum'.txt
  preserve

  /* look for error codes in the grep output */
  /* we use "file read" because import delimited wants to split on characters that can appear in the code */
  local error_found false
  cap file close logfile
  file open logfile using $tmp/error`randnum'.txt, read
  file read logfile line
  while r(eof)==0 {
    if regexm(`"`line'"', "r\([0-9]*\);") local error_found true
    file read logfile line
  }
  file close logfile

  /* if we found an error code */
  if "`error_found'" == "true" {
    di "--------------BEGIN ERRORS------------------"
    cat $tmp/error`randnum'.txt    
    di "--------------END ERRORS------------------"
    di "Error in at least one of the parallel scripts. See $tmp/gnupar_`randnum'/log*.log"
    /* if we want a notificiation, send the fail announcement */
    if !mi("`slackbot'") & !mi("$slackkey"){
      slack ":rotating_light: FAILURE: *`program'* Stata error code found in logs: $tmp/gnupar_`randnum' ... $S_TIME"
    }
    error 345

    }
    /* if we want a notificiation, send the success announcement */
    else {
      if !mi("`slackbot'") & !mi("$slackkey"){
        slack":not-a-dumpster-fire: GNUPAR job completed without Stata errors: *`program'* _(logs in $tmp/gnupar_`randnum')_ ... $S_TIME"
      }
    }
  restore

  /* if we made it this far, clear the log folder */
  cap rm -rf $tmp/gnupar_`randnum'

end
/* *********** END program gnu_parallelize ***************************************** */


  /**********************************************************************************/
  /* program extract_collapse_prog - assists gnu_parallelize                        */
/**********************************************************************************/
cap prog drop extract_collapse_prog
prog def extract_collapse_prog
      
  /* only need the program name (anything) and the location (string) */
  syntax anything, progloc(string) randnum(string)
      
  qui {

    /* step 1 - get the line number in the do file that corresponds with
    the start of the program. save to a temp file - not sure if there is
    another way to get stdout into a stata macro */
    !grep -n "cap prog drop `anything'" `progloc' | sed 's/^\([0-9]\+\):.*$/\1/'  | tee $tmp/linenums_`randnum'.txt

    /* step 2 - same for the end of the program. add a new line to the file */
    !grep -n "END program `anything'" `progloc' | sed 's/^\([0-9]\+\):.*$/\1/' >> $tmp/linenums_`randnum'.txt

    /* get the line nums into macros */
    file open lines_file using $tmp/linenums_`randnum'.txt, read
    file read lines_file line
    local first_line `line'
    file read lines_file line
    local last_line `line'
    local last_line_plus_1 = `last_line' + 1
    file close lines_file
    
    /* step 4 - extract the section of the do file between those line
    nums and save to $tmp/tmp_prog_extracted.do */
    !sed -n '`first_line',`last_line'p;`last_line_plus_1'q' `progloc' > $tmp/tmp_prog_extracted_`randnum'.do
    
    /* remove the temp file */
    !rm $tmp/linenums_`randnum'.txt
  }
end
/* *********** END program extract_collapse_prog ***************************************** */


/**********************************************************************************/
/* program prep_gnu_parallel_input_file - assists gnu_parallelize                 */
/**********************************************************************************/
cap prog drop prep_gnu_parallel_input_file
prog def prep_gnu_parallel_input_file
{

  /* we just need the output file name, and the list to be split into separate lines */
  syntax anything, in(string)

  /* open the output file for writing to */
  file open output_file using `anything', write replace

  /* tokenize the input var */
  tokenize `in'

  /* loop over all the individual inputs and write to a new line */
  while "`*'" != "" {
    file write output_file "`1'" _n
    macro shift
  }

  /* close the file handle */
  file close output_file

  /* print an output message */
  disp _n "input file for gnu_parallelize written to `anything'"
}
end
/* *********** END program prep_gnu_parallel_input_file ***************************************** */

/**********************************************************************************/
/* program lsm : list files in megabytes */
/***********************************************************************************/
cap prog drop lsm
prog def lsm
{
  shell ls -l --block-size=MB `1' `2' `3' `4' `5' `6'
}
end
cap prog drop lsh
prog def lsh
{
  shell ls -lh `1' `2' `3' `4' `5' `6'
}
end
/* *********** END program lsm / lsh ***************************************** */

/************************************************************************************/
/* program log_count : Store an observation of a variable count in an external file */
/*   - Used to make a log of where and how many observations we drop.               */
/************************************************************************************/
cap prog drop log_count
prog def log_count
{
  syntax using if, s(string) [sumvar(varname)]
  if mi("`sumvar'") {
    count `if'
    local n = `r(N)'
  }
  else {
    sum `sumvar' `if'
    local n = `r(N)' * `r(mean)'
  }
  append_to_file `using', s(`""`s'",`n'"')
}
end
/* *********** END program log_count ***************************************** */

/**********************************************************************************/
/* program log_drop : Insert description here */
/***********************************************************************************/
cap prog drop log_drop
prog def log_drop
{
  syntax varlist if using/, s(string)
  qui { 
    /* if `using' doesn't exit, throw an error */
    cap confirm file `using'
    if _rc {
      cap confirm file `using'.dta
      if _rc {
        display as error "log_drop requires file `using' to exist, and have correct keys."
        error 123
      }
    }
    
    /* first, store all these in an external dataset, with a reason in a string field */
    preserve
    keep `if'
    keep `varlist'
    count
    if `r(N)' > 0 {
      duplicates drop
      count
      local c = `r(N)'
      
      gen drop_reason = "`s'"
      merge 1:1 `varlist' using `using', nogen
      save `using', replace
    }
    
    restore
    
    /* second, drop these obs */
    noi di "Dropping `c' observations (`varlist') and logging to `using'..."
    drop `if'
  }
}
end
/* *********** END program log_drop ***************************************** */

/**********************************************************************************/
/* program make_con_names_unique : This program "fixes" the con names of the dozen
or so constituencies that have non-unique names within their states.

Currently it operates only on the Trivedi / con_key_2008 version of the constituency
names, and assumes that pc01_district_id exists, but if we see
other common versions of these names, we can easily extend it.

Requires a pc01_district_id or a district name

*/
/***********************************************************************************/
cap prog drop make_con_names_unique
prog def make_con_names_unique
{
  syntax varlist(min=1 max=1), [dist_name(string) dist_id(string)]
  tokenize `varlist'

  di "Adding 4-letter district prefixes to con names that are non-unique in each state..."
  
  if !mi("`dist_id'") {
    replace `1' = "east-gannavaram" if `1' == "gannavaram" & `dist_id' == "14"
    replace `1' = "kris-gannavaram" if `1' == "gannavaram" & `dist_id' == "16"
    
    replace `1' = "east-prathipadu" if `1' == "prathipadu" & `dist_id' == "14"
    replace `1' = "gunt-prathipadu" if `1' == "prathipadu" & `dist_id' == "17"
    
    replace `1' = "rajk-jetpur" if `1' == "jetpur" & `dist_id' == "09"
    replace `1' = "vado-jetpur" if `1' == "jetpur" & `dist_id' == "19"
    
    replace `1' = "gand-kalol" if `1' == "kalol" & `dist_id' == "06"
    replace `1' = "panc-kalol" if `1' == "kalol" & `dist_id' == "17"
    
    replace `1' = "bhav-mahuva" if `1' == "mahuva" & `dist_id' == "14"
    replace `1' = "sura-mahuva" if `1' == "mahuva" & `dist_id' == "22"
    
    replace `1' = "kach-mandvi" if `1' == "mandvi" & `dist_id' == "01"
    replace `1' = "sura-mandvi" if `1' == "mandvi" & `dist_id' == "22"
    
    replace `1' = "juna-mangrol" if `1' == "mangrol" & `dist_id' == "12"
    replace `1' = "sura-mangrol" if `1' == "mangrol" & `dist_id' == "22"
    
    replace `1' = "vell-tiruppattur" if `1' == "tiruppattur" & `dist_id' == "04"
    replace `1' = "siva-tiruppattur" if `1' == "tiruppattur" & `dist_id' == "23"

    // don't do tirupur -- it should actually be t-north and t-south
    //    replace `1' = "nilg-tiruppur" if `1' == "tiruppur" & `dist_id' == "11"
    //    replace `1' = "coim-tiruppur" if `1' == "tiruppur" & `dist_id' == "12"
  }
  
  if !mi("`dist_name'") {
    replace `1' = "east-gannavaram" if `1' == "gannavaram" & `dist_name' == "east godavari"
    replace `1' = "kris-gannavaram" if `1' == "gannavaram" & `dist_name' == "krishna"
    
    replace `1' = "east-prathipadu" if `1' == "prathipadu" & `dist_name' == "east godavari"
    replace `1' = "gunt-prathipadu" if `1' == "prathipadu" & `dist_name' == "guntur"
    
    replace `1' = "rajk-jetpur" if `1' == "jetpur" & `dist_name' == "rajkot"
    replace `1' = "vado-jetpur" if `1' == "jetpur" & `dist_name' == "chhota udepur"
    
    replace `1' = "gand-kalol" if `1' == "kalol" & `dist_name' == "gandhinagar"
    replace `1' = "panc-kalol" if `1' == "kalol" & `dist_name' == "panchmahal"
    
    replace `1' = "bhav-mahuva" if `1' == "mahuva" & `dist_name' == "bhavnagar"
    replace `1' = "sura-mahuva" if `1' == "mahuva" & `dist_name' == "surat"
    
    replace `1' = "kach-mandvi" if `1' == "mandvi" & `dist_name' == "kachchh"
    replace `1' = "sura-mandvi" if `1' == "mandvi" & `dist_name' == "surat"
    
    replace `1' = "juna-mangrol" if `1' == "mangrol" & `dist_name' == "junagadh"
    replace `1' = "sura-mangrol" if `1' == "mangrol" & `dist_name' == "surat"
    
    replace `1' = "vell-tiruppattur" if `1' == "tiruppattur" & `dist_name' == "vollore"
    replace `1' = "vell-tiruppattur" if `1' == "tiruppattur" & `dist_name' == "vellore"
    replace `1' = "siva-tiruppattur" if `1' == "tiruppattur" & `dist_name' == "sivaganga"
    
    // don't do tirupur -- it should actually be t-north and t-south
    //     replace `1' = "nilg-tiruppur" if `1' == "tiruppur" & `dist_name' == "the nilgiris"
    //     replace `1' = "coim-tiruppur" if `1' == "tiruppur" & `dist_name' == "coimbatore"
  }

  if mi("`dist_name'") & mi("`dist_id'") {
    disp as error "make_`1's_unique requires dist_name() or dist_id()"
    disp as error "syntax varlist(min=1 max=1), [dist_name(string) dist_id(string)]"
    error 12345
  }
}
end
/* *********** END program make_con_names_unique ***************************************** */

/********************************************************************************/
/* program tag_non_alpha : Tags string entries with non-alphanumeric characters */
/********************************************************************************/
cap prog drop tag_non_alpha
prog def tag_non_alpha
{
  syntax varlist, gen(string)
  tokenize `varlist'
  tempvar x
  tempvar y

  gen `x' = `1'
  gen `y' = ""
  count
  while `r(N)' != 0 {
    replace `y' = `x'
    replace `x' = regexr(`x', "[- +a-z0-9]+", "")
    count if `y' != `x'
  }
  gen `gen' = strlen(strtrim(`x')) > 0
}
end
/* *********** END program tag_non_alpha ***************************************** */

/***********************************************************************************/
/* program set_data_label : Insert description here */
/***********************************************************************************/
cap prog drop set_data_label 
prog def set_data_label
{
  syntax anything

  local anything = subinstr(`"`anything'"', `"""', "", .)      // fix syntax highlighting for emacs: `"""'
                            qui count
                            local r_N: di %10.0fc `r(N)'
                            local r_N = trim("`r_N'")
                            label data "`anything' (n=`r_N')"
  }
  end
  /* *********** END program set_data_label ***************************************** */

  /**********************************************************************************/
  /* program label_from_gdoc : Label variables from a google doc URL */
  /***********************************************************************************/
  cap prog drop label_from_gdoc
  prog def label_from_gdoc
  {
    syntax, docid(string) [sheet(string)]
    tempfile tempfile
    
    /* set a local to handle a request for a sheet other than the first (not yet implemented) */
    if !mi("`sheet'") {
      disp_nice "We haven't figured out how to make this work with a sheet option :-("
      error 150
    }

    /* set up the call to CURL and run it */
    local url "https://docs.google.com/spreadsheets/d/`docid'/gviz/tq?tqx=out:csv"
    local curl_cmd "curl -s -d /dev/null https://docs.google.com/spreadsheets/d/`docid'/export?exportFormat=csv >`tempfile'"
    shell `curl_cmd'

    /* loop over the generated dictionary line by line */
    cap file close fh
    file open fh using `tempfile', read
    file read fh line
    while r(eof) == 0 {

      /* if the first character is a comment, skip this one */
      if substr("`line'", 1, 1) == "#" {
        file read fh line
        continue
      }
            
      /* split the line on the comma into a variable and variable label */
      local spacepos = strpos("`line'", ",")
      local varname = substr("`line'", 1, `spacepos' - 1)
      local varlabel = substr("`line'", `spacepos' + 1, .)
      
      /* label the variable */
      cap label var `varname' "`varlabel'"

      /* get the next line in the file */
      file read fh line
    }
    cap file close fh
  }
  end
  /* *********** END program label_from_gdoc ***************************************** */

  /**********************************************************************************/
  /* program useshrug : Rapidly open the shrug */
  /***********************************************************************************/
  cap prog drop useshrug
  prog def useshrug
  {
    use shrid pc11_pca_tot_p using $shrug/data/shrug_pc11_pca, clear
  }
  end
  /* *********** END program useshrug ***************************************** */

  /*************************************************************************/
  /* program presave_clean : Compress, clear data description, drop notes  */
  /*************************************************************************/
  cap prog drop presave_clean
  prog def presave_clean
  {
    label data ""
    notes drop _all
    compress
  }
  end
  /* *********** END program presave_clean ***************************************** */

  /***********************************************************************/
  /* program strip_special_chars: Strips special chars from a string   */
  /***********************************************************************/
  cap prog drop strip_special_chars
  prog def strip_special_chars
  {
    syntax varname(min=1 max=1), [replace]
    tokenize `varlist'
    if mi("`replace'") {
      disp as error "Please specify 'replace' or modify this program to work with generate."
      error 543
    }
    forval i=128/255 {
      qui replace `1' = subinstr(`1', `"`=char(`i')'"', "", .)
    }
  }
  end
  /** END program strip_special_chars ***********************************/

  /*************************************************************************************************/
  /* program create_unique_id_dataset: save a copy of the data after dropping obs w/non-unique ids */
  /*
  - if using is specified, opens the using dataset. Otherwise uses currently open dataset.
  - Only current approach is ddrop style -- both sides of pair are gone.
  - Could add option to keep one of each set if we wanted to                                   */
  /*************************************************************************************************/
  cap prog drop create_unique_id_dataset
  prog def create_unique_id_dataset
  {
    syntax [using/], KEYs(string) save(string)

    preserve
    if !mi("`using'") {
      use `using', clear
    }
    
    /* tag observations that are non-unique on keys */
    tempvar dup
    duplicates tag `keys', gen(`dup')

    /* save the data that are unique */
    savesome if `dup' == 0 using `save', replace

    /* restore original status */
    restore
  }
  end
  /** END program create_unique_id_dataset *********************************************************/

  /******************************************************************************************/
  /* program drop_from_list: drop a set of rows with fields matching a hand-made CSV list   */
  /* The drop file .csv needs a column titled "drop" -- we drop all
  rows if this field is non-empty */
  /******************************************************************************************/
  cap prog drop drop_from_list
  prog def drop_from_list
  {
    syntax varlist using/

  qui {
    /* convert the CSV to a .dta that we can merge */
    preserve
    insheet using `using', clear names
    tempfile droplist
    save `droplist', replace
    restore
    
    /* merge the data to the droplist on varlist */
    merge m:1 `varlist' using `droplist', gen(_m_drop) keep(master match)
    
    /* report drop numbers */
    qui count if _m_drop == 3 & !mi(trim(drop))
    if (`r(N)' > 0) {
      noi di "Dropping `r(N)' rows that matched the droplist."
      drop if _m_drop == 3 & !mi(trim(drop))
    }
    drop _m_drop drop
  }
  }
  end
  /** END program drop_from_list ********************************************************/


  /**********************************************************************************************/
  /* program show_coef : show a coef from a regression that was just run */
  /***********************************************************************************************/
  cap prog drop show_coef
  prog def show_coef, rclass
  {
    syntax varlist, [title(string) s(real 40) absorb(varlist) disponly]

    tokenize `varlist'
    local xvar = "`1'"

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
  /* *********** END program show_coef **********************************************************************************************/

  /**************************************************************/
  /* program dsave: save with DDL rules: require a unique key   */
  /**************************************************************/
  cap prog drop dsave
  prog def dsave
  {
    syntax anything, [key(varname) replace emptyok]

    if mi("`key'") {
      di "Error: Every save needs a unique key to be specified."
      error 345
    }
    
    cap is_unique `key'
    if _rc {
      di "Error: `key' is not unique. All saves require a unique key to be specified"
      error 345
    }

    order `key'
    save `anything', `replace' `emptyok'
  }
  end
  /** END program dsave *****************************************/

  /********************************************************************************/
  /* program longtable: Shows a oneway frequency table with non-truncated names   */
  /********************************************************************************/
  cap prog drop longtable
  prog def longtable
  {
    syntax varlist [aweight pweight] [if/]
    capdrop __group
    qui {
      
      /* create weighting local macro */
      if !mi("`weight'") {
        local wt [`weight'`exp']
      }
      /* set if to 1 if missing */
      if mi("`if'") local if 1
      
      /* create a group identifier and get the max */
      tokenize `varlist'
      egen __group = group(`1') if `if'
      sum __group, meanonly
      local max = `r(max)'
  
      /* get the string length */
      tempvar t
      gen `t' = strlen(`1') if `if'
      sum `t'
      local len = `r(max)'
      drop `t'
  
      /* write table header */
      noi di %`len's "`1'" "   | Count"
      noi di %`len's "-------------------------------------------------------------------------"
      
      /* loop over all entries */
      forval i = 1/`max' {
  
        /* count the number of appearances for this entry */
        count if __group == `i' & `if'
        local count = `r(N)'
        
        /* get the string value for this entry */
        tempvar tmp
        gen `tmp' = _n if __group == `i'
        sum `tmp', meanonly
        local str = `1'[`r(min)']
        drop `tmp'
  
        /* display the result */
        noi di %`len's "`str'" "   |  "  `r(N)'
      }
      drop __group
    }
  }
  end
  /** END program longtable *******************************************************/

  /****************************************************************************************/
  /* program stc: short version of store_tex_constant   */
  /****************************************************************************************/
  cap prog drop stc
  prog def stc
    syntax, file(passthru) idshort(passthru) idlong(passthru) value(passthru) desc(passthru)
    store_tex_constant, `file' `idshort' `idlong' `value' `desc'
  end
  /** END program stc *******************************************************/
      
  /****************************************************************************************/
  /* program store_tex_constant: Store a value in a table for importing into a tex file   */
  /****************************************************************************************/
  cap prog drop store_tex_constant
  prog def store_tex_constant
  {
    syntax, file(string) idshort(string) idlong(string) value(real) desc(string) 
  
    /* create a string for use in insert_into_file() with both ids and the description */
    local key `idlong'
    local value `idshort',`value',`desc'

    /* create the CSV and TEX files-- assume the same stub within a project */
    local csvfile `file'.csv
    local texfile `file'.tex
  
    /* break if description includes commas */
    if strpos("`desc'", ",") {
      display as error "store_tex_constant error: Description cannot include commas."
      error 765
    }
    
    /* IF CSV FILE EXISTS, CHECK IF LONG OR SHORT ID IS ALREADY THERE AND CONTRADICTORY */
    cap confirm file `csvfile'
    if !_rc {
  
    /* Use grep to pull just the line with this string in it from the CSV */
      tempfile foo
      shell grep ^`idlong', `csvfile' >`foo'
      shell grep ,`idshort', `csvfile' >>`foo'
      cat `foo'
      
      /* read the one-line input file (and do nothing if the file is empty) */
      cap file close fh
      file open fh using `foo', read
      file read fh line
      while r(eof) == 0 {
    
        /* pull the first delimiter from the line */
        local file_idlong = substr("`line'", 1, strpos("`line'", ",") - 1)
//        di "file_idlong: `file_idlong'"
        
        /* pull the second delimiter from the line */
        local rest_of_line = substr("`line'", strpos("`line'", ",") + 1, .)
//        di "rest_of_line: `rest_of_line'"
        local file_idshort = substr("`rest_of_line'", 1, strpos("`rest_of_line'", ",") - 1)
//        di "file_idshort: `file_idshort'"
    
        /* assert that the idshorts match and we aren't creating a conflict */
        cap assert "`file_idshort'" == "`idshort'" & "`file_idlong'" == "`idlong'"
        if _rc {
          display as error "store_tex_constant error: `idshort',`idlong' was requested, but `file_idshort',`file_idlong' already exists in file"
          file close fh
          error 765
        }
    
        /* if this doesn't result in eof, the grep got multiple lines-- which is bad */
        file read fh line
      }
      file close fh
    }
    
    /* insert the string into the CSV */
    insert_into_file using `csvfile', key(`key') value(`"`value'"') 

    /* REGENERATE THE LATEX INPUT FILE */
  
    /* open the CSV input file and the TEX output file */
    /* note: it would be easier to import the CSV in stata, but expensive to preserve each time we call this */
    confirm file `csvfile'
    cap file close fout
    cap file close fintex
    file open fout using `texfile', write replace
    file open fintex using `csvfile', read
  
    /* loop over all lines in the CSV */
    file read fintex line
    while r(eof) == 0 {
  
      /* all the latex file needs are the short id and the number-- fields 2 and 3 */
      local comma1 = strpos("`line'", ",")
      local rest   = substr("`line'", `comma1' + 1, .)
  
      local comma2 = strpos("`rest'", ",")
      local shortid = substr("`rest'", 1, `comma2' - 1)
      local rest   = substr("`rest'", `comma2' + 1, .)
  
      local comma3 = strpos("`rest'", ",")
      local value  = substr("`rest'", 1, `comma3' - 1)
      
      /* write the latex line */
      file write fout "\newcommand{\\`shortid'}{`value'}" _n
  
      /* read the next line from the file */
      file read fintex line
    }  
    file close fout
    file close fintex
  }
  end
  /** END program store_tex_constant ******************************************************/

  /****************************************************************************************/
  /* program store_constant: same idea as store tex constant, but without the tex part. Allows a category for sorting. */
  /****************************************************************************************/
  cap prog drop store_constant
  prog def store_constant
  {
    syntax using/, value(string) desc(string) [category(string) format(string)]

    /* update the value to the format if applicable */
    if !mi("`format'") & "`format'" != "string" {
      local value: di `format' (`value')
    }
          
    /* create a string for use in insert_into_file() with both ids and the description */
    local key `category',`desc'
    local value `value'

    /* create the CSV output filename */
    local csvfile `using'.csv
  
    /* break if category or description includes commas, since we want to use it as a key */
    if strpos("`category'", ",") | strpos("`desc'", ",") | strpos("`desc'", "(") {
      display as error "store_constant error: Category and description cannot include special characters."
      error 765
    }
    
    /* insert the string into the CSV, replacing if it already exists */
    insert_into_file using `csvfile', key(`key') value(`"`value'"') 
  }
  end
  /** END program store_constant ******************************************************/
      
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
  
  
  /**********************************************************************************/
  /* program get_var_labels : Labels all variables from a source file               */
  /***********************************************************************************/
  cap prog drop get_var_labels
  prog def get_var_labels
  {
    do ~/ddl/tools/do/label_vars
  }
  end
  /* *********** END program get_var_labels ***************************************** */
  
  
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
  
  
  /**********************************************************************************/
  /* program drop_prefix : Insert description here */
  /***********************************************************************************/
  cap prog drop drop_prefix
  prog def drop_prefix
  {
    syntax, [EXCept(varlist)]
    local x ""
  
    foreach i of varlist _all {
      local x `x' `i'
      continue, break
    }
  
    local prefix = substr("`x'", 1, strpos("`x'", "_"))
  
    /* do it var by var instead of using renpfix so can pass exception parameters */
    local line = `"renpfix `prefix' """'
    di `"`line'"'
    `line'
  
    /* rename exception list */
    if "`except'" != "" {
      foreach var in `except' {
        local newvar = substr("`var'", strpos("`var'", "_") + 1 ,.)
        ren `newvar' `prefix'`newvar'
      }
    }
  
  }
  end
  /* *********** END program drop_prefix ***************************************** */
  
  
  /**********************************************************************************/
  /* program lf : Better version of lf */
  /***********************************************************************************/
  cap prog drop lf
  prog def lf
  {
    syntax anything
    d *`1'*, f
  }
  end
  /* *********** END program lf ***************************************** */
  
  
  /**********************************************************************************/
  /* program make_binary: make a numeric binary variable out of string data */
  /***********************************************************************************/
  cap prog drop make_binary
  prog def make_binary
  {
    syntax varlist, one(string) zero(string) [label(string)]
  
    /* cycle over varlist, replacing strings with 1s and 0s */
    foreach var in `varlist' {
      replace `var' = trim(lower(`var'))
      assert inlist(`var', "`one'", "`zero'", "")
      replace `var' = "1" if `var' == "`one'"
      replace `var' = "0" if `var' == "`zero'"
    }
  
    /* destring variables */
    destring `varlist', replace
  
    /* create value label */
    if !mi("`label'") {
      label define `label' 1 "`one'" 0 "`zero'", modify
      label values `varlist' `label'
    }
  
  }
  end
  /* *********** END program make_binary ***************************************** */
  
  
  /**********************************************************************************************/
  /* program binscatter_rd : Produce binscatter graphs that absorb variables on the Y axis only */
  /**********************************************************************************************/
  cap prog drop binscatter_rd
  prog def binscatter_rd
  {
    syntax varlist [aweight pweight] [if], [RD(passthru) NQuantiles(passthru) XQ(passthru) SAVEGRAPH(passthru) REPLACE LINETYPE(passthru) ABSORB(string) XLINE(passthru) XTITLE(passthru) YTITLE(passthru) BY(passthru)]
    cap drop yhat
    cap drop resid
  
    tokenize `varlist'
  
    // Create convenient weight local
    if ("`weight'"!="") local wt [`weight'`exp']

    reg `1' `absorb' `wt' `if'
    predict yhat
    gen resid = `1' - yhat
  
    local cmd "binscatter resid `2' `wt' `if', `rd' `xq' `savegraph' `replace' `linetype' `nquantiles' `xline' `xtitle' `ytitle' `by'"
    di `"RUNNING: `cmd'"'
    `cmd'
  }
  end
  /* *********** END program binscatter_rd ***************************************** */
  
  
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
  
  
  
  
  /********************************************************************/
  /* program appendmodels : append stored estimates for making tables */
  /********************************************************************/
  
  /* version 1.0.0  14aug2007  Ben Jann*/
  
  cap prog drop appendmodels
  prog def appendmodels, eclass
  {
    // using first equation of model version 8
    syntax namelist
    tempname b V tmp
    foreach name of local namelist {
      qui est restore `name'
      mat `tmp' = e(b)
      local eq1: coleq `tmp'
      gettoken eq1 : eq1
      mat `tmp' = `tmp'[1,"`eq1':"]
      local cons = colnumb(`tmp',"_cons")
      if `cons'<. & `cons'>1 {
        mat `tmp' = `tmp'[1,1..`cons'-1]
      }
      mat `b' = nullmat(`b') , `tmp'
      mat `tmp' = e(V)
      mat `tmp' = `tmp'["`eq1':","`eq1':"]
      if `cons'<. & `cons'>1 {
        mat `tmp' = `tmp'[1..`cons'-1,1..`cons'-1]
      }
      capt confirm matrix `V'
      if _rc {
        mat `V' = `tmp'
      }
      else {
        mat `V' = ( `V' , J(rowsof(`V'),colsof(`tmp'),0) ) \ ( J(rowsof(`tmp'),colsof(`V'),0) , `tmp' )
      }
    }
  
    local names: colfullnames `b'
    mat coln `V' = `names'
    mat rown `V' = `names'
    eret post `b' `V'
    eret local cmd "whatever"
  }
  end
  
  /* *********** END program appendmodels *****************************************/
  
  
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
  /* program insert_est_into_file : *Inserts* a regression estimate to a csv file   */
  /**********************************************************************************/
  cap prog drop insert_est_into_file
  prog def insert_est_into_file
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
  /* *********** END program insert_est_into_file ***************************************** */

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
  /* program gen_rd_bins : regression discontinuity with binned data                */
  /**********************************************************************************/
  cap prog drop gen_rd_bins
  prog def gen_rd_bins
  {
    /* N is number of bins, gen is the new variable name, cut breaks
    bins into two sections (e.g. positive and negative). e.g. cut(0)
    will proportionally split desired bins into positive and negative,
    with 0 inclusive in positive bins. */
    syntax varlist(min=1 max=1), gen(string) [n(real 20) Cut(integer -999999999999) if(string)]
  
    cap drop rd_tmp_id
    
    /* if there is an `if' statement, we need a preserve/restore, and to
    execute the condition. */
    if !mi(`"`if'"') {
      gen rd_tmp_id = _n
      preserve
      foreach cond in `if' {
        `cond'
      }
    }
  
    /* get our xvar into a more legible macro */
    local xvar `varlist'
  
    /* create empty index var */
    cap drop `gen'
    gen `gen' = .
  
    /* calculate the proportionate number of bins above/below `cut',
    which defaults to -99999999999 - a value which just about guarantees
    all obs will be in the `above' split - so will divide into bins
    normally. */
  
    /* count below cut */
    count if !mi(`xvar')  & `xvar' < `cut'
    local below_count = `r(N)'
  
    /* count above cut, inclusive */
    count if !mi(`xvar') & `xvar' >= `cut'
    local above_count = `r(N)'
  
    /* number of below-cut groups, then above */
    local below_num_bins = floor((`below_count'/_N) * `n')
    local above_num_bins = `n' - `below_num_bins'
  
    /* number of obs in each group */
    local below_num_obs = floor(`below_count'/`below_num_bins')
    local above_num_obs = floor(`above_count'/`above_num_bins')
  
    /* rank our obs above and below cut */
    cap drop below_rank above_rank
    egen below_rank = rank(-`xvar') if `xvar' < `cut' & !mi(`xvar'), unique
    egen above_rank = rank(`xvar') if `xvar' >= `cut' & !mi(`xvar'), unique
  
    /* split into groups above/below cut */
    foreach side in above below {
  
      /* set a multiplier - negative bins will be < `cut', positive
      will be above */
      if "`side'" == "below" {
        local multiplier = -1
      }
      else if "`side'" == "above" {
        local multiplier = 1
      }
  
      /* loop over the number of bins either above or below, to
      reclassify our index */
      forval i = 1/``side'_num_bins' {
  
        /* get start and end of this specific bin (obs count) */
        local cut_start = (`i' - 1) * ``side'_num_obs'
        local cut_end = `i' * ``side'_num_obs'
  
        /* replace our bin categorical with the right group */
        replace `gen' = `multiplier' * (`i') if inrange(`side'_rank, `cut_start', `cut_end')
      }
    }
  
    /* now the restore and merge, if we have a subset condition */
    if !mi(`"`if'"') {
  
      /* save our new data */
      save $tmp/rd_bins_tmp, replace
  
      /* get our original data back, and merge in new index */
      restore
      merge 1:1 rd_tmp_id using $tmp/rd_bins_tmp, keepusing(`gen') nogen
      drop rd_tmp_id
  
      /* remove our temporary file */
      rm $tmp/rd_bins_tmp.dta
    }
  }
  end
  /* *********** END program gen_rd_bins ***************************************** */
  
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
  /* program add_to_global : Shortcut variable [or anything] to a global declaration*/
  /* add_to_global FOO v1 v2
         is equivalent to:
     global FOO $FOO v1 v2                                                          */
  /***********************************************************************************/
  cap prog drop add_to_global
  prog def add_to_global
  {
    syntax anything
    tokenize `anything'
    global `1' ${`1'} `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12'
    if !mi("`13'") {
      di "add_to_global only works with 12 vars. Sorry! Modify it to take any number in include.do."
      error 123
    }
  }
  end
  /* *********** END program add_to_global ***************************************** */
  
  /************************************************************/
  /* program mccrary - clean wrapper for dc_density function  */
  /************************************************************/
  cap prog drop mccrary
  prog def mccrary
  {
    syntax varlist [if], BReakpoint(real) [b(real 0) h(real 0) name(passthru) graphregion(passthru) qui graph xtitle(passthru) ytitle(passthru) xlabel(passthru) ylabel(passthru)]
    if "`graph'" == "graph" {
      local nograph = ""
    }
    else {
      local nograph = "nograph"
    }
    `qui' {
      dc_density `varlist' `if', breakpoint(`breakpoint') h(`h') b(`b') generate(Xj Yj r0 fhat se_fhat) `nograph' `name' `graphregion' `xtitle' `ytitle' `xlabel' `ylabel'
      drop Xj Yj r0 fhat se_fhat
    }
  }
  end
  /* *********** END program mccrary ************************* */
  
      
/**********************************************************************************/
/* program reconf : Insert description here */
/***********************************************************************************/
cap prog drop reconf
prog def reconf
  shell cd ~/ddl/tools; git pull
  shell cd ~/ddl/config; git pull
  do ~/ddl/config/config
end
/* *********** END program reconf ***************************************** */

/*****************************************************************************/
/* program store_depvar_mean : Store mean dependent variable after an estout */
/*****************************************************************************/
cap prog drop store_depvar_mean
prog def store_depvar_mean
  syntax anything, format(string)
  qui sum `e(depvar)' if e(sample)
  local x: di `format' (`r(mean)')
  tokenize `anything'
  c_local `1' `x'
end
/* *********** END program store_depvar_mean ***************************************** */
      
  /*****************************************************************************************************/
  /* program convert_ids: Convert easily back and forth between identifiers using a key, and write out */
  /*****************************************************************************************************/

  ////TEST:
  //use pc11_state_id pc11_district_id using $keys/lgd_pc11_district_key_weights.dta, clear
  ////keep if inlist(lgd_district_id, "175", "640", "185")
  ///* 179 and 158 compound match to lgd_district_id 175, 185, and 640 */
  //keep if inlist(pc11_district_id, "179", "158")
  //duplicates drop
  //gen meanvar = 1 if pc11_district_id == "179"
  //replace meanvar = 2 if pc11_district_id == "158"
  //gen sumvar = mean
  //global meanvar_ mean
  //global sumvar_ sum
  ///* as of may 2020, weights for these obs are as follows: */
  //+-----------------------------------------------------------------+
  //| lgd_st~d   lgd_di~d   pc11_s~d   pc11_d~d   pc11_l~p   lgd_pc~p |
  //|-----------------------------------------------------------------|
  //|       09        175         09        158   .8742403          1 |
  //|       09        185         09        179   .6276585          1 |
  //|       09        640         09        158   .1257596   .2242026 |
  //|       09        640         09        179   .3723415   .7757974 |
  //+-----------------------------------------------------------------+
  ///* so means going from pc11 to lgd, lgd 175 should equal 2, lgd 185 should equal 1, and lgd 640 should be a weighted average */
  ///* this average would be: 2 * (.1257596 / (.1257596 + .3723415)) + 1 * (.3723415 / (.1257596 + .3723415)) = 1.25247806118 */
  ///* for sums, we should get: 175 = .8742403 * 2; 185 = .6276585 * 1; 640 = .1257596 * 2 + .3723415 * 1 */
  //convert_ids, from_ids(pc11_state_id pc11_district_id) to_ids(lgd_state_id lgd_district_id) key($keys/lgd_pc11_district_key_weights.dta) weight_var(pc11_lgd_wt_pop)
  //assert inrange(sumvar, 1.747, 1.749) if lgd_district_id == "175"
  //assert inrange(sumvar, .626, .628) if lgd_district_id == "185"
  //assert inrange(sumvar, .622, .624) if lgd_district_id == "640"
  //assert meanvar == 2 if lgd_district_id == "175"
  //assert meanvar == 1 if lgd_district_id == "185"
  //assert inrange(meanvar, 1.251, 1.253) if lgd_district_id == "640"

  cap prog drop convert_ids
  prog def convert_ids
    {
      /* NOTE: this program requires globals for each var e.g. $`varname'_ */
      syntax, FROM_ids(string) TO_ids(string) Key(string) WEIGHT_var(string) [VARiables(varlist) Level(string) Globals_from_csv(string) METAdata_urls(string) labels long(string)]

      /* pull down metadata csv and extract globals, if specified */
      if !mi("`metadata_urls'") {
        foreach url in `metadata_urls' {
          shell wget --no-check-certificate --output-document=$tmp/metadata_scrape.csv '`metadata_urls''
          qui aggmethod_globals_from_csv $tmp/metadata_scrape.csv, `labels'
        }
      }
      
      /* load globals, if specified */
      if !mi("`globals_from_csv'") qui aggmethod_globals_from_csv `globals_from_csv'
      
      /* set varlist if not specified */
      if mi("`variables'") {
        unab variables : _all
      }

      /* remove identifiers from varlist */
      local variables : list variables - from_ids

      /* assert globals exist for all vars other than ID */
      disp_nice "Globals in the form of \$[varname]_ must be set for all collapse (non-id) vars"
      foreach var in `variables' {
        if mi("${`var'_}") {
          disp "WARNING: Missing global - `var' will be ignored and dropped from this transformation" _n
          local variables : list variables - var
        }
        else disp "`var' aggregation type set to: ${`var'_}"
      }

      /* save mean values for each variable into locals for validation */
      foreach var in `variables' {
        qui sum `var'
        local `var'_o = `r(mean)'
      }
      
      /* if we're unique on ids ("long" option not specified), merge in specified weights directly */
      if mi("`long'") {
        isid `from_ids'
        qui merge 1:m `from_ids' using `key'

        /* make sure merge is decent */
        qui count
        local tot_ct `r(N)'
        qui count if _merge == 3
        if `r(N)' / `tot_ct' < 0.9 disp "WARNING: merge rate to `key' is less than 90%"
        qui keep if _merge == 3
        drop _merge
      }
      else {
        disp _n"using joinby as data are in long format..."
        qui joinby `from_ids' using `key'            
      }
          
      /* initialize a collapse string for instances where pc11 dists are aggregated to LGD (or vice versa) */
      local collapse_string
      
      /* initialize a list of mean variables that will need postprocessing */
      local mean_vars
      
      /* conduct the weighting for all variables, using externally-defined globals. loop over calculated vars */
      foreach var in `variables' {
      
        /* extract aggregation method into its own local */
        local clean_method = lower("${`var'_}")

        /* aggregation type can be [min, max, mean, count, sum]. sums get iweights. */
        if inlist("`clean_method'", "sum") {

          /* add to collapse string - these will be weighted */
          local collapse_string `collapse_string' (`clean_method') `var'
            }

        /* counts just get a binary yes/no indicating a nonmissing value; these should be 1/0 */
        else if inlist("`clean_method'", "count") {
          cap assert inlist(`var', 0, 1)
          if _rc {
            di "Error: `var' is specified as a count var - these should be only zero or one. If you wish to sum a numeric var, change the aggregation method to 'sum'"
            error 345
          }
          local collapse_string `collapse_string' (first) `var'        
        }

        /* means are a bit different. we can population-weight merges, but not splits. */
        else if inlist("`clean_method'", "mean") {
          
          /* take first value for 1:1s and splits */
          local collapse_string `collapse_string' (first) `var'

          /* create temp var for merges. identify the merges by finding duplicate "to" IDs */
          qui dtag `to_ids' `long'
          qui gen _`var' = `var' if dup > 0
          local mean_vars `mean_vars' `var'
          drop dup
          
          /* weight merges only (not splits), and add to collapse call string */
          local collapse_string `collapse_string' (mean) _`var'
        }

        /* for others e.g. min/max, take first value */
        else {
          local collapse_string `collapse_string' (first) `var'
        }    
      }    
      
      /* collapse to specified IDs. use iweights; aweights normalize
      group weights to sum to Ni, which we don't want */
      collapse_save_labels
      collapse `collapse_string' [iw = `weight_var'], by(`to_ids' `long')
      collapse_apply_labels
              
      /* execute replacements for merged means */
      foreach var in `mean_vars' {
        qui replace `var' = _`var' if !mi(_`var')
        drop _`var'
      }
      
      /* check old and new values */
      foreach var in `variables' {    
        qui sum `var'
        local newmean = `r(mean)'
        if !inrange(`newmean', ``var'_o' * .8, ``var'_o' * 1.2) disp "WARNING: `var' has changed more than 20% from original value (``var'_o' -> `newmean')"
      }
      
      /* set varlabels if desired */
      if !mi("`labels'") {
        foreach var in `variables' {    
        label var `var' "${`var'_label}"
        }
      }

      /* add dataset note */
      note: Data programmatically transformed from '`from_ids'' to '`to_ids''
    }
  end
  /* *********** END program convert_ids ***************************************** */


  /******************************************************************************************************/
  /* program aggmethod_globals_from_csv: pull variable collapse type globals necessary for convert_ids  */
  /******************************************************************************************************/

  /* could rework this to use frames to avoid preserve/restore, but
  dont' want stata16 dependency */
  cap prog drop aggmethod_globals_from_csv
  prog def aggmethod_globals_from_csv
  {
    /* infile is the only argument */
    syntax anything [, labels]

    /* preserve data in memory */
    preserve
    
    /* print infile requirements */
    disp _n "NOTE: this program requires a .csv file with variable name and aggregationMethod variables" _n
    
    /* rename arg for clarity */
    local infile `anything'
    
    /* read in the file */
    disp "Reading variable definitions from `infile'" _n
    qui import delimited using `infile', clear

    /* target variable name and aggregation method for adding to globals, as well as varlabels */
    keep variablename aggregationmethod label
    forval i = 1/`=_N' {
      local var = variablename[`i']
      local var = strtrim("`var'")
      local aggmethod = aggregationmethod[`i']
      if !mi("`aggmethod'") global `var'_ `aggmethod'
      disp "global set: \$`var'_ = `aggmethod'"
      if !mi("`labels'") {
        if !mi("`var'") {
          local l = label[`i']
          global `var'_l `l'
        }
      }
    }
    restore
  }
  end
  /* *********** END program aggmethod_globals_from_csv ***************************************** */

/**********************************************************************************/
/* program fail : Fail with an error message */
/***********************************************************************************/
cap prog drop fail
prog def fail
  syntax anything
  display as error "`anything'"
  error 345
end
/* *********** END program fail ***************************************** */

  /******************************************************************************************************/
  /* program download_gsheet: Download a google sheet to either CSV or XLSX  */
  /******************************************************************************************************/

  cap prog drop download_gsheet
  prog def download_gsheet
  {
    /* target output file is the primary option */
    /* e.g.: download_gsheet $tmp/somefile.csv, key(LONG GSHEET PUBLIC KEY HERE) */
    syntax anything, Key(string)

    /* excise filetype from output file string */
    if regexm("`anything'",".csv$") local ftype csv
    if regexm("`anything'",".xlsx$") local ftype xlsx
    if !regexm("`anything'",".xlsx$") & !regexm("`anything'",".csv$") {
      disp "output filetypes must be either csv or xlsx"
      exit
    }
          
    /* execute the `curl` call. this requires a public link. -s option
    is silent; -L is to follow http redirects; -o sets output file
    location. i've turned off silenced execution so the user knows
    download is proceeding.*/
    shell curl -L -o `anything' "https://docs.google.com/spreadsheets/d/`key'/export?exportFormat=`ftype'"
  }
  end
  /* *********** END program download_gsheet ***************************************** */

  /******************************************************************************************************/
  /* program pyscript: Run external python script without silent failures.   */
  /******************************************************************************************************/
  /* all python scripts should be run this way, e.g. pyscript $tmp/example.py */
  cap prog drop pyscript
  cap prog def pyscript
  {
//    /* input is py script location, with possible arguments */
//    /* e.g. pyscript $tmp/example.py */
//    /* or. pyscript $tmp/example.py -opt1 optiontext */
//    /* or. pyscript $tmp/example.py option1 option2 */
//    /* using argparse in your python script for option handling is recommended */
//    syntax anything
//
//    /* replace relative paths with absolute paths (this fails with trailing tildes in filenames)*/
//    local homedir : env HOME
//    local anything : subinstr local anything "~/" "`homedir'/", all
//
//    /* need to construct the subprocess call by tokenizing all
//    arguments. subprocess can handle arguments but requires that they're
//    in quotations and separated by commas. */
//    tokenize `anything'
//    local fun_call = "'`1''"
//    mac shift
//    while (!mi("`1'")) {
//      local fun_call = "`fun_call', '`1''"
//      mac shift
//    }
//    
//    /* note: python calls *cannot* be indented! do not change the indentation of this line! */
//python: import subprocess; import os; subprocess.check_output(['python', `fun_call'])
        disp_nice "this function is deprecated: use stata's 'python script' (see DDL tools wiki)"
  }
  end
  /* *********** END program pyscript ***************************************** */
      
  /******************************************************************************************************/
  /* program pyfunc: Run externally defined python function without silent failures.   */
  /******************************************************************************************************/
  /* note: pyfunc exists in ~/ddl/tools/do/ado/, which is auto-loaded on polaris */
  /****** END program pyfunc ****************/

  /**********************************************************************************/
  /* program interaction_term : this program interacts a varlist with a set of
  variables. the set of varibles interacted can be as long as needed, meaning the 
  function can produce simple, triple, quadruple, etc. interactions

  varlist: list of root variables to be interacted
  interact: a varlist to be interacted with each root variable

  Examples:
  interaction_term ed1 ed2 ed3, interact(scst)
    --> ed1_scst ed2_scst ed3_scst

  interaction_term ed1 ed2 ed3, interact(scst slum)
    --> ed1_scst_slum ed2_scst_slum ed3_scst_slum
  */
  /***********************************************************************************/
  cap prog drop interaction_term
  prog def interaction_term
  {
    syntax varlist, interact(varlist)

    /* cycle through each primary variable that will be interacted */
    foreach var1 in `varlist' {

      /* use the var1 name to initiate the new name of the interaction term */
      local new_var `var1'

      /* create a __temp variable to hold the interaction term */
      gen __temp = `var1'
    
      /* cycle through each variable to be interacted with the primary variable */
      foreach i in `interact' {
      
        /* add this variable to the interaction term name */
        local new_var `new_var'_`i'
      
        /* multiply the interaction term by this variable */
        replace __temp = __temp * `i'
      }

      /* name the interaction term with the concatenated name */
      ren __temp `new_var'

    }
  }
  end
  /* *********** END program interaction_term ***************************************** */

/*********************************************************/
/* program slack: send a message to user's slack DM   */
/*********************************************************/
cap prog drop slack
prog def slack
  syntax anything
  shell curl -X POST -H 'Content-type: application/json' --data '{"text":"`anything'"}' https://hooks.slack.com/services/$slackkey
end
/** END program slack ************************************/


/*************************************************************************************/
/* program distinct_within_group: check unique values of a variable within a group   */
/*************************************************************************************/
cap prog drop distinct_within_group
prog def distinct_within_group
  {
    syntax varlist(min = 1 max = 1), group(name)
    bys `group' `varlist': gen nvals = _n == 1 
    by `group': replace nvals = sum(nvals)
    by `group': replace nvals = nvals[_N]
  }
end
/************* END program distinct_within_group ************************************/

    
  do ~/ddl/tools/do/dc_density.do
  do ~/ddl/tools/do/get_vars.do
}


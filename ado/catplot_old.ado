*! 1.1.2 NJC 11 February 2004 
* 1.1.1 NJC 2 February 2004 
* 1.1.0 NJC 8 January 2004 
* 1.0.1 NJC 29 April 2003
* 1.0.0 NJC 18 February 2003
program catplot
	version 8
	
	gettoken plottype 0 : 0 
	local plotlist "bar dot hbar" 
	if !`: list plottype in plotlist' { 
		di ///
		"{p}{txt}syntax is {inp:catplot} {it:plottype varlist} " /// 
		"... e.g. {inp: catplot hbar foreign rep78} ...{p_end}" 
		exit 198 
	}
	
	syntax varlist(max=3) [if] [in] [fweight aweight iweight/] ///
	[, PERCent(varlist) PERCent2 FRaction(varlist) FRaction2   ///
	YTItle(str asis) MISSing SORT DEScending oversubopts(str asis) * ]
	
	if "`missing'" != "" local novarlist "novarlist" 
	marksample touse, strok `novarlist' 
	qui count if `touse' 
	if r(N) == 0 error 2000 

	local pc "`percent'" 
	local pc2 "`percent2'" 
	
	local nopts = ("`pc'" != "") + ("`pc2'" != "") ///
		+ ("`fraction'" != "" ) + ("`fraction2'" != "") 
	if `nopts' > 1 {
		di as err "percent and fraction options may not be combined"
		exit 198
	}

	local pvars `pc' `fraction' 
	local prop = cond("`fraction'`fraction2'" != "", "prop", "") 
		
	tempvar toshow

	quietly { 
		if "`pc2'" != "" | "`fraction2'" != "" {
			local total = cond("`pc2'" != "", 100, 1)
			if "`weight'" == "" { 
				egen `toshow' = pc(`total') if `touse', `prop' 
			} 
			else { 
				egen `toshow' = pc(`exp') if `touse', `prop'
			} 	
		} 
		else if "`pvars'" != "" {
			local total = cond("`pc'" != "", 100, 1)
			if "`weight'" == "" { 
				egen `toshow' = pc(`total') if `touse', ///
					`prop' by(`pvars') 
			}
			else { 
				egen `toshow' = pc(`exp') if `touse', ///
					`prop' by(`pvars') 
			} 
		} 	
		else {
			if "`weight'" == "" {
				gen `toshow' = `touse' 
			}	
			else gen `toshow' = `touse' * (`exp') 
		} 	
	} 	

	if `"`ytitle'"' == "" { 
		if "`pc2'" != "" { 
			local ytitle "percent" 
		} 
		else if "`fraction2'" != "" { 
			local ytitle "fraction" 
		}	
		else if "`pc'" != "" { 
			local ytitle "percent of category" 
		} 
		else if "`fraction'" != "" { 
			local ytitle "fraction of category" 
		} 
		else local ytitle "frequency" 
	}

	if "`sort'" != "" local sort "sort(1)" 
	if "`descending'" != "" local sort "sort(1) `descending'" 
	// -descending- without -sort- is thus indulged 
	
	foreach v of local varlist { 
		local overs `"`overs' over(`v' , `sort' `oversubopts')"' 
	} 

	graph `plottype' (sum) `toshow' if `touse', ///
		`overs' ytitle(`ytitle') `missing' `options' 
end


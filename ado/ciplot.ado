*! NJC 1.1.1 15 August 2011 
*! NJC 1.1.0 18 August 2003 
* NJC 1.0.4 15 May 2003
* NJC 1.0.3 1 April 2003
* NJC 1.0.2 11 March 2003
* NJC 1.0.1 12 February 2003
* NJC 1.0.0 10 February 2003
* cihplot 1.0.4 NJC 30 May 1999 
program ciplot, sortpreserve rclass 
	version 8.1 
	syntax varlist(numeric) [if] [in] [aweight fweight]        ///
	[ , BY(varname) LEVel(integer $S_level) Poisson BINomial   ///
	Exposure(varname) EXAct Jeffreys Wilson Agresti Total      ///
	Total2(str asis) MISSing INCLusive                         ///
	YTItle(str asis) XTItle(str asis)                          ///
	HORizontal VERTical RCAPopts(str asis) plot(str asis)      ///
	addplot(str asis) * ]

	// undocumented options: INCLusive Total() plot() addplot()  

	// error checks 
	if `"`total'`total2'"' != "" & "`by'" == "" {
		di as err "by() option required with total option"
		exit 198
	}
	
	if "`missing'" != "" & "`by'" == "" {
		di as txt "missing option ignored without by() option"
	}

	if "`inclusive'" != "" marksample touse, novarlist 
	else marksample touse 
	if "`by'" != "" & "`missing'" == "" markout `touse' `by', strok 
		
	qui count if `touse' 
	if r(N) == 0 error 2000 
	
	if "`by'" != "" {
		capture confirm numeric var `by'
		if _rc { 
			tempvar byvar
			encode `by', gen(`byvar')
			_crcslbl `byvar' `by' 
			local by "`byvar'"
		}
		
		local bylab : value label `by'
		qui tab `by' if `touse' , `missing' 
		local nobs = r(r) + (("`total'" != "")|(`"`total2'"' != ""))
	}
	else local nobs = 1 
	
	local nvars : word count `varlist'

	local nshow = `nobs' * `nvars' 
	if `nshow' > _N { 
		di as err "too many intervals: increase data set size" 
		exit 498 
	} 	

	// calculations of confidence intervals 
	tempvar group mean l`level' u`level' which 
	tempname lbl

	qui {
		gen `which' = . 
		gen `mean' = .
		gen `l`level'' = .
		gen `u`level'' = .

		// these labels aren't used at present; there if wanted 
		label var `l`level'' "lower limit"
		label var `u`level'' "upper limit"
	
		bysort `touse' `by' : gen byte `group' = _n == 1 if `touse'
		replace `group' = sum(`group')

		// stepping by 2 ensures that group medians of `which' are 
		// integers and can be labelled 
		local w = 2 
		local i = 1 
		local max = `group'[_N]
		
		if "`exposure'" != "" local exposur "e(`exposure')" 
		
		count if !`touse'
		local J = 1 + r(N)

		// loop over groups 
		forval j = 1 / `max' {
			count if `group' == `j'
			local obs = r(N)
			local i1 = `i' 

			// loop over variables 
			foreach v of local varlist {
				ci `v' [`weight' `exp'] if `group' == `j', ///
     		                `exposure' `binomial' `poisson' l(`level') ///
				`exact' `jeffreys' `wilson' `agresti' 
				replace `which' = `w' in `i' 
				local i2 = `i' 
				replace `mean' = r(mean) in `i'
				replace `l`level'' = r(lb) in `i'
				replace `u`level'' = r(ub) in `i'
				if "`by'" == "" { 
					local name "`v'"
					local vlbl : variable label `v' 
					if "`vlbl'" != "" local name "`vlbl'" 
					label def `lbl' `w' "`name'", modify
					local W "`W' `w'"
				} 
				local i = `i' + 1 
				local w = `w' + 2 
			}	

			if "`by'" != "" {
		    		local name = `by'[`J']
				if "`bylab'" != ""  & !mi(`name') {
					local name : label `bylab' `name'
				}
				su `which' in `i1' / `i2', meanonly 
				local median = round((r(min) + r(max)) / 2)
				label def `lbl' `median' "`name'", modify
				local W "`W' `median'"
			}	
	
			// extra spacing between groups 
			local w = `w' + 1 
			local J = `J' + `obs'
		} 	
		
		// c.i. for total wanted? 
		if "`total'`total2'" != "" |  {
			local i1 = `i' 
			foreach v of local varlist { 
				ci `v' [`weight' `exp'] if `touse', ///
				`exposure' `binomial' `poisson' l(`level') ///
				`exact' `jeffreys' `wilson' `agresti' 
				replace `which' = `w' in `i' 
				local i2 = `i' 
				replace `mean' = r(mean) in `i'
				replace `l`level'' = r(lb) in `i'              
				replace `u`level'' = r(ub) in `i'
				local i = `i' + 1 
				local w = `w' + 2 
			}
			
			su `which' in `i1' / `i2', meanonly 
			local median = round((r(min) + r(max)) / 2)
			if `"`total2'"' == "" local total2 "Total"
			label def `lbl' `median' `"`total2'"', modify
			local W "`W' `median'"
		}
		
		label val `which' `lbl'
		if "`by'" != "" _crcslbl `which' `by' 
	}

	// set up graph 
	if "`horizontal'" == "" { 
		if `"`ytitle'"' == "" { 
			if `nvars' == 1 { 
				local ytitle : variable label `varlist' 
				if `"`ytitle'"' == "" local ytitle "`varlist'" 
				else local ytitle `""`ytitle'""' 
			} 	
			else if `"`ytitle'"' == "" local ytitle " " 
		}	
		if `"`xtitle'"' == "" { 
			if "`by'" != "" local xtitle : variable label `by' 
			if `"`xtitle'"' == "" { 
				local xtitle "`by'" 
				if "`xtitle'" == "" local xtitle `"" ""' 	
			}
			else local xtitle `""`xtitle'""' 
		} 	
	}
	else if "`horizontal'" != "" { 
		if `"`xtitle'"' == "" { 
			if `nvars' == 1 { 
				local xtitle : variable label `varlist'
				if `"`xtitle'"' == "" local xtitle "`varlist'" 
				else local xtitle `""`xtitle'""' 
			} 	
			else local xtitle `" "'  
		} 	
		if `"`ytitle'"' == "" { 
			if "`by'" != "" local ytitle : variable label `by' 
			if `"`ytitle'"' == "" { 
				local ytitle "`by'" 
				if "`ytitle'" == "" local ytitle `"" ""'  	
			}
			else local ytitle `""`ytitle'""' 
		} 	
	}

	qui { 
		local tosplit = cond("`horizontal'" != "", "`which'", "`mean'")
		tokenize `varlist' 
		tempvar seq 
		egen `seq' = seq(), to(`nvars') 
		forval i = 1 / `nvars' { 
			tempvar s 
			local lbl : var label ``i'' 
			if `"`lbl'"' == "" local lbl "``i''" 
			gen `s' = `tosplit' if `seq' == `i'  
			label var `s' `"`lbl'"' 
			local S "`S'`s' " 
		} 
	} 
	
	if "`by'" == "" | `nvars' == 1 { 
		local legend "legend(off)"
	}	
	else {  
		numlist "2 / `++nvars'"
		local legend "legend(order(`r(numlist)'))"
	}	
		
	local nmax = `which'[`nshow'] + 1

	if "`horizontal'" != "" {
		twoway rcap `l`level'' `u`level'' `which',          /// 
		hor `rcapopts' ||                                   ///  
	        scatter `S' `mean', `legend' xtitle(`xtitle')       ///
		ytitle(`ytitle') yla(`W', val noticks ang(h))       ///
		yscale(r(1,`nmax') reverse) ms(dh oh)               ///
		note("`level'% confidence intervals") `options' ||  ///
		`plot' || `addplot' 
	}
	else { 
		twoway rcap `l`level'' `u`level'' `which',           ///  
		`rcapopts' ||                                        ///
	        scatter `S' `which', `legend' ytitle(`ytitle')       ///
		xtitle(`xtitle') xla(`W', val noticks)               ///
		xscale(r(1,`nmax')) ms(dh oh)                        ///
		note("`level'% confidence intervals") `options' ||   ///
		`plot' || `addplot' 
	}	

	return local labelled "`W'" 
end


*! version 1.0.0 22aug2012 Daniel Klein

pr lab2varn ,rclass
	vers 9.2
	
	if !(c(k)) e 0
	
	syntax varlist [, Dryrun Truncate(int 32) ]
	
	// set valid characters
	loc abc `c(alpha)'
	loc ABC `c(ALPHA)'
	
	// create names
	loc old `varlist'
	foreach v of loc varlist {
		loc varl : var l `v'
		if (`"`macval(varl)'"' == "") {
			loc old : list old - v
			continue
		}
		
		// substitute invalid characters
		loc varl : subinstr loc varl "`" " " ,all
		forv j = 1/`: length loc varl' {
			loc tok = substr(`"`varl'"', `j', 1)
			if inlist(`"`tok'"',"_", " ") continue
			cap conf integer n `tok'
			if !(_rc) | (`: list tok in abc') | (`: list tok in ABC') {
				continue
			}
			loc varl : subinstr loc varl `"`tok'"' " " ,all
		}
		if (substr("`varl'", 1, 1) == " ") ///
		| inrange(substr("`varl'", 1, 1), "0", "9") loc us _
		else loc us
		loc varl : list retok varl
		loc varl : subinstr loc varl " " "_" ,all
		loc varl `us'`varl'
				
		// truncate
		loc varl = substr("`varl'",1 ,`truncate')
		
		// put in new
		if ("`varl'" == "`v'") {
			loc old : list old - v
			continue
		}
		loc new `new' `varl'
	}
	if ("`new'" == "") {
		di %2s as txt " " "(all {it:newnames}=={it:oldnames})"
		e 0
	}
	conf new v `new' // no rc
	
	// dryrun
	if ("`dryrun'" != "") {
		_dryrun ,v(`varlist') old(`old') new(`new')
		e 0
	}
		
	// rename variables
	token `new'
	loc i 0
	foreach v of loc old {
		ren `v' ``++i''
	}
	
	// return
	ret loc newnames `new'
	ret loc oldnames `old'
end

pr _dryrun
	syntax ,v(str) old(str) new(str)
	di %37s as txt _n "{it:oldname}" " - " "{it:newname}"
	token `old'
	loc i 0
	foreach n of loc new {
		di %32s as res "``++i''" " - " "`n'"
	}
	loc noren : list v - old
	if ("`noren'" == "") e 0
	di 
	foreach e of loc noren {
		di %32s as res "`e'" " - " "`e'" 
	}
end
e

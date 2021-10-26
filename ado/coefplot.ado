*! version 1.8.3  07mar2019  Ben Jann

program coefplot
    version 11
    nobreak {
        capt mata: mata drop COEFPLOT_STRUCT
        capt n break _coefplot `macval(0)'
        local rc = _rc
        capt mata: mata drop COEFPLOT_STRUCT
        exit `rc'
    }
end

program _coefplot, rclass
    // get subgraphs and parse global options
    parse_subgraphs `macval(0)'     // returns n_subgr, subgr_#, opts
    parse_globalopts `macval(opts)' // returns expanded global opts and twopts, 
                            // subgropts0, plotopts0, modelopts0, twplotopts0
    
    // backup current estimates, initialize struct
    tempname ecurrent
    _est hold `ecurrent', restore estsystem nullok
    mata: COEFPLOT_STRUCT = coefplot_struct_init()
    
    // dryrun across subgraphs and plots to collect options
    local i             0
    local N_plots       0
    forv j = 1/`n_subgr' {
        if "`recycle'"=="" local i 0
        local firstplot_`j' = `i'+1
        parse_plots `j' `macval(subgr_`j')' // returns n_plots_j, plot_j_#, opts
        if ("`recycle'"=="" & `n_subgr'>1) {
            combine_plotopts, `macval(opts)' _opts0(`macval(plotopts1prev)')
            local plotopts1prev `macval(plotopts)'
            local opts `macval(plotopts)' `macval(options)'
        }
        merge_subgropts, `macval(opts)' _opts0(`subgropts0' `plotopts0' `macval(modelopts0)')
                    // returns subgropts, plotopts1, modelopts1, twplotopts1
        parse_subgropts `j', `subgropts'
        forv k = 1/`n_plots_`j'' {
            local ++i
            local twplotopts1_`i' `twplotopts1_`i'' `twplotopts1'
            parse_models `j' `k' `macval(plot_`j'_`k')' 
                // returns n_models_j_k, model_j_k_#, opts
            if `n_models_`j'_`k''==1 & `"`model_`j'_`k'_1'"'=="_skip" {
                if `"`opts'"'!="" {
                    di as err "options not allowed with _skip"
                    exit 198
                }
                continue
            }
            if (`i'>`N_plots') {    // get p#() from twoplotopts0
                parse_get_popt_i `i', `macval(twplotopts0)' // returns twplotopts0, plotopts
                if `"`macval(plotopts)'"'!="" {
                    merge_plotopts, `macval(plotopts)'  // to isolate the modelopts
                    local popt_mopts_`i' `macval(modelopts2)'
                    merge_plotopts, `macval(opts)' ///
                        _opts0(`macval(modelopts2)' `plotopts' `_opts0' `options')
                        // returns plotopts, modelopts2, options, _opts0
                    local opts `macval(modelopts2)' `plotopts' `_opts0' `options' 
                }
            }
            else {
                if `"`macval(popt_mopts_`i')'"'!="" { // add modelopts from p#()
                    merge_plotopts, `macval(opts)' _opts0(`macval(popt_mopts_`i')')
                        // returns plotopts, modelopts2, options, _opts0
                    local opts `macval(modelopts2)' `plotopts' `_opts0' `options' 
                }
            }
            if ("`recycle'"=="" & `n_subgr'>1) {
                combine_plotopts, `macval(opts)' _opts0(`macval(plotopts2_`i')')
                local plotopts2_`i' `macval(plotopts)'
                local opts `macval(plotopts)' `macval(options)'
            }
            merge_plotopts, `macval(opts)' _opts0(`macval(plotopts1)' `macval(modelopts1)') 
                        // returns plotopts, modelopts2, options, _opts0
            if `"`_opts0'"'!="" error 198
            local modelopts_`j'_`k' `macval(modelopts2)'
            local twplotopts_`i' `twplotopts_`i'' `options'
            local plotopts_`i' `plotopts'
        }
        local lastplot_`j' `i'
        local N_plots = max(`N_plots', `i')
    }
    // expand plotopts
    local customoffset  0
    forv i = 1/`N_plots' {
        parse_plotopts `i', `plotopts_`i''
        if `"`offset_`i''"'!="" local customoffset 1
    }
    // parse cismooth
    forv i = 1/`N_plots' {
        local cis_`i' = `"`cismooth_`i''"'!=""
        if `cis_`i'' {
            if `"`cismooth_`i''"'=="cismooth" local cismooth_`i'
            parse_cismooth `i', `cismooth_`i'' // returns cis_levels_i,
                // cis_n_i, cis_lwidth_i, cis_intens_i, cis_color_i, cis_pstyle_i
        }
        else local cis_n_`i' = 0
    }
    
    // parse models and collect results
    local i 0
    forv j = 1/`n_subgr' {
        if "`recycle'"=="" local i 0
        forv k = 1/`n_plots_`j'' {
            local ++i
            if `n_models_`j'_`k''==1 & `"`macval(model_`j'_`k'_1)'"'=="_skip" {
                continue
            }
            forv l = 1/`n_models_`j'_`k'' {
                parse_model `macval(model_`j'_`k'_`l')' // returns model, matrix, opts
                if `"`matrix'"'=="" {
                    if `"`model'"'=="." {
                        _est unhold `ecurrent'
                    }
                    else {
                        qui est restore `model'
                    }
                }
                collect_coefs `"`model'"' ///
                    "`matrix'"          /// matrix mode?
                    "`atmode'"          /// whether at() is used; will be replaced
                    `i'                 /// plot number
                    `j'                 /// subgraph number
                    "`cis_levels_`i''"  ///
                    , `macval(opts)' _opts0(`macval(modelopts_`j'_`k')')
                        // returns equation, atmode, n_ci
                        // may reset mlabel_# and mlabvposition_# 
                local n_ci = `n_ci' - `cis_n_`i''
                if `"`matrix'"'=="" & `"`model'"'=="." {
                    _est hold `ecurrent', restore estsystem nullok
                }
                if "`n_ci_`i''"=="" local n_ci_`i' 0
                local n_ci_`i' = max(`n_ci_`i'', `n_ci')
                mata: coefplot_add_label(COEFPLOT_STRUCT, "by", `j', "model", 0)
                if `"`equation'"'!="" {
                    if `"`model'"'=="." local model `"`equation'"'
                    else                local model `"`model'=`equation'"'
                }
                mata: coefplot_add_label(COEFPLOT_STRUCT, "plot", `i', "model", 0)
            }
        }
    }
    forv i = 1/`N_plots' { // expand ciopts
        if `n_ci_`i''>0 {
            parse_ciopts_nocilwincr `i', `ciopts_`i'' `cirecast_`i'' // returns nocilwincr_#
            parse_ciopts `i' `n_ci_`i'' `ciopts_`i'' `cirecast_`i''
        }
    }
    mata: coefplot_set_r(COEFPLOT_STRUCT) // returns r, N_ci, N_aux, mlbllen
    local mlbllen = max(1, min(c(maxstrvarlen), `mlbllen'))
    if `r'==0 {
        di as txt "(nothing to plot)"
        exit
    }
    
    // cleanup and and arrange
    if `"`horizontal'`vertical'"'=="" {
        if `atmode' local vertical vertical
        else        local horizontal horizontal
    }
    if `"`horizontal'"'!="" {
        local xaxis y
        local yaxis x
        local offdir "-"
        local reverse yscale(reverse)
        local plotregion plotregion(margin(t=0 b=0))
    }
    else {  // vertical
        local xaxis x
        local yaxis y
        local offdir "+"
        local plotregion plotregion(margin(l=0 r=0))
    }
    if `atmode' {
        if "`bycoefs'"!="" {
            di as err "at() and bycoefs not both allowed"
            exit 198
        }
        local grid       `"`grid'`gridopts'"'
        foreach opt in order coeflabels eqlabels relocate headings ///
            groups grid {
            if `"``opt''"'!="" {
                di as err "at() and `opt'() not both allowed"
                exit 198
            }
        }
        mata: coefplot_add_eq_and_grp(COEFPLOT_STRUCT)
        local reverse
        local plotregion
        local meqs 0
    }
    else {
        if `"`eqstrict'"'!=""  local meqs 1
        else {
            mata: coefplot_multiple_eqs(COEFPLOT_STRUCT) // returns meqs
        }
        mata: coefplot_arrange(COEFPLOT_STRUCT) // updates local r
        mata: coefplot_coeflbls(COEFPLOT_STRUCT)
        coeflbls "`labels'" `"`clinteract'"'
        if "`bycoefs'"!="" {
            mata: coefplot_bycoefs(COEFPLOT_STRUCT) // returns n_subgr
            local meqs 0
        }
        mata: coefplot_catvals(COEFPLOT_STRUCT)
            // modifies C.at; sets C.eq, C.grp; returns groups
        mata: coefplot_headings(COEFPLOT_STRUCT) 
            // modifies C.at; returns hlbls
    }
    
    // save results to variables
    if `"`generate'"'=="" {
        if (_N > `r') & "`nodrop'"=="" {
            preserve
            qui keep in 1/`r'   // remove extra observations to speed up
        }
        else if (_N < `r') {
            preserve
            qui set obs `r'
        }
    }
    else {
        if (_N < `r') {
            di as txt "need to create additional observations; " _c
            di as txt "press break to abort"
            more
            set obs `r'
        }
    }
    tempname by plot at mlbl mlpos b V se t df pval eq grp
    qui gen `by' = .
    qui gen `plot' = .
    qui gen `at' = .
    qui gen str`mlbllen' `mlbl' = ""
    qui gen `mlpos' = .
    qui gen `b' = .
    qui gen `V' = .
    qui gen `se' = .
    qui gen `t' = .
    qui gen `df' = .
    qui gen `pval' = .
    if `"`format'"'!="" {
        format `format' `b' `V' `se' `t' `pval'
    }
    qui gen `eq' = .
    qui gen `grp' = .
    forv i = 1/`N_ci' {
        tempname ll`i' ul`i'
        qui gen `ll`i'' = .
        qui gen `ul`i'' = .
        if `"`format'"'!="" {
            format `format' `ll`i'' `ul`i''
        }
    }
    forv i = 1/`N_aux' {
        tempname aux`i'
        qui gen `aux`i'' = .
        if `"`format'"'!="" {
            format `format' `aux`i''
        }
    }
    if `"`generate'"'!="" {
        preserve
        if "`replace'"!="" {
            capt label drop `generate'by 
            capt label drop `generate'plot
        }
        local returnvars
        local i 0
        foreach v in by plot at mlbl mlpos b V se t df pval {
            local ++i
            local varl: word `i' of                 ///
                "subgraph ID"                       ///
                "plot ID"                           ///
                "plot position (category axis)"     ///
                "marker label"                      ///
                "marker label position"             ///
                "coefficient"                       ///
                "variance"                          ///
                "standard error"                    ///
                "t or z statistic"                  ///
                "degrees of freedom"                ///
                "p-value"
            if "`replace'"!="" {
                capt confirm new variable `generate'`v', exact
                if _rc {
                    drop `generate'`v'
                }
            }
            rename ``v'' `generate'`v'
            lab var `generate'`v' `"`varl'"'
            local `v' `generate'`v'
            local returnvars `returnvars' `generate'`v'
        }
        forv i = 1/`N_ci' {
            foreach v in ll ul {
                if "`v'"=="ll" local varl "CI`i': lower limit"
                else           local varl "CI`i': upper limit"
                if "`replace'"!="" {
                    capt confirm new variable `generate'`v'`i', exact
                    if _rc {
                        drop `generate'`v'`i'
                    }
                }
                rename ``v'`i'' `generate'`v'`i'
                lab var `generate'`v'`i' `"`varl'"'
                local `v'`i' `generate'`v'`i'
                local returnvars `returnvars' `generate'`v'`i'
            }
        }
        forv i = 1/`N_aux' {
            local varl "Auxiliary variable `i'"
            if "`replace'"!="" {
                capt confirm new variable `generate'aux`i', exact
                if _rc {
                    drop `generate'aux`i'
                }
            }
            rename `aux`i'' `generate'aux`i'
            lab var `generate'aux`i' `"`varl'"'
            local aux`i' `generate'aux`i'
            local returnvars `returnvars' `generate'aux`i'
        }
    }
    mata: coefplot_put(COEFPLOT_STRUCT)
    mata: coefplot_apply_transform(COEFPLOT_STRUCT)
    qui compress `at' `df' `plot' `by' `eq' `grp' `mlpos' // not really needed

    // get labels
    set_by_and_plot_labels `plot' `by'
    if `"`plotlabels'"'!="" {
        set_labels "`plot'" "`N_plots'" `"`plotlabels'"'
    }
    if `"`pltrunc'`plwrap'"'!="" {
        truncwrap_vlabels "`plot'" "`N_plots'" "`pltrunc'" ///
            "`plwrap'" "`plbreak'"
    }
    if "`bycoefs'"=="" {
        if `"`bylabels'"'!="" {
            set_labels "`by'" "`n_subgr'" `"`bylabels'"'
        }
        if `"`bltrunc'`blwrap'"'!="" {
            truncwrap_vlabels "`by'" "`n_subgr'" "`bltrunc'" ///
                "`blwrap'" "`blbreak'"
        }
    }
    if `atmode'==0 {
        if "`grid'"=="" & "`xaxis'"=="y" {
            if `N_plots'>1 & `"`offsets'"'==""  local grid between
            else                                local grid within
        }
        get_axis_labels `at' `eq' `grp' "`grid'" `"`groups'"'
            // => returns xlabels, xgrid, xrange, eqlabels, groups
        if `meqs'==0 | "`noeqlabels'"!="" local eqlabels
        if `"`cltrunc'`clwrap'"'!="" {
            if "`bycoefs'"=="" {
                truncwrap_labels xlabels "`cltrunc'" "`clwrap'" ///
                    "`clbreak'" `"`xlabels'"'
            }
            else {
                truncwrap_vlabels "`by'" "`n_subgr'" "`cltrunc'" ///
                    "`clwrap'" "`clbreak'"
            }
        }
        if "`bycoefs'"!="" {
            if `"`bylabels'"'!="" {
                reset_xlabels `"`bylabels'"' `"`xlabels'"'
            }
            if `"`bltrunc'`blwrap'"'!="" {
                truncwrap_labels xlabels "`bltrunc'" "`blwrap'" ///
                    "`blbreak'" `"`xlabels'"'
            }
        }
        if `"`clangle'"'=="" local clangle angle(horizontal)
        local xlabel `xaxis'label(`xlabels', nogrid `clangle' `clopts')
        local xrange `xaxis'scale(range(`xrange'))
        if !inlist("`grid'", "", "none") {
            local xtick `xaxis'tick(`xgrid', notick tlstyle(none) grid `gridopts')
                // note: tlstyle(none) is required to prevent by() from drawing
                //       the ticks
        }
        else local xtick
        if "`eqashead'"!="" {
            merge_eqlabels_hlbls `"`eqlabels'"' `"`hlbls'"'
                // => returns hlbls and clears eqlabels
        }
        if `"`eqtrunc'`eqwrap'"'!="" {
            if `"`eqlabels'"'!="" {
                 truncwrap_labels eqlabels "`eqtrunc'" "`eqwrap'" ///
                    "`eqbreak'" `"`eqlabels'"'
            }
        }
        if `"`gtrunc'`gwrap'"'!="" {
            if `"`groups'"'!="" {
                 truncwrap_labels groups "`gtrunc'" "`gwrap'" ///
                    "`gbreak'" `"`groups'"'
            }
        }
        if `"`htrunc'`hwrap'"'!="" {
            if `"`hlbls'"'!="" {
                 truncwrap_labels hlbls "`htrunc'" "`hwrap'" ///
                    "`hbreak'" `"`hlbls'"'
            }
        }
    }

    // compute offsets
    if `customoffset' {
        forv i = 1/`N_plots' {
            if "`offset_`i''"!="" {
                qui replace `at' = `at' `offdir' `offset_`i'' if `plot'==`i'
            }
        }
    }
    else if `atmode'==0 & `"`offsets'"'=="" & `N_plots'>1 {
        if "`recycle'"=="" | `n_subgr'==1 {
            qui replace `at' = `at' - 0.5 + `plot'/(`N_plots'+1)
        }
        else {
            forv j=1/`n_subgr' {
                qui replace `at' = `at' - 0.5 + ///
                    (`plot'-`firstplot_`j''+1) / ///
                    (`lastplot_`j''-`firstplot_`j''+2) if `by'==`j'
            }
        }
    }
    
    // inject tempvars
    forv i=1/`N_plots' {
        foreach opt in ifopt weightopt mlabel mlabvposition {
            if `"``opt'_`i''"'!="" {
                mata: coefplot_inject_temvars("`opt'_`i'", `N_ci', `N_aux')
            }
        }
    }
    
    // handle string expressions in mlabel()
    forv i=1/`N_plots' {
        if `"`mlabel_`i''"'!="" {
            if `"`mlabel_`i''"'=="mlabel(`mlbl')" continue
            parse_mlabel_exp, `mlabel_`i'' // returns mlblexp
            capt confirm variable `mlblexp'
            if _rc==0 continue
            capt replace `mlbl' = `mlblexp' if `plot'==`i'
            if _rc {
                di as err "invalid expression in mlabel()"
                exit 198
            }
            local mlabel_`i' mlabel(`mlbl')
        }
    }

    // compile plot
    local addaxis 1
    local eqaxis  2
    local axisalt alt
    if (`"`eqlabels'"'!="" & `"`groups'"'!="") | (`"`addplotbelow'"'!="") local axisalt
    if `"`groups'"'!="" {
        local ++eqaxis
        local addaxis `addaxis' 2
        local groupsopts `xaxis'scale(axis(2) `axisalt' noline) ///
            `xaxis'title("", axis(2)) ///
            `xaxis'label(`groups', axis(2) noticks tlstyle(none) `gopts')
    }
    if `"`eqlabels'"'!="" {
        local addaxis `addaxis' `eqaxis'
        local eqaxisopts `xaxis'scale(axis(`eqaxis') `axisalt' noline) ///
            `xaxis'title("", axis(`eqaxis')) ///
            `xaxis'label(`eqlabels', axis(`eqaxis') noticks ///
                tlstyle(none) `eqopts')
    }
    local axisalt
    if "`addaxis'"!="1" {
        local addaxis `xaxis'axis(`addaxis')
        if `"`addplotbelow'"'!="" {
            if (`"`eqlabels'"'!="")+(`"`groups'"'!="")==1 {
                local axisalt `xaxis'scale(alt)
            }
        }
    }
    else local addaxis
    if `"`hlbls'"'!="" {
        local hlblsopts ///
            `xaxis'label(`hlbls', custom add tlstyle(none) `hopts')
    }
    local j 0
    if `"`addplot'"'!="" {
        mata: coefplot_inject_temvars("addplot", `N_ci', `N_aux')
        if `"`addplotbelow'"'!="" {
            capt two `addplot' ||, nodraw
            if _rc==0 local j `.Graph.last_style'
            capt confirm integer number `j'
            if _rc local j 0
        }
    }
    local plots
    local legendlbls
    local legendorder
    forv i=1/`N_plots' {
        local key
        if "`n_ci_`i''"=="" {
            continue // plot does not exist (this can happen if _skip is
                     // specified together with norecycle)
        }
        local n_ci = `n_ci_`i'' + `cis_n_`i''
        if `n_ci'==0 & `"`cionly_`i''"'!="" {
            continue // can happen if noci and cionly is specified 
        }
        local axis
        if `"`axis_`i''"'!="" {
            local axis `yaxis'axis(`axis_`i'')
        }
        local ciplots
        if (`n_ci')>0 {
            get_pstyle_id `=mod(`i'-1,`pcycle')+1', `pstyle_`i'' // returns pstyle_id
            forv k = 1/`n_ci' {
                local lw
                if `k'>`cis_n_`i'' {
                    local l = `k' - `cis_n_`i''
                    local ciopts `ciopts_`i'_`l''
                    parse_ciopts_recast_pstyle, `ciopts'
                        // returns cirecast, cipstyle, ciopts
                    if "`nocilwincr_`i''"=="" {
                        local lw: di 1 + log10(`l')/log10(2)
                        local lw lwidth(*`lw')
                    }
                    local ciplotcmd rspike `ll`k'' `ul`k'' `at'
                    if (substr(`"`cirecast'"',1,2)=="pc") { // paired coordinates
                        local ciplotcmd `cirecast' `ll`k'' `at' `ul`k'' `at'
                        if `"`cirecast'"'=="pcrarrow" {
                            local ciplotcmd pcarrow `ul`k'' `at' `ll`k'' `at'
                        }
                    }
                    else if `"`cirecast'"'!="" {
                        local ciopts `ciopts' recast(`cirecast')
                    }
                }
                else { // cismooth
                    local l 0
                    local cirecast
                    local cipstyle `cis_pstyle_`i''
                    local lw: word `k' of `cis_lwidth_`i''
                    local lw lwidth(*`lw')
                    local lcinten: word `k' of `cis_intens_`i''
                    local ciopts lcolor("`cis_color_`i''*`lcinten'") `cipstyle'
                    local ciplotcmd rspike `ll`k'' `ul`k'' `at'
                }
                if `"`cipstyle'"'!="" local pstyle
                else {
                    set_pstyle `pstyle_id' `"`cirecast'"' // returns pstyle
                }
                local ciplots `ciplots' ///
                    (`ciplotcmd' if `plot'==`i'`ifopt_`i'', `addaxis' ///
                    `pstyle' `lw' `axis' `ciopts' `horizontal')
            }
        }
        if "`citop_`i''"=="" & `n_ci'>0 {
            local plots `plots' `ciplots'
            local j = `j' + `cis_n_`i''
            if inrange(`key_`i'', 1, `n_ci_`i'') {
                local key = `j' + `key_`i''
            }
            local j = `j' + `n_ci_`i''
        }
        if `"`cionly_`i''"'=="" {
            if `"`pstyle_`i''"'!="" local pstyle `pstyle_`i''
            else {
                set_pstyle `=mod(`i'-1,`pcycle')+1' `"`recast_`i''"' // returns pstyle
            }
            if `"`recast_`i''"'!=""  local recast recast(`recast_`i'')
            else                     local recast
            if `"`horizontal'"'=="" | inlist(`"`recast_`i''"', ///
                                "area", "bar", "spike", "dropline", "dot") {
                local plots `plots' ///
                    (scatter `b' `at'                                  ///
                    if `plot'==`i'`ifopt_`i''`weightopt_`i'',          ///
                    `addaxis' `pstyle' `twplotopts0' `twplotopts1_`i'' ///
                    `axis' `recast' `mlabel_`i'' `mlabvposition_`i''   ///
                    `twplotopts_`i'' `horizontal')
            }
            else {
                local plots `plots' ///
                    (scatter `at' `b'                                  ///
                    if `plot'==`i'`ifopt_`i''`weightopt_`i'',          ///
                    `addaxis' `pstyle' `twplotopts0' `twplotopts1_`i'' ///
                    `axis' `recast' `mlabel_`i'' `mlabvposition_`i''   ///
                    `twplotopts_`i'')
            }
            local ++j
            if `key_`i''==0 {
                local key `j'
            }
        }
        local plotlab `"`: lab `plot' `i''"'
        gettoken trash : plotlab, qed(hasquotes)
        if `hasquotes'==0 {
            local plotlab `"`"`plotlab'"'"'
        }
        if "`citop_`i''"!="" & `n_ci'>0 {
            local plots `plots' `ciplots'
            local j = `j' + `cis_n_`i''
            if inrange(`key_`i'', 1, `n_ci_`i'') {
                local key = `j' + `key_`i''
            }
            local j = `j' + `n_ci_`i''
        }
        if "`key'"!="" {
            local legendlbls `legendlbls' label(`key' `plotlab')
            local legendorder `legendorder' `key'
        }
    }
    if `"`legendorder'"'!="" {
        local legendorder all order(`legendorder')
        if `N_plots'==1 {
            if `n_subgr'==1 & `"`legend'"'=="" {
                local legendorder `legendorder' off 
            }
        }
    }
    else local legendorder off
    if `n_subgr'>1 {
        local byopt `by', note("")
        if (`N_plots'==1 & `"`bylegend'"'=="") | `"`legendorder'"'=="off" {
            local byopt `byopt' legend(off)
        }
        local byopt by(`byopt' `bylegend' `byopts')
    }
    else local byopt
    if `"`plots'"'=="" {
        di as txt "(nothing to plot)"
        exit
    }
    if `"`addplot'"'!="" {
        if `"`addplotbelow'"'!="" {
            local plots `addplot' || `plots' ||
        }
        else {
            local plots `plots' || `addplot' ||
        }
    }
    local plots two `plots', `axisalt' `groupsopts' `eqaxisopts' ///
        `xlabel' `hlblsopts' `xtick' `xrange' `reverse' yti("") xti("") ///
        legend(`legendlbls' `legendorder') `legend' `plotregion' `byopt' `twopts'
    `plots'
    
    // return
    if `"`generate'"'!="" {
        restore, not
        di as txt _n "Generated variables:" _c
        describe `returnvars'
    }
    return local graph    `plots'
    return local labels   `"`xlabels'"'
    return local eqlabels `"`eqlabels'"'
    return local groups   `"`groups'"'
    return local headings `"`hlbls'"'
    return local legend   `"`legendlbls' `legendorder'"'
    return scalar n_plots = `N_plots'
    return scalar n_subgr = `n_subgr'
    return scalar n_ci = `N_ci'
end

program parse_subgraphs // input: "subgr || subgr ..., opts"
    local i 0
    local empty 1
    while (`"`macval(0)'"'!="") {
        gettoken subgraph 0 : 0, parse("|") bind
        if `"`macval(subgraph)'"'=="|" {
            gettoken subgraph 0 : 0, parse("|") bind
            if `"`macval(subgraph)'"'!="|" error 198  // require "||"
            if `empty' {
                local ++i
                c_local subgr_`i' "."               // use active model
            }
            else local empty 1
            continue
        }
        if `"`0'"'=="" {                            // get opts if last
            _parse comma subgraph opts : subgraph
        }
        if `"`macval(subgraph)'"'!="" {             // skip last if empty
            local empty 0
            local ++i
            c_local subgr_`i' `"`macval(subgraph)'"'
        }
    }
    if `i'==0 {                                     // check if empty
        local i 1
        c_local subgr_1 "."                         // use active model
    }
    c_local n_subgr `i'
    c_local opts `macval(opts)'
end

program parse_globalopts
    syntax [,                       ///
        /// globalopts
        HORizontal                  ///
        VERTical                    ///
        sort SORT2(str)             ///
        orderby(str)                ///
        order(str asis)             ///
        BYCoefs                     ///
        noRECycle                   ///
        grid(str)                   ///
        noOFFsets                   ///
        format(str)                 ///
        noLABels                    ///
        COEFLabels(str asis)        ///
        NOEQLABels                  ///
        EQLabels(str asis)          ///
        eqstrict                    ///
        HEADings(str asis)          ///
        GROUPs(str asis)            ///
        PLOTLabels(str asis)        ///
        bylabels(str asis)          ///
        GENerate GENerate2(name)    ///
        RELOCate(str asis)          ///
        replace                     ///
        addplot(str asis)           ///
        NODROP                      ///
        LEGend(passthru)            ///
        BYOPts(str asis)            ///
        Bname(passthru)             /// so that b() is not b1title()
        rename(passthru)            ///
        EQREName(passthru)          ///
        PCYCle(int 15)              ///
        /// twoway options not captured by _get_gropts, gettwoway
        play(passthru)              ///
        XOVERHANGs                  ///
        YOVERHANGs                  ///
        fxsize(passthru)            ///
        fysize(passthru)            ///
        *                           ///
        ]
    _get_gropts, graphopts(`options') gettwoway
    local twopts `s(twowayopts)' `play' `xoverhangs' `yoverhangs' `fxsize' `fysize'
    local opts0 `bname' `macval(rename)' `macval(eqrename)' `s(graphopts)'
    if `"`sort'`sort2'"'!="" {
        parse_sort `sort2' // returns local sort
    }
    if `"`orderby'"'!="" {
        parse_orderby `orderby', `recycle' // returns local orderby
    }
    if `"`generate'"'!="" & `"`generate2'"'=="" {
        local generate "__"
    }
    else local generate `"`generate2'"'
    if `"`grid'"'!="" {
        parse_grid, `grid' // returns local grid, gridopts
    }
    if `"`coeflabels'"'!="" {
        parse_coeflabels `coeflabels'
            // returns coeflabels, cltrunc, clwrap, clbreak, clinteract, clangle, clopts
    }
    if `"`clinteract'"'=="" {
        local clinteract `"" # ""'
    }
    parse_eqlabels "`noeqlabels'" `eqlabels'
        // returns eqlabels, eqashead, eqxlab
        // if eqashead=="": also eqgap, eqwrap, eqtrunc, eqbreak, eqopts
        // if eqashead!="": also hoff, hgap, hwrap, htrunc, hbreak, hopts
    if `"`headings'"'!="" {
        if `"`eqashead'"'!="" {
            di as err "eqlabels(, asheadings) and headings() not both allowed"
            exit 198
        }
        parse_headings `headings' // returns headings, hoff, hgap, hopts
    }
    else if `"`hgap'"'=="" local hgap 0
    if `"`eqashead'"'!="" {
        if "`bycoefs'"!="" {
            di as err "eqlabels(, asheadings) and bycoefs not both allowed"
            exit 198
        }
    }
    if `"`groups'"'!="" {
        parse_groups `groups' // returns groups, ggap, gwrap, gtrunc, gbreak, gopts
    }
    else local ggap 0
    if `"`plotlabels'"'!="" {
        parse_plotlabels `plotlabels' // returns plotlabels, plwrap, pltrunc, plbreak
    }
    if `"`bylabels'"'!="" {
        parse_bylabels `bylabels' // returns bylabels, blwrap, bltrunc, blbreak
    }
    if `"`format'"'!="" {
        confirm numeric format `format'
    }
    if `"`horizontal'"'!="" {
        if `"`vertical'"'!="" {
            di as err "horizontal and vertical not both allowed"
            exit 198
        }
    }
    if `"`addplot'"'!="" {
        parse_addplot `addplot' // returns addplot, addplotbelow
    }
    parse_byopts, `byopts' // returns bylegend, byopts
    foreach opt in                                                   ///
        horizontal                                                   ///
        vertical                                                     ///
        sort                                                         ///
        orderby                                                      ///
        order                                                        ///
        bycoefs                                                      ///
        recycle                                                      ///
        grid gridopts                                                ///
        offsets                                                      ///
        format                                                       ///
        labels                                                       ///
        coeflabels cltrunc clwrap clbreak clinteract clangle clopts  ///
        noeqlabels                                                   ///
        eqlabels eqashead eqxlab eqgap eqtrunc eqwrap eqbreak eqopts ///
        eqstrict                                                     ///
        headings hxlab hoff hgap htrunc hwrap hbreak hopts           ///
        groups ggap gtrunc gwrap gbreak gopts                        ///
        plotlabels plwrap pltrunc plbreak                            ///
        bylabels blwrap bltrunc blbreak                              ///
        relocate                                                     ///
        generate                                                     ///
        replace                                                      ///
        addplot addplotbelow                                         ///
        nodrop                                                       ///
        legend                                                       ///
        bylegend                                                     ///
        byopts                                                       ///
    {
        c_local `opt' `"``opt''"'
    }
    c_local pcycle `pcycle'
    c_local twopts `twopts'
    merge_subgropts, `macval(opts0)'
    c_local subgropts0  `subgropts'
    c_local plotopts0   `plotopts1'
    c_local modelopts0  `macval(modelopts1)'
    c_local twplotopts0 `twplotopts1'
end

program parse_sort
    syntax [anything] [, Descending by(str) ]
    if `"`anything'"'=="" {
        local subgr .
        local plot .
    }
    else {
        gettoken subgr rest : anything, parse(":")
        if `"`rest'"'=="" {                 // sort(#)
            local plot `"`subgr'"'
            local subgr .
        }
        else if `"`subgr'"'==":" {          // sort(:#)
            local subgr .
            gettoken plot rest : rest
        }
        else {                              // sort(#:#)
            gettoken colon rest : rest, parse(":")
            if `"`colon'"'!=":" {
                di as err "sort(): invalid syntax"
                exit 198
            }
            gettoken plot rest : rest
        }
        if `"`rest'"'!="" {
            di as err "sort(): invalid syntax"
            exit 198
        }
        foreach t in subgr plot {
            if `"``t''"'=="" local `t' .
            else if `"``t''"'!="." {
                capt confirm integer number ``t''
                if _rc==0 {
                    local rc = (``t''<=0)
                }
                else local rc 1
                if `rc' {
                    di as err "sort(): invalid syntax"
                    exit 198
                }
            }
        }
    }
    capt parse_sort_by, `by'
    if _rc {
        di as err `"sort(): '`by'' not allowed in by()"'
        exit 198
    }
    local descending = ("`descending'"!="")
    c_local sort `"`subgr' `plot' `descending' "`by'""'
end
program parse_sort_by
    syntax [, b v se t tabs df p ll ul aux * ]
    local by `b' `v' `se' `t' `tabs' `df' `p' `ll' `ul' `aux'
    if `: list sizeof by'>1 exit 198
    if inlist("`by'","ll", "ul", "aux") {  // by(ll/ul/aux #)
        if `"`options'"'=="" local by `by' 1
        else {
            capt confirm integer number `options'
            if _rc==0 {
                local rc = (`options'<=0)
            }
            else local rc 1
            if `rc' exit 198
            local by `by' `options'
        }
    }
    else if `"`options'"'!="" exit 198
    if `"`by'"'=="" local by b
    c_local by `by'
end

program parse_orderby
    syntax [anything] [, norecycle ]
    gettoken subgr rest : anything, parse(":")
    if `"`rest'"'=="" {                 // orderby(#)
        local plot `"`subgr'"'
        local subgr 1
    }
    else if `"`subgr'"'==":" {          // ordeby(:#)
        local subgr 1
        gettoken plot rest : rest
    }
    else {                              // orderby(#:#)
        gettoken colon rest : rest, parse(":")
        if `"`colon'"'!=":" {
            di as err "orderby(): invalid syntax"
            exit 198
        }
        if "`recycle'"!="" {
            di as err "orderby(): subgraph not allowed with norecycle"
            exit 198
        }
        gettoken plot rest : rest
    }
    if `"`rest'"'!="" {
        di as err "orderby(): invalid syntax"
        exit 198
    }
    foreach t in subgr plot {
        if `"``t''"'=="" local `t' 1
        else {
            capt confirm integer number ``t''
            if _rc==0 {
                local rc = (``t''<=0)
            }
            else local rc 1
            if `rc' {
                di as err "orderby(): invalid syntax"
                exit 198
            }
        }
    }
    if "`recycle'"!="" local subgr .
    c_local orderby `subgr' `plot'
end

program parse_grid
    syntax [, Between Within None * ]
    if ("`between'"!="") + ("`within'"!="") + ("`none'"!="") > 1 {
        di as err "grid(): only one of between, within, and none allowed"
        exit 198
    }
    c_local grid     `between' `within' `none'
    c_local gridopts `options'
end

program parse_coeflabels
    mata: coefplot_parsecomma("coeflabels", "0", "0")
    syntax [, Truncate(numlist integer max=1 >0)    ///
        Wrap(numlist integer max=1 >0) noBreak      ///
        Interaction(str asis) angle(passthru) * ]
    c_local coeflabels  `"`coeflabels'"'
    c_local cltrunc     `truncate'
    c_local clwrap      `wrap'
    c_local clbreak     `break'
    c_local clinteract  `"`interaction'"'
    c_local clangle     `angle'
    c_local clopts      `options'
end

program parse_eqlabels
    gettoken noeqlabels 0 : 0
    mata: st_local("0", strltrim(st_local("0")))
    mata: coefplot_parsecomma("eqlabels", "0", "0")
    syntax [, LABels LABels2(str asis) ///
        OFFset(real 0) ASHEADings noGap Gap2(numlist max=1) ///
        Truncate(numlist integer max=1 >0)      ///
        Wrap(numlist integer max=1 >0) noBreak * ]
    if "`labels'"!="" & `"`labels2'"'=="" {
        local labels2 `"" # ""'
    }
    if "`gap'"!="" local gap2 0
    else if "`gap2'"=="" {
        if "`noeqlabels'"!="" local gap2 0
        else                  local gap2 1
    }
    if "`asheadings'"!="" {
        c_local hoff    `offset'
        c_local hgap    `gap2'
        c_local htrunc  `truncate'
        c_local hwrap   `wrap'
        c_local hbreak  `break'
        c_local hopts   `options'
        c_local eqgap   0
    }
    else {
        if `offset'!=0  {
            di as err "eqlabels(): offset() only allowed with asheadings"
            exit 198
        }
        c_local eqgap   `gap2'
        c_local eqtrunc `truncate'
        c_local eqwrap  `wrap'
        c_local eqbreak `break'
        c_local eqopts  `options'
    }
    c_local eqxlab      `"`labels2'"'
    c_local eqlabels    `"`eqlabels'"'
    c_local eqashead    `asheadings'
end

program parse_headings
    mata: coefplot_parsecomma("headings", "0", "0")
    syntax [, OFFset(real 0) noGap Gap2(real 1)     ///
        Truncate(numlist integer max=1 >0)          ///
        Wrap(numlist integer max=1 >0) noBreak * ]
    if "`gap'"!="" local gap2 0
    c_local headings `"`headings'"'
    c_local hoff   `offset'
    c_local hgap   `gap2'
    c_local htrunc `truncate'
    c_local hwrap  `wrap'
    c_local hbreak `break'
    c_local hopts  `options'
end

program parse_groups
    mata: coefplot_parsecomma("groups", "0", "0")
    syntax [, noGap Gap2(real 1)                ///
        Truncate(numlist integer max=1 >0)      ///
        Wrap(numlist integer max=1 >0) noBreak * ]
    if "`gap'"!="" local gap2 0
    c_local groups  `"`groups'"'
    c_local ggap    `gap2'
    c_local gtrunc  `truncate'
    c_local gwrap   `wrap'
    c_local gbreak  `break'
    c_local gopts   `options'
end

program parse_plotlabels
    mata: coefplot_parsecomma("plotlabels", "0", "0")
    syntax [, Truncate(numlist integer max=1 >0) ///
        Wrap(numlist integer max=1 >0) noBreak ]
    c_local plotlabels  `"`plotlabels'"'
    c_local pltrunc `truncate'
    c_local plwrap  `wrap'
    c_local plbreak `break'
end

program parse_bylabels
    mata: coefplot_parsecomma("bylabels", "0", "0")
    syntax [, Truncate(numlist integer max=1 >0) ///
        Wrap(numlist integer max=1 >0) noBreak ]
    c_local bylabels  `"`bylabels'"'
    c_local bltrunc `truncate'
    c_local blwrap  `wrap'
    c_local blbreak `break'
end

program parse_addplot
    _parse expand addplot addplotopts : 0 , ///
        common(below by() nodraw draw name() SAVing() play())
    forv i=1/`addplot_n' {
        local addplot `addplot' (`addplot_`i'')
    }
    local addplot `addplot' `addplotopts_if' `addplotopts_in'
    _parse combop addplotopts_op : addplotopts_op, option(below) opsin rightmost
    parse_addplotopts, `addplotopts_op' // returns below, options
    if `"`options'"'!="" {
        local addplot `addplot', `options'
    }
    c_local addplot `addplot'
    c_local addplotbelow `below'
end
program parse_addplotopts
    syntax [, below by(passthru) NODRAW draw name(passthru) ///
        SAVing(passthru) play(passthru) * ]
    foreach opt in nodraw draw {
        if `"``opt''"'!="" {
            di as err "`opt' not allowed within addplot()"
            exit 198
        }
    }
    foreach opt in by name saving play {
        if `"``opt''"'!="" {
            di as err "`opt'() not allowed within addplot()"
            exit 198
        }
    }
    local options: subinstr local options "below" "", all word // to be sure
    c_local below `below'
    c_local options `options'
end

program parse_byopts
    syntax [, LEGend(passthru) * ]
    c_local bylegend `legend'
    c_local byopts `options'
end

program merge_subgropts
    merge_plotopts `macval(0)' // returns modelopts2, plotopts, options, _opts0
    _merge_subgropts, `options'
    _merge_subgropts _opt0_, `_opts0'
    if `"`_opt0_options'"'!="" error 198
    if `"`bylabel'"'!="" {
        c_local subgropts `bylabel'
    }
    else {
        c_local subgropts `_opt0_bylabel'
    }
    c_local modelopts1  `macval(modelopts2)'
    c_local plotopts1   `plotopts'
    c_local twplotopts1 `options'
end
program _merge_subgropts
    syntax [anything] [, BYLABel(passthru) * ]
    c_local `anything'bylabel `bylabel'
    c_local `anything'options `options'
end

program parse_subgropts
    syntax anything [, BYLABel(str asis) ]
    gettoken lbl rest : bylabel, qed(qed)    // remove outer quotes
    if `"`lbl'"'!="" & `"`rest'"'=="" & `qed' {
        local bylabel `"`lbl'"'
    }
    mata: coefplot_add_label(COEFPLOT_STRUCT, "by", `anything', "bylabel", 0)
end

program parse_plots // input: "j (plot) (plot) ..., opts"
    gettoken j 0 : 0
    _parse comma 0 opts : 0                 // get opts
    gettoken comma opts : opts, parse(",")  // strip comma
    local i 0
    while (`"`macval(0)'"'!="") {
        gettoken plot 0: 0, match(hasparen)
        local estexpand 0                   // expand wildcards?
        if `"`hasparen'"'=="" {             // - not if "(...)"
            if strpos(`"`plot'"',"(")==0 {  // - not it "mat(...)"
                if strpos(`"`plot'"',"*") | strpos(`"`plot'"',"?") {
                    local estexpand 1
                }
            }
        }
        if `estexpand' {
            qui estimates dir `plot'
            foreach plot in `r(names)' {
                local ++i
                c_local plot_`j'_`i' `"`macval(plot)'"'
            }
        }
        else {
            local ++i
            c_local plot_`j'_`i' `"`macval(plot)'"'
        }
    }
    if `i'==0 {                             // check if empty
        local i 1
        c_local plot_`j'_1 "."              // use active model
    }
    c_local n_plots_`j' `i'
    c_local opts `macval(opts)'
end

program parse_get_popt_i
    gettoken i 0 : 0, parse(",")
    syntax [, p`i'(str asis) * ]
    c_local plotopts `macval(p`i')'
    c_local twplotopts0 `macval(options)'
end

program combine_plotopts
    syntax [, _opts0(str asis) * ]
    _merge_plotopts, `macval(options)'
    _merge_plotopts _opt0_, `macval(_opts0)'
    if `"`mlabels'"'!="" local _opt0_mlabel
    if `"`mlabel'"'!=""  local _opt0_mlabels
    if `"`cismooths'"'!="" local _opt0_cismooth
    if `"`cismooth'"'!=""  local _opt0_cismooths
    if `"`nokey'`key'`key2'"'!="" {
        local _opt0_nokey
        local _opt0_key
        local _opt0_key2
    }
    local 0
    foreach opt of local opts { // opts is set by _merge_plotopts
        if `"``opt''"'!="" {
            local 0 `0' ``opt''
        }
        else {
            local 0 `0' `_opt0_`opt''
        }
    }
    c_local plotopts `0'
    c_local options `macval(options)'
end

program merge_plotopts
    merge_modelopts `macval(0)' // returns modelopts, mlabels2, options, _opts0
    _merge_plotopts, `options'
    _merge_plotopts _opt0_, `_opts0'
    if `"`mlabels'"'!="" local _opt0_mlabel
    if `"`mlabel'"'!=""  local _opt0_mlabels
    if `"`mlabels'`mlabel'"'!="" local mlabels2
    if `"`cismooths'"'!="" local _opt0_cismooth
    if `"`cismooth'"'!=""  local _opt0_cismooths
    if `"`nokey'`key'`key2'"'!="" {
        local _opt0_nokey
        local _opt0_key
        local _opt0_key2
    }
    local 0
    foreach opt of local opts { // opts is set by _merge_plotopts
        if `"``opt''"'!="" {
            local 0 `0' ``opt''
        }
        else {
            local 0 `0' `_opt0_`opt''
        }
    }
    c_local modelopts2 `macval(modelopts)' `mlabels2'
    c_local plotopts `0'
    c_local options `options'
    c_local _opts0 `_opt0_options'
end

program _merge_plotopts
    syntax [anything] [,                ///
        LABel(passthru)                 ///
        offset(passthru)                ///
        PSTYle(passthru)                ///
        AXis(passthru)                  ///
        recast(passthru)                ///
        MLabels MLabel(passthru)        ///
        MLABVposition(passthru)         ///
        cionly                          ///
        citop                           ///
        CISmooths CISmooth(passthru)    ///
        CIOPts(passthru)                ///
        CIREcast(passthru)              ///
        IFopt(passthru)                 ///
        Weightopt(passthru)             ///
        NOKEY key KEY2(passthru)        ///
        * ]
    if `"`mlabel'"'!="" local mlabels
    if `"`cismooth'"'!="" local cismooths
    local opts              ///
        label               ///
        offset              ///
        pstyle              ///
        axis                ///
        recast              ///
        mlabels mlabel      ///
        mlabvposition       ///
        cionly              ///
        citop               ///
        cismooths cismooth  ///
        ciopts              ///
        cirecast            ///
        ifopt               ///
        weightopt           ///
        nokey key key2
    foreach opt of local opts {
        c_local `anything'`opt' ``opt''
    }
    c_local `anything'options `options'
    c_local opts `opts'
end

program parse_plotopts
    syntax anything [,                      ///
        LABel(str asis)                     ///
        offset(str asis)                    ///
        PSTYle(passthru)                    ///
        AXis(numlist integer max=1 >0 <10)  ///
        recast(str)                         ///
        MLabels MLabel(passthru)            ///
        MLABVposition(passthru)             ///
        cionly                              ///
        citop                               ///
        CISmooths CISmooth(str asis)        ///
        CIOPts(str asis)                    ///
        CIREcast(str)                       ///
        IFopt(str asis)                     ///
        Weightopt(str asis)                 ///
        NOKEY key KEY2(str)                 ///
        ]
    if `"`label'"'!="" {
        gettoken lbl rest : label, qed(qed) // remove outer quotes
        if `"`lbl'"'!="" & `"`rest'"'=="" & `qed' {
            local label `"`lbl'"'
        }
        mata: coefplot_add_label(COEFPLOT_STRUCT, "plot", `anything', "label", 1)
    }
    if `"`mlabels'"'!="" local mlabel mlabel(@b)
    if `"`cismooths'"'!="" local cismooth cismooth
    if `"`cirecast'"'!="" local cirecast recast(`cirecast')
    if `"`offset'"'!="" {
        capt parse_offset `offset'
        if _rc {
            di as err `"invalid offset(): `offset'"'
            exit 198
        }
    }
    if `"`ifopt'"'!="" local ifopt `" & (`ifopt')"'
    if `"`weightopt'"'!="" local weightopt `" [aw=`weightopt']"'
    local key0 0 // default
    if `"`nokey'"'!="" local key0 -1 // suppress key
    if `"`key'`key2'"'!="" {
        if `key0'<0 {
            di as err "nokey and key() not both allowed"
            exit 198
        }
        if `"`key2'"'!="" {
            gettoken key2ci key2 : key2
            if `"`key2ci'"'!="ci" {
                di as err "invalid syntax in key()"
                exit 198
            }
            if `"`key2'"'!="" {
                capt confirm integer number `key2'
                if _rc==0 {
                    capt assert (`key2'>0)
                }
                if _rc {
                    di as err "invalid syntax in key()"
                    exit 198
                }
            }
            else local key2 1
            local key0 `key2'
        }
    }
    local key `key0'
    foreach opt in      ///
        offset          ///
        pstyle          ///
        axis            ///
        recast          ///
        mlabel          ///
        mlabvposition   ///
        cionly          ///
        citop           ///
        cismooth        ///
        ciopts          ///
        cirecast        ///
        ifopt           ///
        weightopt       ///
        key             ///
    {
        c_local `opt'_`anything' `"``opt''"'
    }
end

program parse_offset
    local offset = `0'
    local 0 `", offset(`offset')"'
    syntax [, offset(numlist max=1) ]
    c_local offset `offset'
end

program parse_models // input: "j k model \ model ..., opts"
    gettoken j 0 : 0
    gettoken k 0 : 0
    local i 0
    local empty 1
    while (`"`macval(0)'"'!="") {
        gettoken model 0 : 0, parse("\") bind
        if `"`macval(model)'"'=="\" {
            if `empty' {
                local ++i
                c_local model_`j'_`k'_`i' "."       // use active model
            }
            else local empty 1
            continue
        }
        _parse comma model opts : model
        if `"`macval(0)'"'=="" {                    // get plotopts if last
            gettoken comma plotopts : opts, parse(",")  // strip comma
            local opts
        }
        if `"`model'`macval(opts)'"'!="" {          // skip last if empty
            local empty 0
            if strpos(`"`model'"',"(") {            // mat(...)
                local ++i
                c_local model_`j'_`k'_`i' `"`model'`macval(opts)'"'
            }
            else {
                if `"`model'"'=="" local model .
                foreach ename of local model {
                    if strpos(`"`ename'"',"*") | strpos(`"`ename'"',"?") {
                        qui estimates dir `ename'
                        local ename `"`r(names)'"'
                    }
                    foreach mm of local ename {
                        local ++i
                        c_local model_`j'_`k'_`i' `"`mm'`macval(opts)'"'
                    }
                }
            }
        }
    }
    if `i'==0 {                                     // check if empty
        local i 1
        c_local model_`j'_`k'_1 "."                 // use active model
    }
    c_local n_models_`j'_`k' `i'
    c_local opts `macval(plotopts)'
end

program parse_model // input: "name, opts" or "matrix(name[...]), opts"
    _parse comma 0 opts : 0
    gettoken comma opts : opts, parse(",")  // strip comma
    capt parse_model_matrix, `0' // returns model, matrix
    if _rc {
        gettoken model rest : 0
        if `"`rest'"'!="" {
            di as err `"`rest' not allowed"'
            exit 198
        }
        if `"`model'"'=="" local model .
    }
    c_local model `"`model'"'
    c_local matrix `"`matrix'"'
    c_local opts `macval(opts)'
end
program parse_model_matrix
    syntax, Matrix(str)
    gettoken model : matrix, parse(" [")
    if `"`model'"'=="" error 198
    c_local model `"`model'"'
    c_local matrix `"`matrix'"'
end

program merge_modelopts
    syntax [, _opts0(str asis) * ]
    _merge_modelopts, `macval(options)'
    _merge_modelopts _opt0_, `macval(_opts0)'
    if `"`sename'"'!="" local _opt0_vname
    if `"`vname'"'!=""  local _opt0_sename
    if `"`asequation'"'!="" local _opt0_asequation2
    local 0
    foreach opt of local opts { // opts is set by _merge_modelopts
        if `"``opt''"'!="" {
            if "`opt'"=="mlabels2" {
                c_local mlabels2 ``opt''
            }
            else {
                local 0 `macval(0)' `macval(`opt')'
            }
        }
        else {
            if "`opt'"=="mlabels2" {
                c_local mlabels2 `_opt0_`opt''
            }
            else {
                local 0 `macval(0)' `macval(_opt0_`opt')'
            }
        }
    }
    c_local modelopts `macval(0)'
    c_local options `options'
    c_local _opts0 `_opt0_options'
end
program _merge_modelopts
    syntax [anything] [,                 ///
        OMITted                          ///
        BASElevels                       ///
        Bname(passthru)                  ///
        ATname ATname2(passthru)         ///
        SWAPnames                        ///
        keep(passthru)                   ///
        drop(passthru)                   ///
        rename(passthru)                 ///
        EQREName(passthru)               ///
        ASEQuation ASEQuation2(passthru) ///
        eform EFORM2(passthru)           ///
        rescale(passthru)                ///
        TRANSform(passthru)              ///
        MLABELS2(passthru)               ///
        noci                             ///
        Levels(passthru)                 ///
        CIname(passthru)                 ///
        Vname(passthru)                  ///
        SEname(passthru)                 ///
        DFname(passthru)                 ///
        citype(passthru)                 ///
        aux(passthru)                    ///
        * ]
    if "`atname'"!="" & `"`atname2'"'=="" local atname2 "atname2(at)"
    if `"`asequation2'"'!="" local asequation
    if "`eform'"!="" & `"`eform2'"'==""   local eform2 "eform2(*)"
    if `"`sename'"'!="" & `"`vname'"'!="" {
        di as err "se() and v() not both allowed"
        exit 198
    }
    local opts      ///
        omitted     ///
        baselevels  ///
        bname       ///
        atname2     ///
        swapnames   ///
        keep        ///
        drop        ///
        rename      ///
        eqrename    ///
        asequation  ///
        asequation2 ///
        eform2      ///
        rescale     ///
        transform   ///
        mlabels2    ///
        ci          ///
        levels      ///
        ciname      ///
        vname       ///
        sename      ///
        dfname      ///
        citype      ///
        aux
    foreach opt of local opts {
        c_local `anything'`opt' `macval(`opt')'
    }
    c_local `anything'options `options'
    c_local opts `opts'
end

program collect_coefs
    gettoken model   0 : 0
    gettoken matrix  0 : 0  // matrix mode?
    gettoken atmode  0 : 0  // whether at() is used
    gettoken i       0 : 0  // plot number
    gettoken j       0 : 0  // subgraph number
    gettoken cis     0 : 0  // cismooth levels
    
    // get options
    merge_modelopts `macval(0)' // returns modelopts, mlabels2, options, _opts0
    local 0 , `macval(modelopts)' `mlabels2' `options' `_opts0'
    syntax [,                       ///
        OMITted                     ///
        BASElevels                  ///
        Bname(str)                  ///
        ATname2(str)                ///
        SWAPnames                   ///
        keep(str asis)              ///
        drop(str asis)              ///
        rename(str asis)            ///
        EQREName(str asis)          ///
        ASEQuation ASEQuation2(str) ///
        EFORM2(str asis)            ///
        rescale(str asis)           ///
        TRANSform(str asis)         ///
        MLABELS2(str asis)          ///
        noci                        ///
        Levels(numlist)             ///
        CIname(str asis)            ///
        Vname(str)                  ///
        SEname(str)                 ///
        DFname(str)                 ///
        citype(str)                 ///
        aux(str)                    ///
        ]
    if `"`atname2'"'!="" {
        if "`atmode'"=="0" {
            di as err "must specify at for all or none"
            exit 198
        }
        local atmode 1
        parse_at_transform `atname2' // replaces atname2, returns attransform
        capt parse_at_is_matrix, `atname2'  // syntax at(matrix(...))
    }
    else {
        if "`atmode'"=="1" {
            di as err "must specify at for all or none"
            exit 198
        }
        local atmode 0
    }
    if `"`macval(rename)'"'!="" {
        parse_rename `macval(rename)'
    }
    if `"`macval(eqrename)'"'!="" {
        parse_eqrename `macval(eqrename)'
    }
    if "`cis'"!="" local ci // disable noci
    parse_cilevels `"`levels'"' `"`ciname'"' "`cis'" // returns levels, ciname
    parse_citype, `citype' // replaces citype
    if `"`matrix'"'!="" local bname `"`matrix'"'
    if "`asequation'"!="" & `"`asequation2'"'=="" {
        if "`model'"=="." local asequation2 "_"
        else              local asequation2 `"`model'"'
    }
    if `"`aux'"'!="" {
        parse_aux `aux' // returns aux
    }
    // collect results
    local empty 0
    local equation
    mata: coefplot_keepdrop(COEFPLOT_STRUCT) // returns empty, n_ci, equation
    if `empty' {
        local n_ci 0
        di as txt ///
            `"(`model': no coefficients found, all dropped, or none kept)"'
    }
    
    // returns
    c_local equation    `equation'
    c_local atmode      `atmode'
    c_local n_ci        `n_ci'
    if `"`mlabels2'"'!="" {
        c_local mlabel_`i' mlabel(@mlbl)
        c_local mlabvposition_`i' mlabvposition(@mlpos)
    }
end

program parse_at_transform
    syntax [anything] [, Transform(str) ]
    if `"`anything'"'=="" local anything at
    c_local atname2 `"`anything'"'
    c_local attransform `"`transform'"'
end

program parse_at_is_matrix
    syntax, Matrix(str)
    c_local atname2 `"`matrix'"'
    c_local atismatrix "matrix"
end

program parse_rename
    mata: coefplot_parsecomma("rename", "0", "0")
    syntax [, Regex]
    c_local `eq'rename `"`macval(rename)'"'
    c_local `eq'renameregex `regex'
end

program parse_eqrename
    mata: coefplot_parsecomma("rename", "0", "0")
    syntax [, Regex]
    c_local eqrename `"`macval(rename)'"'
    c_local eqrenameregex `regex'
end

program parse_aux // remove spaces in aux()
    gettoken s 0 : 0, bind
    while (`"`s'"'!="") {
        local s = subinstr(`"`s'"', " ", "", .)
        if substr(`"`s'"', 1, 1)=="[" {
            local aux `aux'`s'
        }
        else {
            local aux `aux' `s'
        }
        gettoken s 0 : 0, bind
    }
    c_local aux `"`aux'"'
end

program parse_citype
    local citypes logit probit atanh log
    syntax [, `citypes' NORMal ]
    local citype `logit' `probit' `atanh' `log' `normal'
    if `: list sizeof citype'>1 {
        di as err "citype(): only one of logit, probit, atanh, log, and normal allowed"
        exit 198
    }
    local citype: list posof "`citype'" in citypes
    c_local citype `citype'
end

program parse_cilevels
    args levels names cis
    if "`cis'"!="" {
        foreach level of local cis {
            local ll `ll' `level'
            local nn `"`nn'`space'"""'
            local space " "
        }
    }
    while (1) {
        gettoken l levels : levels
        gettoken n names  : names, match(paren)
        if `"`l'`n'"'=="" {
            continue, break
        }
        if `"`n'"'=="" {
            parse_cilevel, levels(`l') // returns level
            local ll `ll' `level'
            local nn `"`nn'`space'"""'
        }
        else {
            capt confirm number `n'
            if _rc {
                gettoken empty : n
                if `"`empty'"'=="" {    // set default level
                    parse_cilevel       // returns level
                    local ll `ll' `level'
                }
                else {
                    local ll `ll' .
                }
                local nn `"`nn'`space'`"`n'"'"'
            }
            else {
                parse_cilevel, levels(`n') // returns level
                local ll `ll' `level'
                local nn `"`nn'`space'"""'
            }
        }
        local space " "
    }
    if `"`ll'"'=="" {       // set default level
        parse_cilevel       // returns level
        local ll `level'
        local nn `""""'
    }
    c_local levels `ll'
    c_local ciname `"`nn'"'
end
program parse_cilevel
    syntax [, level(cilevel) levels(numlist min=1 max=1 >0 <100) ]
    if `"`levels'"'=="" {
        c_local level `level'
    }
    else {
        c_local level `levels'
    }
end

program parse_cismooth
    syntax anything(name=j) [, Color(str) PSTYle(passthru) n(int 50) ///
        Intensity(numlist min=2 max=2 >=0 <=100) ///
        LWidth(numlist min=2 max=2 >=0 <=1000) ]
    if `n'<4 {
        di as err "cismooth(n()) must be >= 4"
        exit 198
    }
    if "`intensity'"!="" {
        gettoken imin imax : intensity
    }
    else {
        local imin = (1+3) / (ceil(`n'/2)+3) * 100
        local imax 100
    }
    if "`lwidth'"!="" {
        gettoken wmin wmax : lwidth
        local lwidth
    }
    else {
        local wmin 2
        local wmax 15
    }
    local d = 100/`n'
    local lmax = 100 - `d'/2
    forv i = 1/`n' {
        if mod(`i',2)==0 {
            local l = `d'/2 + (`i'/2-1)*`d'
        }
        else {
            local l = `d'/2 + (`n'-`i'/2-.5)*`d'
        }
        local levels `levels' `:di `l''
        local inten = (`imin' + (`imax'-`imin') / (ceil(`n'/2)-1) * ///
            (ceil(`i'/2)-1))/100
        local intens `intens' `:di `inten''
        local lw = 4 + (`l'-1)/(`lmax'-1) * (100-4) // if n=50 max lw is 25
        local lw = 100 / `lw'
        local lw = `wmin' + (`lw'-1) / (25-1) * (`wmax'-`wmin')
        local lwidth `lwidth' `:di `lw''
    }
    c_local cis_levels_`j'  `levels'
    c_local cis_n_`j'       `n'
    c_local cis_intens_`j'  `intens'
    c_local cis_lwidth_`j'  `lwidth'
    c_local cis_color_`j'   `"`color'"'
    c_local cis_pstyle_`j'  `"`pstyle'"'
end

program get_pstyle_id
    syntax anything(name=i) [, PSTYle(str) ]
    if `"`pstyle'"'=="" {
        local id `i'
    }
    else {
        local id = substr(`"`pstyle'"', 2, 2) // p##...
        capt confirm number `id'
        if _rc {
            local id = substr(`"`pstyle'"', 2, 1) // p#...
            capt confirm number `id'
        }
        if _rc { // invalid pstyle
            local id `i'
        }
    }
    c_local pstyle_id `id'
end

program parse_ciopts_nocilwincr
    syntax anything(name=i) [, recast(str) LWidth(str) * ]
    if `"`recast'`lwidth'"'!="" {
        c_local nocilwincr_`i' 1
    }
end

program parse_ciopts_recast_pstyle
    syntax [, recast(str) PSTYle(str) * ]
    if `"`pstyle'"'!="" {
        local options `options' pstyle(`pstyle')
    }
    c_local cirecast `"`recast'"'
    c_local cipstyle `"`pstyle'"'
    c_local ciopts `options'
end

program set_pstyle
    args i recast
    if `"`recast'"'=="" {
        c_local pstyle pstyle(p`i')
        exit
    }
    if inlist(`"`recast'"', "line", "rline") ///
        c_local pstyle pstyle(p`i'line)
    else if inlist(`"`recast'"', "area", "rarea") ///
        c_local pstyle pstyle(p`i'area)
    else if inlist(`"`recast'"', "bar", "rbar") ///
        c_local pstyle pstyle(p`i'bar)
    else if inlist(`"`recast'"', "dot") /// 
        c_local pstyle pstyle(p`i'dot)
    else c_local pstyle pstyle(p`i')
end

program parse_ciopts
    gettoken j 0 : 0
    gettoken n 0 : 0
    gettoken opt 0 : 0, bind
    local opts
    while (`"`opt'"'!="") { // get rid of possible spaces between opt and ()
        gettoken paren: opt, parse("(")
        if `"`paren'"'=="(" {
            local opts `opts'`opt'
        }
        else {
            local opts `opts' `opt'
        }
        gettoken opt 0 : 0, bind
    }
    local ciopts `", `opts'"'
    gettoken opt opts : opts, bind
    local i 0
    while (`"`opt'"'!="") {
        local ++i
        gettoken optname optcontents : opt, parse("(")
        if `"`optcontents'"'=="" {
            gettoken opt opts : opts, bind
            continue
        }
        _parse factor ciopts : ciopts, option(`optname') to(`optname'(X))
        gettoken opt opts : opts, bind
    }
    _parse factordot ciopts : ciopts, n(`n')
    // _parse combine only works up to p20
    gettoken opt ciopts : ciopts // get rid of comma
    gettoken opt ciopts : ciopts, bind // get first opt
    while (`"`opt'"'!="") {
        mata: coefplot_combine_ciopts() // appends opt_# or options
        gettoken opt ciopts : ciopts, bind // get next opt
    }
    forv i=1/`n' {
        c_local ciopts_`j'_`i' `opt_`i'' `options'
    }
end

program parse_mlabel_exp
    syntax [ , MLabel(str asis) ]
    c_local mlblexp `"`mlabel'"'
end

program coeflbls
    args labels interact
    mata: coefplot_get_coefs(COEFPLOT_STRUCT)
    local i 0
    foreach v of local coefs {
        local ++i
        if (`"`v'"'=="") continue   // gap from order()
        if (`"`v'"'==`"`last'"') {
            mata: coefplot_add_label(COEFPLOT_STRUCT, "coef", `i', "coeflbl", 1)
            continue
        }
        mata: coefplot_get_coeflbl(COEFPLOT_STRUCT, `i')
        if `"`coeflbl'"'=="" {
            if  `"`labels'"'!="" {
                local coeflbl `"`v'"'
            }
            else {
                compile_xlabel, v(`v') interact(`interact') // returns coeflbl
            }
        }
        mata: coefplot_add_label(COEFPLOT_STRUCT, "coef", `i', "coeflbl", 1)
    }
end

program compile_xlabel
    syntax [, v(str) interact(str) ]
    gettoken vi vrest: v, parse("#")
    while (`"`vi'"') !="" {
        local xlabi
        if `"`vi'"'=="#" {
            local xlabi `"`interact'"'
        }
        else if strpos(`"`vi'"',".")==0 {
            capt confirm variable `vi', exact
            if _rc==0 {
                local xlabi: var lab `vi'
            }
            if `"`xlabi'"'=="" {
                local xlabi `"`vi'"'
            }
        }
        else {
            gettoken li vii : vi, parse(".")
            gettoken dot vii : vii, parse(".")
            capt confirm variable `vii', exact
            if _rc==0 & `"`vii'"'!="" {
                capt confirm number `li'
                if _rc {
                    local xlabi: var lab `vii'
                    if (`"`xlabi'"'=="") local xlabi `"`vii'"'
                    if (substr(`"`li'"',1,1)=="c") ///
                                         local li = substr(`"`li'"',2,.)
                    if (`"`li'"'!="")    local xlabi `"`li'.`xlabi'"'
                }
                else {
                    local viilab : value label `vii'
                    if `"`viilab'"'!="" {
                        local xlabi: label `viilab' `li'
                    }
                    else {
                        local viilab: var lab `vii'
                        if (`"`viilab'"'=="") local viilab `"`vii'"'
                        local xlabi `"`viilab'=`li'"'
                    }
                }
            }
            if `"`xlabi'"'=="" {
                local xlabi `"`vi'"'
            }
        }
        local xlab `"`xlab'`xlabi'"'
        gettoken vi vrest: vrest, parse("#")
    }
    c_local coeflbl `"`xlab'"'
end

program set_by_and_plot_labels
    args plot by
    // plot
    qui levelsof `plot', local(levels)
    foreach l of local levels {
        mata: coefplot_get_plotlbl(COEFPLOT_STRUCT, `l') // returns plotlbl
        lab def `plot' `l' `"`plotlbl'"', add
    }
    lab val `plot' `plot', nofix
    // by
    qui levelsof `by', local(levels)
    foreach l of local levels {
        mata: coefplot_get_bylbl(COEFPLOT_STRUCT, `l') // returns bylbl
        lab def `by' `l' `"`bylbl'"', add
    }
    lab val `by' `by', nofix
end

program get_axis_labels
    args x eq grp grid groups
    // eqlabels
    qui levelsof `eq', local(levels)
    local j 0
    foreach l of local levels {
        local ++j
        su `x' if `eq'==`l', meanonly
        local pos: di %9.0g r(min) + (r(max)-r(min))/2
        local pos: list retok pos
        mata: coefplot_get_eqlbl(COEFPLOT_STRUCT, `j') // returns eqlbl
        local eqlabels `eqlabels' `pos' `"`eqlbl'"'
    }
    c_local eqlabels `"`eqlabels'"'
    // groups
    if `"`groups'"'!="" {
        local j 0
        foreach glab of local groups {
            local ++j
            foreach l of local levels { // equations (from above)
                su `x' if `grp'==`j' & `eq'==`l', mean
                if r(N)>0 {
                    local pos: di %9.0g r(min) + (r(max)-r(min))/2
                    local pos: list retok pos
                    local glbls `glbls' `pos' `"`glab'"'
                }
            }
        }
        c_local groups `glbls'
    }
    // ticks and xlabels
    mata: coefplot_ticks_and_labels(COEFPLOT_STRUCT)
    c_local xrange `xrange'
    c_local xlabels `xlabels'
    c_local xgrid `xgrid'
end

program merge_eqlabels_hlbls
    args eqlab hlab
    gettoken lab eqlab : eqlab  // skip value
    gettoken lab eqlab : eqlab, quotes
    while (`"`lab'"'!="") {
        gettoken val hlab : hlab
        local hlbls `"`hlbls'`val' `lab' "'
        gettoken lab eqlab : eqlab  // skip value
        gettoken lab eqlab : eqlab, quotes
    }
    c_local hlbls    `"`hlbls'"'
    c_local eqlabels ""
end

program truncwrap_vlabels
    args v n trunc wrap break
    forv i = 1/`n' {
        local lbl: label `v' `i'
        truncwrap_label lbl "`trunc'" "`wrap'" "`break'" `"`lbl'"'
            // may fail if label contains compound quotes
        lab def `v' `i' `"`lbl'"', modify
    }
end

program truncwrap_labels
    args local trunc wrap break lbls
    local labels
    local skip 1
    foreach lbl of local lbls {
        if `skip' {
            local labels `labels' `lbl'
            local skip 0
            continue
        }
        truncwrap_label lbl "`trunc'" "`wrap'" "`break'" `"`lbl'"'
            // may fail if label contains compound quotes
        local labels `labels' `"`lbl'"'
        local skip 1
    }
    c_local `local' `"`labels'"'
end

program truncwrap_label
    args local trunc wrap break lbl
    capt mata: coefplot_lbl_is_multiline() // error if label is multiline
    if _rc exit
    if "`break'"!="" local break ", `break'"
    if "`trunc'"!="" {
        local lbl: piece 1 `trunc' of `"`lbl'"'`break'
        capt truncwrap_label_check_quotes `"`lbl'"'
        if _rc exit
    }
    if "`wrap'"!="" {
        local i 0
        local space
        while (1) {
            local ++i
            local piece: piece `i' `wrap' of `"`lbl'"'`break'
            capt truncwrap_label_check_quotes `"`piece'"'
            if _rc exit
            if `"`piece'"'=="" {
                if `i'==1 {
                    local newlbl `"`lbl'"'  // lbl is empty
                }
                else if `i'==2 { // workaround for multiline label graph bug
                    local newlbl `"`newlbl'`space'"""'
                }
                continue, break
            }
            local newlbl `"`newlbl'`space'`"`piece'"'"'
            local space " "
        }
        local lbl `"`newlbl'"'
    }
    c_local `local' `"`lbl'"'
end
program truncwrap_label_check_quotes // checks for unmatched compound quotes
    syntax [anything]
end

program set_labels
    args v n lbls
    local i 0
    foreach lbl of local lbls {
        local ++i
        if `i'>`n' continue, break
        lab def `v' `i' `"`lbl'"', modify
    }
end

program reset_xlabels
    args lbls xlbls
    local labels
    local skip 1
    foreach lbl of local xlbls {
        if `skip' {
            local labels `labels' `lbl'
            local skip 0
            continue
        }
        if `"`lbls'"'!="" {
            gettoken lbl lbls : lbls
        }
        local labels `labels' `"`lbl'"'
        local skip 1
    }
    c_local xlabels `"`labels'"'
end

version 11
mata:
mata set matastrict on

struct coefplot_struct
{
    real scalar      r, xmin
                     
    real colvector   b, V, se, t, df, pval, at, plot, by, eq, grp, mlpos
    real matrix      ci, aux
                     
    string colvector coefnm, eqnm, coeflbl, eqlbl, plotlbl, bylbl, mlbl, trans
}

struct coefplot_struct scalar coefplot_struct_init()
{
    struct coefplot_struct scalar C
    
    return(C)
}

void coefplot_keepdrop(struct coefplot_struct scalar C)
{
    real scalar         i, j, level, r, brow, bcol, row, col, emode, 
                        firsteqonly, meqs, citype
    real colvector      b, p, at, V, se, t, df, pval, mlpos
    real matrix         ci, aux, tmp
    string scalar       model, bname, cname, rename, attrans, attmp
    string rowvector    keep, drop, cnames, levels, llul
    string colvector    eqnm, coefnm, mlbl, trans

    // get results
    emode = (st_local("matrix")=="")
    // - coefficients
    model = st_local("model")
    bname = st_local("bname")
    if (bname=="") {
        if (st_global("e(mi)")=="mi") bname = "b_mi"
        else                          bname = "b"
    }
    coefplot_parse_input(model, "b", bname, brow, bcol)
    if (emode) bname = "e(" + bname + ")"
    b = st_matrix(bname)
    if (b==J(0,0,.)) {
        st_local("empty", "1")
        return
    }
    coefplot_invalid_subscript(model, bname, b, brow, bcol)
    b = b[brow, bcol]
    if (brow<.) {
        b = b'
        eqnm   = st_matrixcolstripe(bname)[.,1]
        coefnm = st_matrixcolstripe(bname)[.,2]
    }
    else {
        eqnm   = st_matrixrowstripe(bname)[.,1]
        coefnm = st_matrixrowstripe(bname)[.,2]
    }
    _editvalue(eqnm, "", "_")
    meqs = !allof(eqnm, eqnm[1])
    r = rows(b)
    // - get variances and standard errors
    se = J(r,1,.)
    V  = J(r,1,.)
    if ((cname = st_local("sename"))!="") {
        coefplot_parse_cname(model, "se", cname, row, col, emode, 0, bname, brow, bcol)
        tmp = st_matrix(cname)
        if (coefplot_notfound(model, cname, tmp)==0) {
            coefplot_invalid_subscript(model, cname, tmp, row, col)
            tmp = tmp[row, col]
            if (row<.) tmp = tmp'
            if (coefplot_notconformable(model, cname, tmp, r, 1)==0) {
                se = tmp
                V  = tmp:^2
            }
        }
    }
    else if ((cname = st_local("vname"))!="") {
        if (emode) cname = "e(" + cname + ")"
        tmp = st_matrix(cname)
        if (coefplot_notfound(model, cname, tmp)==0) {
            if (coefplot_notconformable(model, cname, tmp, r, r)==0) {
                V  = diagonal(tmp)
                se = sqrt(V)
            }
        }
    }
    else if (emode){
        if (st_global("e(mi)")=="mi") cname = "e(V_mi)"
        else                          cname = "e(V)"
        tmp = st_matrix(cname)
        if (coefplot_notfound(model, cname, tmp, 1)==0) {
            if (coefplot_notconformable(model, cname, tmp, r, r, 1)==0) {
                V  = diagonal(tmp)
                se = sqrt(V)
            }
        }
    }
    // - get DFs
    df = J(r,1,.)
    if ((cname = st_local("dfname"))!="") {
        if (strtoreal(cname)<. | cname==".") {
            df = J(r, 1, strtoreal(cname))
        }
        else {
            coefplot_parse_input(model, "df", cname, row, col)
            if (emode) cname = "e(" + cname + ")"
            tmp = st_matrix(cname)
            if (coefplot_notfound(model, cname, tmp)==0) {
                coefplot_invalid_subscript(model, cname, tmp, row, col)
                tmp = tmp[row, col]
                if (row<.) tmp = tmp'
                if (coefplot_notconformable(model, cname, tmp, r, 1)==0) {
                    df = tmp
                }
            }
        }
    }
    else if (emode) {
        if ((st_global("e(mi)")=="mi") & 
                 (tmp=st_matrix("e(df_mi)")')!=J(0,0,.)) {
            if (coefplot_notconformable(model, "e(df_mi)", tmp, r, 1)==0) {
                df = tmp
            }
        }
        else if (st_numscalar("e(df_r)")!=J(0,0,.)) {
            df = J(r, 1, st_numscalar("e(df_r)"))
        }
    }
    // - CIs
    ci = J(r, 0, .)
    if (st_local("ci")=="") {
        cnames = tokens(st_local("ciname"))
        levels = tokens(st_local("levels"))
        citype = strtoreal(st_local("citype"))
        for (j=1; j<=cols(levels); j++) {
            ci = ci, J(r, 2, .)
            if ((cname = strtrim(cnames[j]))!="") {
                if (cols(tokens(cname))==1) {                      // "name"
                    llul = (cname+"[1]", cname+"[2]")
                }
                else {
                    if (strpos(cname, "[")==0) {                   // "ll ul"
                        llul = tokens(cname)
                        if (cols(llul)!=2) {
                            printf("{txt}(%s: invalid syntax in %s)\n", 
                                model, "ci()")
                            exit(error(198))
                        }
                    }
                    else {
                        if (strpos(cname, "]")==strlen(cname)) { // "ll ul[]"
                            llul = (substr(cname, 1, strpos(cname, " ")-1), 
                                   substr(cname, strpos(cname, " ")+1, .))
                        }
                        else {                                 // "ll[] ul[]"
                            llul = (substr(cname, 1, strpos(cname, "]")), 
                                   substr(cname, strpos(cname, "]")+1, .))
                        }
                    }
                }
                for (i=1; i<=2; i++) {
                    cname = llul[i]
                    coefplot_parse_cname(model, "ci", cname, row, col, emode, 
                        0, bname, brow, bcol)
                    tmp = st_matrix(cname)
                    if (coefplot_notfound(model, cname, tmp)==0) {
                        coefplot_invalid_subscript(model, cname, tmp, row, col)
                        tmp = tmp[row, col]
                        if (row<.) tmp = tmp'
                        if (coefplot_notconformable(model, cname, tmp, r, 1)==0) {
                            ci[,(j*2-2+i)] = tmp
                        }
                    }
                }
            }
            else {
                level = 1 - (1 - strtoreal(levels[j])/100)/2
                tmp = J(r, 1, .)
                for (i=1; i<=r; i++) {
                    tmp[i] = df[i]>2e17 ? invnormal(level) : 
                        invttail(df[i], 1-level)
                }
                if (citype==1) { // logit
                    tmp = tmp :* se :/ (b:* (1 :- b))
                    ci[|1,(j*2-1) \ .,(j*2)|] = 
                        invlogit((logit(b) :- tmp, logit(b) :+ tmp)) 
                }
                else if (citype==2) { // probit
                    tmp = tmp :* se :/ normalden(invnormal(b))
                    ci[|1,(j*2-1) \ .,(j*2)|] = 
                        normal((invnormal(b) :- tmp, invnormal(b) :+ tmp)) 
                }
                else if (citype==3) { // atanh
                    tmp = tmp :* se :/ (1 :- b:^2) // missing if b in {-1,1}
                    ci[|1,(j*2-1) \ .,(j*2)|] = 
                        tanh((atanh(b) :- tmp, atanh(b) :+ tmp))
                }
                else if (citype==4) { // log
                    tmp = tmp :* se :/ b
                    ci[|1,(j*2-1) \ .,(j*2)|] = exp((ln(b) :- tmp, ln(b) :+ tmp)) 
                }
                else { // normal
                    ci[|1,(j*2-1) \ .,(j*2)|] = (b :- tmp:*se, b :+ tmp:*se)
                }
            }
        }
    }
    // - at
    at = J(r,1,1)
    cname = st_local("atname2")
    if ((cname!="") & (cname!="_coef") & (cname!="_eq")) {
        if (    emode & 
                st_global("e(cmd)")=="margins" &
                (st_local("bname")=="" | st_local("bname")=="b") &
                (st_numscalar("e(k_at)")!=J(0,0,.) ? 
                    st_numscalar("e(k_at)")>0 : 0) &
                (cname=="at" | strtoreal(cname)<.)
            ) 
        {
            if (cname=="at") cname = "1"
            at = coefplot_get_margins_at("e", strtoreal(cname), coefnm)'
                // (modifies coefnm)
        }
        else {
            coefplot_parse_cname(model, "at", cname, row, col, emode,
                st_local("atismatrix")!="", bname, brow, bcol)
            tmp = st_matrix(cname)
            if (coefplot_notfound(model, cname, tmp)==0) {
                coefplot_invalid_subscript(model, cname, tmp, row, col)
                tmp = tmp[row, col]
                if (row<.) tmp = tmp'
                if (coefplot_notconformable(model, cname, tmp, r, 1)==0) {
                    at = tmp
                }
            }
        }
    }
    // - auxiliary variables
    cnames = tokens(st_local("aux")) // spaces in mspec not allowed
    aux    = J(r, cols(cnames), .)
    for (j=1; j<=cols(cnames); j++) {
        cname = cnames[j]
        coefplot_parse_cname(model, "aux", cname, row, col, emode, 0, bname, brow, bcol)
        tmp = st_matrix(cname)
        if (coefplot_notfound(model, cname, tmp)==0) {
            coefplot_invalid_subscript(model, cname, tmp, row, col)
            tmp = tmp[row, col]
            if (row<.) tmp = tmp'
            if (coefplot_notconformable(model, cname, tmp, r, 1)==0) {
                aux[,j] = tmp
            }
        }
    }
    
    // keep, drop, etc.
    // - clear "bn"
    coefnm = subinstr(coefnm,"bn.", ".")    // #bn.
    coefnm = subinstr(coefnm,"bno.", "o.")  // #bno.
    // - remove omitted
    p = J(r, 1, 1)
    if (st_local("omitted")=="") {
        p = p :* (!strmatch(coefnm, "*o.*"))
    }
    else {
        coefnm = substr(coefnm, 1:+2*(substr(coefnm, 1, 2):=="o."), .) // o.
        coefnm = subinstr(coefnm, "o.", ".")                           // #o.
    }
    // - remove baselevels
    if (st_local("baselevels")=="") {
        p = p :* (!strmatch(coefnm, "*b.*"))
    }
    else {
        coefnm = subinstr(coefnm, "b.", ".")    // #b.
    }
    // keep
    firsteqonly = 1
    keep = st_local("keep")
    if (keep!="") {
        keep = coefplot_parse_namelist(keep, "", "keep")
        if (!allof(keep[,1], "")) firsteqonly = 0
        keep[,1] = editvalue(keep[,1],"","*")
        p = p :* (rowsum(strmatch(eqnm, keep[,1]') :&
                         strmatch(coefnm, keep[,2]')):>0)
    }
    // drop
    drop = st_local("drop")
    if (drop!="") {
        drop = coefplot_parse_namelist(drop, "", "drop")
        if (!allof(drop[,1], "")) firsteqonly = 0
        drop[,1] = editvalue(drop[,1],"","*")
        p = p :* (!(rowsum(strmatch(eqnm, drop[,1]') :&
                           strmatch(coefnm, drop[,2]'))))
    }
    // equation
    if (firsteqonly) {
        for (i=1; i<=r; i++) { // look for first nonzero equation
            if (p[i]==1) {
                p = p :* (eqnm:==eqnm[i])
                break
            }
        }
    }
    // apply selection
    if (allof(p, 0)) {
        st_local("empty", "1")
        return
    }
    b      = select(b, p)
    V      = select(V, p)
    se     = select(se, p)
    df     = select(df, p)
    ci     = select(ci, p)
    eqnm   = select(eqnm, p)
    coefnm = select(coefnm, p)
    at     = select(at, p)
    aux    = select(aux, p)
    r      = rows(b)
    // t and p values
    t = b:/se
    pval = J(r,1,.)
    for (i=1; i<=r; i++) {
        pval[i] = (df[i]>=. ? 1-normal(abs(t[i])) : ttail(df[i],abs(t[i])))*2
    }
    
    // eform
    coefplot_eform(b, ci, eqnm, coefnm)
    
    // rescale
    coefplot_rescale(b, ci, eqnm, coefnm)
    
    // collect transforms
    trans = coefplot_collect_transforms(eqnm, coefnm)
    
    // collect mlabels
    mlbl = J(r,1,"")
    mlpos = J(r,1,.)
    coefplot_mlabels(mlbl, mlpos, eqnm, coefnm)

    // rename
    rename = st_local("rename")
    if (rename!="") {
        coefplot_rename(rename, st_local("renameregex")!="", 
            eqnm, coefnm) // modifies coefnm
    }

    // rename equations and swap names
    if (st_local("asequation2")!="") {
        eqnm = J(r, 1, st_local("asequation2"))
    }
    rename = st_local("eqrename")
    if (rename!="") {
        coefplot_rename(rename, st_local("eqrenameregex")!="", 
            J(r, 1, ""), eqnm) // modifies eqnm
    }
    
    // at is coef or eq
    if (st_local("atname2")=="_coef") {
        at = strtoreal(coefnm)
    }
    else if (st_local("atname2")=="_eq") {
        at = strtoreal(eqnm)
    }
    
    // apply at transform
    if ((attrans=st_local("attransform"))!="") {
        attmp = st_tempname()
        attrans = subinstr(attrans, "@", "scalar(" + attmp + ")")
        for (i=1; i<=r; i++) {
            st_numscalar(attmp, at[i])
            stata("scalar " + attmp + " = " + attrans)
            at[i] = st_numscalar(attmp)
        }
    }
    
    // check missings
    coefplot_missing(model, b)
    for (j=1; j<=cols(levels); j++) {
        coefplot_cimissing(model, j, ci[|1,(j*2-1) \ .,(j*2)|])
    }
    coefplot_atmissing(model, at)
    
    // return
    if (st_local("swapnames")!="") swap(coefnm, eqnm)
    st_local("n_ci", strofreal(cols(ci)/2))
    if (cols(C.ci)>cols(ci)) {
        ci = ci, J(rows(ci), cols(C.ci)-cols(ci), .)
    }
    else if (cols(C.ci)<cols(ci)) {
        C.ci = C.ci, J(rows(C.ci), cols(ci)-cols(C.ci), .)
    }
    C.ci     = C.ci \ ci
    if (cols(C.aux)>cols(aux)) {
        aux = aux, J(rows(aux), cols(C.aux)-cols(aux), .)
    }
    else if (cols(C.aux)<cols(aux)) {
        C.aux = C.aux, J(rows(C.aux), cols(aux)-cols(C.aux), .)
    }
    C.aux    = C.aux \ aux
    C.b      = C.b \ b
    C.V      = C.V \ V
    C.se     = C.se \ se
    C.t      = C.t \ t
    C.df     = C.df \ df
    C.pval   = C.pval \ pval
    C.coefnm = C.coefnm \ coefnm
    C.eqnm   = C.eqnm \ eqnm
    C.trans  = C.trans \ trans
    C.at     = C.at \ at
    C.mlbl   = C.mlbl \ mlbl
    C.mlpos  = C.mlpos \ mlpos
    C.plot   = C.plot \ J(r, 1, strtoreal(st_local("i")))
    C.by     = C.by \ J(r, 1, strtoreal(st_local("j")))
    if (firsteqonly==0 & allof(eqnm, eqnm[1]) & meqs) {
        st_local("equation", eqnm[1])
    }
}

void coefplot_invalid_subscript(string scalar model, string scalar opt, 
    real matrix b, real scalar row, real scalar col)
{
    if ((row<. & row>rows(b)) | (col<. & col>cols(b))) {
        printf("{err}%s: invalid subscript for %s\n", model, opt)
        exit(503)
    }
}

void coefplot_parse_input(string scalar model, string scalar opt, 
    string scalar s, real scalar row, real scalar col) 
{
    transmorphic     t
    string scalar    r, c
    string rowvector tokens
    
    t = tokeninit(" ", ("[",  "]", ","))
    tokenset(t, s)
    tokens = tokengetall(t)
    if (cols(tokens)>6)         coefplot_parse_input_error(model, opt)
    if (!st_isname(tokens[1]))  coefplot_parse_input_error(model, opt)
    s = tokens[1]
    if (cols(tokens)==1) {          // "name"
        row = 1; col = .
        return
    }
    if (cols(tokens)<4)         coefplot_parse_input_error(model, opt)
    if (tokens[2]!="[" | tokens[cols(tokens)]!="]") 
        coefplot_parse_input_error(model, opt)
    if (cols(tokens)==4) {          // name[#]
        r = tokens[3]
        c = "."
    }
    else if ((r=tokens[3])==",") {  // name[,#]
        if (cols(tokens)!=5) coefplot_parse_input_error(model, opt)
        r = "."
        c = tokens[4]
    }
    else {                          // name[#,] or name[#,.] or name[.,#]
        if (tokens[4]!=",") coefplot_parse_input_error(model, opt)
        r = tokens[3]
        if (cols(tokens)==5)    c = "."
        else                    c = tokens[5]
    }
    if (((r==".") + (c=="."))!=1) coefplot_parse_input_error(model, opt)
    if (r==".") row = .
    else row = coefplot_parse_input_num(model,opt, r)
    if (c==".") col = .
    else col = coefplot_parse_input_num(model,opt, c)
}

real scalar coefplot_parse_input_num(string scalar model, string scalar opt, 
    string scalar s)
{
    real scalar num
    
    num = strtoreal(s)
    if (missing(num)) coefplot_parse_input_error(model, opt)
    return(num)
}

void coefplot_parse_input_error(string scalar model, string scalar opt)
{
    printf("{err}%s: invalid syntax in %s()\n", model, opt)
    exit(198)
}

void coefplot_parse_cname(string scalar model, string scalar opt, 
    string scalar cname, real scalar row, real scalar col, real scalar emode,
    real scalar atismat, string scalar bname, real scalar brow, real scalar bcol)
{
    if (emode) {
        coefplot_parse_input(model, opt, cname, row, col)
        if (!atismat) cname = "e(" + cname + ")"
    }
    else {
        if (coefplot_parse_input_isposint(cname)) {
            row = brow; col = bcol
            if (row<.) row = strtoreal(cname)
            else       col = strtoreal(cname)
            cname = bname
        }
        else coefplot_parse_input(model, opt, cname, row, col)
    }
}

real scalar coefplot_parse_input_isposint(string scalar cname)
{
    real scalar n
    
    n = strtoreal(cname)
    return(!missing(n) & n==trunc(n) & n>0)
}

real scalar coefplot_notfound(
    string scalar model, string scalar name, real matrix e, | real scalar q)
{
    if (e==J(0,0,.)) {
        if (args()<4 | q==0) {
            printf("{txt}(%s: %s not found)\n", model, name)
        }
        return(1)
    }
    return(0)
}

real scalar coefplot_notconformable(
    string scalar model, string scalar name, real matrix e, 
    real scalar r, real scalar c, | real scalar q)
{
    if (rows(e)!=r | cols(e)!=c) {
        if (args()<6 |q==0) {
            printf("{txt}(%s: %s not conformable)\n", model, name)
        }
        return(1)
    }
    return(0)
}

void coefplot_eform(real colvector b, real matrix ci, string colvector eq, 
    string colvector coef)
{
    real scalar      i
    string matrix    eform
    real colvector   match, p
    
    eform = st_local("eform2")
    if (eform=="") {
        return
    }
    if (eform=="*") {
        b  = exp(b)
        ci = exp(ci)
        return
    }
    eform = coefplot_parse_namelist(eform, "*", "eform")
    match = J(rows(b), 1, 0)
    for (i=1; i<=rows(eform); i++) {
        p = select(1::rows(match), strmatch(eq, eform[i,1]) :&
            strmatch(coef, eform[i,2]))
        if (rows(p)==0) continue
        match[p] = J(rows(p), 1, 1)
    }
    p = select(1::rows(match), match)
    if (rows(p)==0) return
    b[p] = exp(b[p])
    ci[p,] = exp(ci[p,.])
}

void coefplot_rescale(real colvector b, real matrix ci, string colvector eq, 
    string colvector coef)
{
    real scalar      i, j
    string matrix    rescale, names
    real colvector   c, match, p
    
    rescale = st_local("rescale")
    if (rescale=="") {
        return
    }
    if (strtoreal(rescale)<.) {
        c = strtoreal(rescale)
    }
    else {
        rescale = coefplot_parse_matchlist(rescale, "rescale")
        c = J(rows(b), 1, 1)
        match = J(rows(b), 1, 0)
        for (i=1; i<=rows(rescale); i++) {
            if (strtoreal(rescale[i,2])>=.) {
                display("{err}rescale(): invalid value")
                exit(198)
            }
            names = coefplot_parse_namelist(rescale[i,1], "*", "rescale")
            for (j=1; j<=rows(names); j++) {
                p = select(1::rows(match), strmatch(eq, names[j,1]) :&
                    strmatch(coef, names[j,2]) :& (match:==0))
                if (rows(p)==0) continue
                c[p]     = J(rows(p), 1, strtoreal(rescale[i,2]))
                match[p] = J(rows(p), 1, 1)
            }
        }
    }
    b = b :* c
    ci = ci :* c
}

string colvector coefplot_collect_transforms(string colvector eq, 
    string colvector coef)
{
    real scalar      i, j
    string matrix    trans, names
    string colvector T
    real colvector   match, p
    
    T = J(rows(eq), 1, "")
    trans = st_local("transform")
    if (trans=="") {
        return(T)
    }
    trans = coefplot_parse_matchlist(trans, "transform")
    match = J(rows(eq), 1, 0)
    for (i=1; i<=rows(trans); i++) {
        names = coefplot_parse_namelist(trans[i,1], "*", "transform")
        for (j=1; j<=rows(names); j++) {
            p = select(1::rows(match), strmatch(eq, names[j,1]) :&
                strmatch(coef, names[j,2]) :& (match:==0))
            if (rows(p)==0) continue
            T[p]     = J(rows(p), 1, trans[i,2])
            match[p] = J(rows(p), 1, 1)
        }
    }
    return(T)
}

void coefplot_mlabels(string colvector mlbl, real colvector mlpos, 
    string colvector eq, string colvector coef)
{
    real scalar      i, j
    string matrix    mlab, names
    real colvector   match, p
    
    mlab = st_local("mlabels2")
    if (mlab=="") {
        return
    }
    mlab = coefplot_parse_matchlist(mlab, "mlabels", 2)
    match = J(rows(eq), 1, 0)
    for (i=1; i<=rows(mlab); i++) {
        names = coefplot_parse_namelist(mlab[i,1], "*", "mlabels")
        for (j=1; j<=rows(names); j++) {
            p = select(1::rows(match), strmatch(eq, names[j,1]) :&
                strmatch(coef, names[j,2]) :& (match:==0))
            if (rows(p)==0) continue
            mlbl[p]  = J(rows(p), 1, mlab[i,3])
            mlpos[p] = J(rows(p), 1, strtoreal(mlab[i,2]))
            match[p] = J(rows(p), 1, 1)
        }
    }
}

void coefplot_rename(string scalar rename, real scalar regex, 
    string colvector eq, string colvector coef)
{
    real scalar     i, j, rl
    real colvector  p, p0, match
    string matrix   names

    if (regex) {
        rename = coefplot_parse_matchlist(rename, "rename")
        p0 = 1::rows(coef)
        for (i=1; i<=rows(rename); i++) {
            if (rows(p0)==0) return
            names = coefplot_parse_namelist(rename[i,1], "*", "rename")
            for (j=1; j<=rows(names); j++) {
                match = (strmatch(eq[p0], names[j,1]) :& regexm(coef[p0], names[j,2]))
                p = select(p0, match)
                if (rows(p)==0) continue 
                coef[p] = coefplot_regexr(coef[p], names[j,2], rename[i,2])
                p0 = select(p0, match:==0)
            }
        }
        return
    }
    rename = coefplot_parse_matchlist(rename, "rename")
    p0 = 1::rows(coef)
    for (i=1; i<=rows(rename); i++) {
        if (rows(p0)==0) return
        // syntax: *abc for suffix rename
        //         abc* for prefix rename
        //         abc for exact rename
        names = coefplot_parse_namelist(rename[i,1], "*", "rename")
        for (j=1; j<=rows(names); j++) {
            if (substr(names[j,2],1,1)=="*") {
                rl = strlen(names[j,2])-1
                match = strmatch(eq[p0], names[j,1]) :& 
                    (substr(coef[p0], -rl, .):==substr(names[j,2], -rl, .))
                p = select(p0, match)
                if (rows(p)==0) continue 
                coef[p] = substr(coef[p], 1, strlen(coef[p]) :- rl) :+ rename[i,2]
            }
            else if (substr(names[j,2],-1,1)=="*") {
                rl = strlen(names[j,2])-1
                match = strmatch(eq[p0], names[j,1]) :&
                    (substr(coef[p0], 1, rl):==substr(names[j,2], 1, rl))
                p = select(p0, match)
                if (rows(p)==0) continue 
                coef[p] = rename[i,2] :+ substr(coef[p], 1 + rl, .)
            }
            else {
                match = strmatch(eq[p0], names[j,1]) :& (coef[p0]:==names[j,2])
                p = select(p0, match)
                if (rows(p)==0) continue 
                coef[p] = J(rows(p), 1, rename[i,2])
            }
            p0 = select(p0, match:==0)
        }
    }
}

string matrix coefplot_regexr(string matrix x, string matrix y, string matrix z)
{
    string matrix       res
    real scalar         r, R, c, C
    transmorphic scalar rx, cx, ry, cy, rz, cz

    R = max((rows(x),rows(y),rows(z)))
    C = max((cols(x),cols(y),cols(z)))
    rx = (rows(x)==1 ? &1 : (rows(x)<R ? _error(3200) : &r))
    cx = (cols(x)==1 ? &1 : (cols(x)<C ? _error(3200) : &c))
    ry = (rows(y)==1 ? &1 : (rows(y)<R ? _error(3200) : &r))
    cy = (cols(y)==1 ? &1 : (cols(y)<C ? _error(3200) : &c))
    rz = (rows(z)==1 ? &1 : (rows(z)<R ? _error(3200) : &r))
    cz = (cols(z)==1 ? &1 : (cols(z)<C ? _error(3200) : &c))
    res = J(R,C, "")
    for (r=1;r<=R;r++) {
        for (c=1;c<=C;c++) {
            res[r,c] = _coefplot_regexr(x[*rx,*cx], y[*ry,*cy], z[*rz,*cz])
        }
    }
    return(res)
}
string scalar _coefplot_regexr(string scalar s0, string scalar from, string scalar to)
{
    real scalar         i, j
    string scalar       s, t, BSLASH
    string rowvector    sub
    pragma unset        s
    
    if (regexm(s0, from)) {
        sub = regexs()
        sub = (sub, J(1, 10-cols(sub), ""))
        BSLASH = "\"
        for (i=1; i<=strlen(to); i++) {
            if ((t=substr(to,i,1))==BSLASH) {
                i++
                if ((t=substr(to,i,1))==BSLASH) s = s + BSLASH      // "\\"
                else if ((j=strtoreal(t))<.)    s = s + sub[j+1]    // "\#"
                else                            s = s + BSLASH + t
            }
            else s = s + t
        }
        return(subinstr(s0, sub[1], s, 1))
    }
    else return(s0)
}

real rowvector coefplot_get_margins_at(string scalar rtype, 
    real scalar pos, string colvector coefnm)
{
    real scalar         i, j, r, c
    real matrix         at0
    real rowvector      at, p, atstats
    
    at0     = st_matrix(rtype + "(at)")
    r       = rows(at0)
    coefnm  = subinstr(coefnm, "1bn._at", "1._at")
    c       = rows(coefnm)
    at      = J(1, c, .)
    for (i=1; i<=r; i++) {
        atstats = tokens(st_global(rtype + "(atstats" + strofreal(i) + 
                                                        ")")) :== "values"
        atstats = select(1..cols(atstats), atstats)
        if (pos>cols(atstats)) continue
        j = atstats[pos]
        p = select(1..c, strmatch(coefnm, strofreal(i) + "._at*")')
        at[p] = J(1, cols(p), at0[i,j])
    }
    return(at)
}

void coefplot_missing(string scalar model, real colvector b)
{
    if (hasmissing(b)) {
        printf("{txt}(%s: b missing for some coefficients)\n", model)
    }
}

void coefplot_atmissing(string scalar model, real colvector at)
{
    if (hasmissing(at)) {
        if (nonmissing(at)) {
            printf("{txt}(%s: 'at' missing for some coefficients)\n", model)
            return
        }
        printf("{txt}(%s: could not determine 'at')\n", model)
    }
}

void coefplot_cimissing(string scalar model, real scalar ci, real matrix tmp)
{
    if (hasmissing(tmp)) {
        if (nonmissing(tmp)) {
            printf("{txt}(%s: CI%g missing for some coefficients)\n", 
                model, ci)
            return
        }
        printf("{txt}(%s: could not determine CI%g)\n", model, ci)
    }
}

void coefplot_add_label(struct coefplot_struct scalar C, 
    string scalar name, real scalar i, string scalar lbl, real scalar force)
{
    pointer(string colvector) scalar l
    
    if (name=="plot")       l = &C.plotlbl
    else if (name=="by")    l = &C.bylbl
    else if (name=="coef")  l = &C.coeflbl
    else                    return
    if (rows(*l)<i) {
        *l = *l \ J(i-rows(*l), cols(*l), "")
    }
    if (force | (*l)[i,1]=="") {
        (*l)[i,1] = st_local(lbl)
    }
}

void coefplot_set_r(struct coefplot_struct scalar C)
{
    C.r = rows(C.b)
    st_local("r", strofreal(C.r))
    st_local("N_ci", strofreal(cols(C.ci)/2))
    st_local("N_aux", strofreal(cols(C.aux)))
    st_local("mlbllen", strofreal(max(strlen(C.mlbl))))
}

void coefplot_add_eq_and_grp(struct coefplot_struct scalar C)
{
    C.eq = J(C.r, 1, 1)
    C.grp = J(C.r, 1, 0)
}

void coefplot_arrange(struct coefplot_struct scalar C)
{
    real colvector      p
    
    p = coefplot_niceorder(C.eqnm, C.coefnm, C.plot, C.by, C.r)
    coefplot_order(p, coefplot_orderby(st_local("orderby"), C), C)
    coefplot_order(p, coefplot_sort(p, st_local("sort"), C), C)
    coefplot_order(p, st_local("order"), C)
    C.b      = C.b[p]
    C.V      = C.V[p]
    C.se     = C.se[p]
    C.t      = C.t[p]
    C.df     = C.df[p]
    C.pval   = C.pval[p]
    C.at     = C.at[p]
    C.aux    = C.aux[p,]
    C.mlbl   = C.mlbl[p]
    C.mlpos  = C.mlpos[p]
    C.plot   = C.plot[p]
    C.by     = C.by[p]
    C.ci     = C.ci[p,]
    C.coefnm = C.coefnm[p]
    C.eqnm   = C.eqnm[p]
    C.trans  = C.trans[p]
    st_local("r", strofreal(C.r))
}

real colvector coefplot_niceorder(string colvector eqnm, string colvector coefnm,
    real colvector plot, real colvector by, real scalar r)
{
    real matrix     Y
    real scalar     i, a0, b0, s0, a, b, s
    real colvector  p
    
    p = order((eqnm, coefnm, strofreal(plot), strofreal(by)), 1..4)
    Y = (1::r)
    Y = Y, Y, Y
    a0 = b0 = a = b = 1
    for (i=2; i<=r; i++) {
        // equation
        s0 = (eqnm[p[i]]==eqnm[p[i-1]])
        if (s0) {
            b0++
        }
        if (s0==0 | i==r) {
            Y[p[|a0 \ b0|],1] = J(b0-a0+1, 1, min(Y[p[|a0 \ b0|],1]))
            a0 = b0 + 1
            b0 = a0
        }
        // coef
        s = coefnm[p[i]]==coefnm[p[i-1]] & eqnm[p[i]]==eqnm[p[i-1]]
        if (s) {
            b++
        }
        if (s==0) {
            if (coefnm[p[i-1]]=="_cons") {
                Y[p[|a \ b|],2] = J(b-a+1, 1, .)
            }
            else {
                Y[p[|a \ b|],2] = J(b-a+1, 1, min(Y[p[|a \ b|],2]))
            }
            a = b + 1
            b = a
        }
        if (i==r) {
            if (coefnm[p[i]]=="_cons") {
                Y[p[|a \ b|],2] = J(b-a+1, 1, .)
            }
            else {
                Y[p[|a \ b|],2] = J(b-a+1, 1, min(Y[p[|a \ b|],2]))
            }
        }
    }
    return(order(Y, 1..3))
}

string scalar coefplot_orderby(string scalar order, struct coefplot_struct scalar C)
{
    real scalar      i
    string rowvector s
    real colvector   p
    string colvector eqs, coefs
    
    if (order=="") return("")
    s = tokens(order)
    if (s[1]==".") p = select(1::C.r, C.plot:==strtoreal(s[2]))
    else p = select(1::C.r, (C.by:==strtoreal(s[1]) :& C.plot:==strtoreal(s[2])))
    if (rows(p)==0) return("")
    eqs = C.eqnm[p]; coefs = C.coefnm[p]
    p = coefplot_niceorder(eqs, coefs, J(rows(p),1,1), J(rows(p),1,1), rows(p))
    eqs = ("`"+`"""') :+ eqs[p] :+ (`"""' + "'")
    coefs = ("`"+`"""') :+ coefs[p] :+ (`"""' + "'")
    s = eqs[1] + ": " + coefs[1]
    for (i=2; i<=rows(p); i++) {
        if (eqs[i]!=eqs[i-1]) s = s + " * " + eqs[i] + ":"
        if (coefs[i]==`"`"_cons"'"') continue  // so that _cons goes last
        s = s + " " + coefs[i]
    }
    s = s + " *"
    return(s)
}

string scalar coefplot_sort(real colvector p0, string scalar sort, 
    struct coefplot_struct scalar C)
{
    real scalar      subgr, plot, desc, c, i
    string rowvector s
    real colvector   p, eq, v, df
    string colvector eqs, coefs

    if (sort=="") return("")
    // parse input
    s = tokens(sort)
    subgr = strtoreal(s[1])
    plot = strtoreal(s[2])
    desc = (s[3]=="1")
    s = tokens(s[4])
    if (length(s)>1) c = strtoreal(s[2])
    else             c = 1
    s = s[1]
    // get relevant data
    p = p0
    if (subgr<.) {
        p = select(p, C.by[p]:==subgr)
        if (rows(p)==0) return("")
    }
    if (plot<.) {
        p = select(p, C.plot[p]:==plot)
        if (rows(p)==0) return("")
    }
    if      (s=="b")    v = C.b[p]
    else if (s=="v")    v = C.V[p]
    else if (s=="se")   v = C.se[p]
    else if (s=="t")    v = C.t[p] 
    else if (s=="tabs") v = abs(C.t[p])
    else if (s=="df")   v = C.df[p]
    else if (s=="p")    v = C.pval[p]
    else if (s=="ll") {
        if ((c*2)>cols(C.ci)) return("")
        v = C.ci[p,c*2-1]
    }
    else if (s=="ul") {
        if ((c*2)>cols(C.ci)) return("")
        v = C.ci[p,c*2]
    }
    else if (s=="aux") {
        if (c>cols(C.aux)) return("")
        v = C.aux[p,c]
    }
    // establish sort order (within equations)
    if (desc) v = -v
    eqs = C.eqnm[p]
    eq = J(rows(eqs),1,1)
    for (i=2; i<=rows(eq); i++) {
        if (eqs[i]!=eqs[i-1]) eq[i] = eq[i-1]+1
        else                  eq[i] = eq[i-1]
    }
    p = sort((eq, v, p), 1..3)[,3]
    // collect ordered names
    eqs = ("`"+`"""') :+ C.eqnm[p] :+ (`"""' + "'")
    coefs = ("`"+`"""') :+ C.coefnm[p] :+ (`"""' + "'")
    s = eqs[1] + ": " + coefs[1]
    for (i=2; i<=rows(p); i++) {
        if (eqs[i]!=eqs[i-1]) s = s + " * " + eqs[i] + ":"
        s = s + " " + coefs[i]
    }
    s = s + " *"
    return(s)
}

void coefplot_order(real colvector p0, string scalar order, 
    struct coefplot_struct scalar C)
{
    real scalar      i, j, k
    real colvector   p, tag, tmp
    string colvector eqs

    if (order=="") return
    order = coefplot_parse_namelist(order, "", "order")
    if (order[1,1]=="" & !allof(order[,1], "")) {
        display("{err}inconsistent order(): " + 
            "specify equations for all or for none")
        exit(198)
    }
    p = J(0,1,.)
    tag = J(C.r, 1, 0)
    k = 0
    // order coefficients (general)
    if (order[1,1]!="") {
        for (i=1; i<=rows(order); i++) {
            k++
            if (order[i,2]==".") {
                coefplot_appendemptyrow(C, order[i,1], tag, p0)
                p = p \ C.r
                continue
            }
            tag = tag :+ (k * strmatch(C.coefnm[p0], order[i,2]) :* !tag :* 
                (C.eqnm[p0]:==order[i,1]))
            if (anyof(tag, k)) {
                p = p \ select(p0, tag:==k)
            }
        }
        if (anyof(tag, 0)) {
            p = p \ select(p0, tag:==0)
        }
        swap(p,p0); return
    }
    // order coefficients within equations
    order = order[,2]'
    eqs = C.eqnm[p0[1]]
    for (i=2; i<=C.r; i++) { // get equations (in right order)
        if (C.eqnm[p0[i]]!=C.eqnm[p0[i-1]]) {
            eqs = eqs \ C.eqnm[p0[i]]
        }
    }
    for (j=1; j<=rows(eqs); j++) {
        for (i=1; i<=cols(order); i++) {
            k++
            if (order[i]==".") {
                coefplot_appendemptyrow(C, eqs[j], tag, p0)
                p = p \ C.r
                continue
            }
            tag = tag :+ (k * strmatch(C.coefnm[p0], order[i]) :* !tag :* 
                (C.eqnm[p0]:==eqs[j]))
            if (anyof(tag, k)) {
                p = p \ select(p0, tag:==k)
            }
        }
        tmp = (tag:==0):&(C.eqnm[p0]:==eqs[j])
        if (any(tmp)) {
            p = p \ select(p0, tmp)
            tag = tag :+ tmp
        }
    }
    swap(p,p0); return
}

void coefplot_appendemptyrow(struct coefplot_struct scalar C, 
    string scalar eq, real colvector tag, real colvector p0)
{
    C.b      = C.b      \ .
    C.V      = C.V      \ .
    C.se     = C.se     \ .
    C.t      = C.t      \ .
    C.df     = C.df     \ .
    C.pval   = C.pval   \ .
    C.at     = C.at     \ 1
    C.aux    = C.aux    \ J(1, cols(C.aux), .)
    C.mlbl   = C.mlbl   \ ""
    C.mlpos  = C.mlpos  \ .
    C.plot   = C.plot   \ .
    C.by     = C.by     \ .
    C.ci     = C.ci     \ J(1, cols(C.ci), .)
    C.coefnm = C.coefnm \ ""
    C.eqnm   = C.eqnm   \ eq
    C.trans  = C.trans  \ ""
    tag      = tag      \ .
    C.r      = C.r      + 1
    p0       = p0       \ C.r
}

void coefplot_coeflbls(struct coefplot_struct scalar C)
{
    real scalar      i, j, k
    real colvector   tag
    string matrix    labels, names
    
    C.coeflbl = J(C.r, 1, "")
    tag = J(C.r, 1, 0)
    labels = coefplot_parse_matchlist(st_local("coeflabels"), "coeflabels")
    for (j=1; j<=rows(labels); j++) {
        names = coefplot_parse_namelist(labels[j,1], "*", "coeflabels")
        for (k=1; k<=rows(names); k++) {
            tag = tag :+ j * strmatch(C.eqnm, names[k,1]) :* 
                             strmatch(C.coefnm, names[k,2]) :* (tag:==0)
        }
    }
    _editmissing(tag, 0)
    for (i=1; i<=C.r; i++) {
        if (tag[i] & C.plot[i]<.) { // C.plot is missing for gaps from order()
            C.coeflbl[i] = labels[tag[i],2]
        }
    }
}

void coefplot_multiple_eqs(struct coefplot_struct scalar C)
{
    real scalar     i, meqs
    string matrix   eq
    
    eq = C.eqnm, strofreal(C.plot), strofreal(C.by)

    _sort(eq, (3,2,1))
    meqs = 0
    for (i=2; i<=rows(eq); i++) {
        if (eq[i,1]!=eq[i-1,1] & eq[i,2]==eq[i-1,2] & eq[i,3]==eq[i-1,3]) {
            meqs = 1
            break
        }
    }
    if (meqs==0) {
        C.eqnm = J(rows(C.eqnm), 1, "_")
    }
    st_local("meqs", strofreal(meqs))
}

void coefplot_bycoefs(struct coefplot_struct scalar C)
{
    real scalar      i, j, k, meqs
    real colvector   p
    string scalar    eql
    string colvector bylbl, last, eqlbls

    meqs = (st_local("meqs")!="0") & (st_local("noeqlabels")=="")
    if (meqs) eqlbls = tokens(st_local("eqlabels"))'
    bylbl = C.bylbl
    C.bylbl = C.coeflbl
    swap(C.at, C.by)
    j = 0
    k = 1
    for (i=1; i<=C.r; i++) {
        if (i>1) {
            if (C.eqnm[i]!=C.eqnm[i-1]) k++
        }
        if ((C.eqnm[i], C.coefnm[i])!=last) j++
        last = (C.eqnm[i], C.coefnm[i])
        C.by[i] = j
        if (meqs) {
            if (k<=rows(eqlbls)) eql = eqlbls[k]
            else                 eql = C.eqnm[i]
            C.bylbl[j] = eql + ": " + C.bylbl[i]
        }
        else C.bylbl[j] = C.bylbl[i]
    }
    C.bylbl = C.bylbl[|1 \ j|]
    C.eqnm = J(C.r, 1, "_")
    C.coefnm = strofreal(C.at)
    C.coeflbl = J(C.r, 1, "")
    for (i=1; i<=C.r; i++) {
        C.coeflbl[i] = bylbl[C.at[i]]
    }
    C.at = J(C.r, 1, 1)
    p = coefplot_niceorder(C.eqnm, C.coefnm, C.plot, C.by, C.r)
    C.b       = C.b[p]
    C.V       = C.V[p]
    C.se      = C.se[p]
    C.t       = C.t[p]
    C.df      = C.df[p]
    C.pval    = C.pval[p]
    C.at      = C.at[p]
    C.aux     = C.aux[p,]
    C.mlbl    = C.mlbl[p]
    C.mlpos   = C.mlpos[p]
    C.plot    = C.plot[p]
    C.by      = C.by[p]
    C.ci      = C.ci[p,]
    C.coefnm  = C.coefnm[p]
    C.eqnm    = C.eqnm[p]
    C.trans   = C.trans[p]
    C.coeflbl = C.coeflbl[p]
    st_local("n_subgr", strofreal(rows(C.bylbl)))
}

void coefplot_catvals(struct coefplot_struct scalar C)
{
    real scalar         i, j, k, e, eqgap, ggap
    real colvector      pos, at0
    string scalar       glbls, xlab
    string colvector    eqs
    string matrix       groups, names
    
    // determine plot positions
    for (i=2; i<=C.r; i++ ) {
        C.at[i] = C.at[i-1] +
            ((C.coefnm[i]!=C.coefnm[i-1])       // new coefficient
                | (C.eqnm[i]!=C.eqnm[i-1])      // new equation
                | (C.plot[i]==.))               // gap from order()
    }
    
    // reposition
    coefplot_relocate(C)
    C.xmin = min(C.at)
    
    // equation numbers and labels
    eqs     = tokens(st_local("eqlabels"))'
    xlab    = st_local("eqxlab")
    C.eq    = J(C.r, 1, 1)
    C.eqlbl = J(C.r, 1, "")
    j = 1
    if (j>rows(eqs)) C.eqlbl[j] = coefplot_get_xlab(C.eqnm[1], xlab)
    else             C.eqlbl[j] = eqs[j]
    for (i=2; i<=C.r; i++ ) {
        C.eq[i] = C.eq[i-1]
        if (C.eqnm[i]!=C.eqnm[i-1]) {
            j++
            if (j>rows(eqs)) C.eqlbl[j] = coefplot_get_xlab(C.eqnm[i], xlab)
            else             C.eqlbl[j] = eqs[j]
            C.eq[i] = C.eq[i] + 1
        }
    }
    C.eqlbl = C.eqlbl[|1,1 \ j,.|]
    
    // group IDs
    groups = st_local("groups")
    C.grp = J(C.r, 1, 0)
    if (groups!="") {
        groups = coefplot_parse_matchlist(groups, "groups")
        eqs = uniqrows(C.eqnm)
        for (e=1; e<=rows(eqs); e++) {
            for (j=1; j<=rows(groups); j++) {
                names = coefplot_parse_namelist(groups[j,1], "*", "groups")
                for (k=1; k<=rows(names); k++) {
                    C.grp = C.grp :+ j * strmatch(C.eqnm, names[k,1]) :* 
                        strmatch(C.coefnm, names[k,2]) :* (C.grp:==0) :* 
                        (C.eqnm:==eqs[e]) :* (C.plot:<.)
                }
                for (i=1; i<=C.r; i++) {
                    pos = select(1::C.r, (C.grp:==j) :& (C.eqnm:==eqs[e]))
                    if (length(pos)>0) {
                        C.grp[|pos[1] \ pos[rows(pos)]|] = 
                            J((pos[rows(pos)]-pos[1]+1), 1, j)
                    }
                }
            }
        }
        for (j=1; j<=rows(groups); j++) {
            glbls = glbls + " " + "`" + `"""' + groups[j,2] + `"""' + "'"
        }
        st_local("groups", strtrim(glbls))
    }

    // add gaps between equations and groups
    eqgap = strtoreal(st_local("eqgap"))
    ggap  = strtoreal(st_local("ggap"))
    if (eqgap==0 & ggap==0) return
    at0   = C.at
    for (i=2; i<=C.r; i++ ) {
        C.at[i] = C.at[i-1] +
            (at0[i,1] - at0[i-1,1]) +           // update downstream
            (C.eqnm[i]!=C.eqnm[i-1])*eqgap +    // new eq
            (C.eqnm[i]==C.eqnm[i-1] & C.grp[i]!=C.grp[i-1])*ggap // new group
    }
}

string scalar coefplot_get_xlab(string scalar v, string scalar interact)
{
    if (interact=="") return(v)
    stata("compile_xlabel, v(" + v + ") interact(" + interact + ")")
    return(st_local("coeflbl"))
}

void coefplot_relocate(struct coefplot_struct scalar C)
{
    real scalar      i, j, k
    real colvector   tag, p
    string matrix    pos, names
    
    if (st_local("relocate")=="") return
    
    // set positions
    tag = J(C.r, 1, 0)
    pos = coefplot_parse_matchlist(st_local("relocate"), "relocate")
    for (j=1; j<=rows(pos); j++) {
        names = coefplot_parse_namelist(pos[j,1], "*", "relocate")
        for (k=1; k<=rows(names); k++) {
            tag = tag :+ j * strmatch(C.eqnm, names[k,1]) :* 
                             strmatch(C.coefnm, names[k,2]) :* (tag:==0)
        }
    }
    _editmissing(tag, 0)
    p = strtoreal(pos[,2])
    for (i=1; i<=C.r; i++) {
        if (tag[i] & (C.plot[i]<.)) {
            C.at[i] = p[tag[i]]
        }
    }
    
    // reorder
    p = order((C.at, (1::C.r)), (1,2))
    C.b       = C.b[p]
    C.V       = C.V[p]
    C.se      = C.se[p]
    C.t       = C.t[p]
    C.df      = C.df[p]
    C.pval    = C.pval[p]
    C.at      = C.at[p]
    C.aux     = C.aux[p,]
    C.mlbl    = C.mlbl[p]
    C.mlpos   = C.mlpos[p]
    C.plot    = C.plot[p]
    C.by      = C.by[p]
    C.ci      = C.ci[p,]
    C.coefnm  = C.coefnm[p]
    C.eqnm    = C.eqnm[p]
    C.trans   = C.trans[p]
    C.coeflbl = C.coeflbl[p]
}

void coefplot_headings(struct coefplot_struct scalar C)
{
    real scalar      i, j, k, off, gap, fskip
    real colvector   tag
    string scalar    hlbls
    string matrix    headings, names

    off = strtoreal(st_local("hoff"))
    gap = strtoreal(st_local("hgap"))
    
    // if headings are equations
    if (st_local("eqashead")!="") {
        fskip = C.at[1]
        j = 0
        for (i=1; i<=C.r; i++) {
            if (C.eq[i]!=j) {
                C.at[|i \ .|] = C.at[|i \ .|] :+ 1 :+ (gap*(i>1))
                hlbls = hlbls + " " + strofreal(C.at[i] - fskip + off)
            }
            j = C.eq[i]
        }
        st_local("hlbls", strtrim(hlbls))
        return
    }
    
    // if headings are not equations
    headings = st_local("headings")
    if (headings=="") {
        st_local("hlbls", "")
        return
    }
    tag = J(C.r, 1, 0)
    if (C.r>1) {
        tag[|2 \ .|] = tag[|2 \ .|] :+ 
            (C.at[|2 \ .|]:==C.at[|1 \ C.r-1|])
        _editvalue(tag, 1, .)
    }
    headings = coefplot_parse_matchlist(headings, "headings")
    for (j=1; j<=rows(headings); j++) {
        names = coefplot_parse_namelist(headings[j,1], "*", "headings")
        for (k=1; k<=rows(names); k++) {
            tag = tag :+ j * strmatch(C.eqnm,names[k,1]) :* 
                             strmatch(C.coefnm, names[k,2]) :* (tag:==0)
        }
    }
    _editmissing(tag, 0)
    for (i=1; i<=C.r; i++) {
        if (tag[i] & (C.plot[i]<.)) {
            C.at[|i \ .|] = C.at[|i \ .|] :+ 1 :+ (gap*(i>1))
            hlbls = hlbls + " " + strofreal(C.at[i] - 1 + off) + " " +
                "`" + `"""' + headings[tag[i],2] + `"""' + "'"
        }
    }
    st_local("hlbls", strtrim(hlbls))
}

string matrix coefplot_parse_matchlist(string scalar s, string scalar opt, 
    | real scalar nc0)
{
    transmorphic     t
    real scalar      c, a, b, j, i, nc
    real rowvector   eqpos
    string rowvector stok
    string matrix    res
    
    if (args()==3) nc = nc0
    else           nc = 1
    if (s=="") return(J(0,1+nc,""))
    t = tokeninit(" ", "=")
    tokenset(t, s)
    stok = tokengetall(t)
    c = cols(stok)
    a = b = i = 1
    eqpos = select(1::c, stok':=="=")'
    res = J(cols(eqpos), 1+nc, "")
    for (j=1; j<=cols(eqpos); j++) {
        b = eqpos[j]
        if (b==a | b==c | (b+nc)>cols(stok)) {
            printf("{err}%s(): invalid matchlist\n", opt)
            exit(198)
        }
        res[i,] = (invtokens(stok[|a \ b-1|]), stok[|b+1 \ b+nc|])
        a = b + 1 + nc
        i++
    }
    if (a<=c) {
        printf("{err}%s(): invalid matchlist\n", opt)
        exit(198)
    }
    nc = nc + 1
    for (i=1; i<=rows(res); i++) { // strip quotes in last column
            if (substr(res[i,nc], 1, 1)==`"""') {
                    res[i,nc] = substr(res[i,nc], 2, strlen(res[i,nc])-2)
            }
            else if (substr(res[i,nc], 1, 2)=="`" + `"""') {
                    res[i,nc] = substr(res[i,nc], 3, strlen(res[i,nc])-4)
            }
    }
    return(res)
}

string matrix coefplot_parse_namelist(string scalar s, string scalar defeq, 
    string scalar opt)
{
    transmorphic     t
    real scalar      i, c
    string rowvector stok
    string matrix    res
    
    if (s=="") return(J(0,2,""))
    t = tokeninit(" ", ":")
    tokenset(t, s)
    stok = tokengetall(t)
    c = cols(stok)
    for (i=1; i<=c; i++) { // strip quotes
            if (substr(stok[i], 1, 1)==`"""') {
                    stok[i] = substr(stok[i], 2, strlen(stok[i])-2)
            }
            else if (substr(stok[i], 1, 2)=="`" + `"""') {
                    stok[i] = substr(stok[i], 3, strlen(stok[i])-4)
            }
    }
    res = J(0, 2, "")
    for (i=1;i<=c;i++) {
        if (i+1<=c) {
            if (stok[i+1]==":") {
                if (stok[i]==":") {
                    printf("{err}%s(): invalid namelist\n", opt)
                    exit(198)
                }
                if (i+2<=c) {
                    if (stok[i+2]==":") {
                        printf("{err}%s(): invalid namelist\n", opt)
                        exit(198)
                    }
                    if (i+3<=c) {                   
                        if (stok[i+3]==":") {           // "... eq: eq: ..."
                            res = res \ (stok[i], "*")
                            i++
                            continue
                        }
                    }
                    res = res \ (stok[i], stok[i+2])    // "... eq:name ..."
                    defeq = stok[i]
                    i = i + 2
                    continue
                }
                res = res \ (stok[i], "*")              // "... eq:"
                i++
                continue
            }
        }
        if (stok[i]==":") {
            printf("{err}%s(): invalid namelist\n", opt)
            exit(198)
        }
        res = res \ (defeq, stok[i])
    }
    return(res)
}

void coefplot_put(struct coefplot_struct scalar C)
{
    real scalar     i
    real rowvector  vi
    
    st_store((1,C.r), st_local("b"),     C.b)
    st_store((1,C.r), st_local("V"),     C.V)
    st_store((1,C.r), st_local("se"),    C.se)
    st_store((1,C.r), st_local("t"),     C.t)
    st_store((1,C.r), st_local("df"),    C.df)
    st_store((1,C.r), st_local("pval"),  C.pval)
    st_store((1,C.r), st_local("at"),    C.at)
    st_sstore((1,C.r), st_local("mlbl"), C.mlbl)
    st_store((1,C.r), st_local("mlpos"), C.mlpos)
    st_store((1,C.r), st_local("plot"),  C.plot)
    st_store((1,C.r), st_local("by"),    C.by)
    st_store((1,C.r), st_local("eq"),    C.eq)
    st_store((1,C.r), st_local("grp"),   C.grp)
    vi = J(1, cols(C.ci), .)
    for (i=1; i<=(cols(vi)/2); i++) {
        vi[1,i*2-1] = st_varindex(st_local("ll" + strofreal(i)))
        vi[1,i*2]   = st_varindex(st_local("ul" + strofreal(i)))
    }
    st_store((1,C.r), vi, C.ci)
    vi = J(1, cols(C.aux), .)
    for (i=1; i<=cols(vi); i++) {
        vi[1,i] = st_varindex(st_local("aux" + strofreal(i)))
    }
    st_store((1,C.r), vi, C.aux)
}

void coefplot_apply_transform(struct coefplot_struct scalar C)
{
    real scalar      i, j, rc, x0, x1, mis
    string scalar    trans0, trans, trans1
    string rowvector vname
    real rowvector   vpos
    
    if (allof(C.trans[i], "")) return
    vname = J(1, cols(C.ci), "")
    for (j=1; j<=(cols(C.ci)/2); j++) {
        vname[j*2-1] = st_local("ll"+strofreal(j))
        vname[j*2]   = st_local("ul"+strofreal(j))
    }
    vname = st_local("b"), vname
    vpos = st_varindex(vname)
    mis = 0
    for (i=1; i<=C.r; i++) {
        if (C.trans[i]=="") continue
        if (C.trans[i]!=trans0) trans0 = C.trans[i]
        trans = _coefplot_inject_temvars(trans0, cols(C.ci), cols(C.aux))
        for (j=1; j<=cols(vname); j++) {
            trans1 = subinstr(trans, "@", vname[j])
            x0 = _st_data(i, vpos[j])
            rc = _stata("replace " + vname[j] + " = " + trans1 + " in " + strofreal(i), 1)
            if (rc) {
                printf("{err}transform '%s' invalid\n", trans0)
                exit(198)
            }
            x1 = _st_data(i, vpos[j])
            if (x1>=. & x1!=x0) mis = 1
        }
    }
    if (mis) {
        display("{txt}(transform missing for some coefficients or CIs)")
    }
}

void coefplot_lbl_is_multiline()
{
    string scalar    lbl
    
    lbl = strtrim(st_local("lbl"))
    if ((substr(lbl, 1, 1)==`"""' | substr(lbl, 1, 2)==("`" + `"""'))) {
        return(499)
    }
}

void coefplot_get_coefs(struct coefplot_struct scalar C)
{
    st_local("coefs", 
        invtokens("`" :+ `"""' :+ C.coefnm' :+ `"""' :+ "'"))
}

void coefplot_get_coeflbl(struct coefplot_struct scalar C, real scalar i) 
{
    st_local("coeflbl", C.coeflbl[i])
}

void coefplot_get_plotlbl(struct coefplot_struct scalar C, real scalar i) 
{
    st_local("plotlbl", C.plotlbl[i])
}

void coefplot_get_bylbl(struct coefplot_struct scalar C, real scalar i) 
{
    st_local("bylbl", C.bylbl[i])
}

void coefplot_get_eqlbl(struct coefplot_struct scalar C, real scalar i) 
{
    st_local("eqlbl", C.eqlbl[i])
}

void coefplot_ticks_and_labels(struct coefplot_struct scalar C)
{
    real scalar      i, between
    string scalar    labels, grid, space
    
    between = (st_local("grid")=="between")
    st_local("xrange", strofreal(C.xmin-0.5) + " " + 
                       strofreal(max(C.at)+0.5))
    if (between & C.plot[1]<.) {
        if (C.xmin<min(C.at)) {
            grid = strofreal(C.at[1] - min((0.5, (C.at[1]-C.xmin)/2))) + " "
        }
    }
    for (i=1; i<=C.r; i++) {
        if (i>1) {
            if ((C.eqnm[i], C.coefnm[i])==(C.eqnm[i-1], C.coefnm[i-1])) {
                continue
            }
            if (between & C.plot[i-1]<.) {
                grid = grid + space + 
                    strofreal(C.at[i-1] + min((0.5, (C.at[i]-C.at[i-1])/2)))
            }
        }
        if (C.plot[i]<.) {
            labels = labels + space + strofreal(C.at[i]) + 
                " `" + `"""' + C.coeflbl[i] + `"""' + "'"
            if (between==0) grid = grid + space + strofreal(C.at[i])
            else if (i>1) {
                grid = grid + space + 
                    strofreal(C.at[i] - min((0.5, (C.at[i]-C.at[i-1])/2)))
            }
            space = " "
        }
    }
    st_local("xlabels", labels)
    st_local("xgrid", grid)
}

void coefplot_combine_ciopts()
{
    string scalar   opt, p

    opt = st_local("opt")
    p = substr(opt, 2, strpos(opt,"(")-2)   // get # from "p#(...)"
    if (strtoreal(p)<.) {
        opt = substr(opt, 3+strlen(p), strlen(opt)-3-strlen(p)) // get contents
        st_local("opt_"+p, st_local("opt_"+p) + " " + opt)
    }
    else {
        st_local("options", st_local("options") + " " + opt)
    }
}

void coefplot_parsecomma(string scalar lhs, string scalar rhs, string scalar lin)
{
    transmorphic    t
    string scalar   l, r, token
    
    t = tokeninit("", ",", (`""""', `"`""'"'), 0, 0)
    tokenset(t, st_local(lin))
    while ((token = tokenget(t))!="") {
        if (token==",") {
            r = token
            while ((token = tokenget(t))!="") {
                r = r + token
            }
            st_local(lhs, l)
            st_local(rhs, r)
            return
        }
        l = l + token
    }
    st_local(lhs, l)
    st_local(rhs, r)
}

void coefplot_inject_temvars(string scalar s, real scalar nci, 
    real scalar naux)
{
    st_local(s, _coefplot_inject_temvars(st_local(s), nci, naux))
}
string scalar _coefplot_inject_temvars(string scalar s, real scalar nci, 
    real scalar naux)
{
    real scalar      i
    string scalar    v, vname
    string rowvector nspace
    
    nspace = J(1, nci*2 + naux, "")
    for (i=1; i<=nci; i++) {
        nspace[i*2-1] = "ll" + strofreal(i)
        nspace[i*2]   = "ul" + strofreal(i)
    }
    for (i=1; i<=naux; i++) {
        nspace[nci*2+i] = "aux" + strofreal(i)
    }
    nspace = nspace, ("b", "V", "se", "t", "df", "pval", "at", "mlbl", "mlpos", "plot", "by")
    while (regexm(s,"@[Va-z]+[0-9]*")) {
        v = regexs()
        vname = substr(v, 2, .)
        if (vname=="ll" | vname=="ul" | vname=="aux") {
            vname = vname + "1"
        }
        if (anyof(nspace, vname)==0) {
            printf("{err}%s not found\n", v)
            exit(error(111))
        }
        s = subinstr(s, v, st_local(vname), 1)
    }
    return(s)
}

end




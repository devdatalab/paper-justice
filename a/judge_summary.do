/* bring in analysis dataset */
use $jdata/justice_analysis, clear

/* generate tenure */
gen tenure = tenure_end - tenure_start

/* generate convicted */
gen convicted = 1 - non_convicted

/* condition outcomes on decision */
/* PN: I don't think we want to */
// replace acq = . if decision == 0
// replace conv = . if decision == 0

/* set outcome vars */
global ovars decision acquitted convicted tenure 

/* generate number of cases at judge level */
bys judge: gen count = _N

/* generate acquittal rate given unambiguous decision */
gen decision_acquit = acq if !mi(decision_date) & ambiguous == 0

/* collapse data at judge level */
collapse $ovars judge_female judge_muslim [aweight = count], by(judge)
save $tmp/judge_collapse, replace

/* ---------------------------- cell:  ---------------------------- */

/**************************/
/* store paper statistics */
/**************************/
use $tmp/judge_collapse, clear
/* set timestamp */
set_log_time

/* statistic to be stored: judge gender shares in sample */
sum judge_female
local judge_fem_share: di %5.4f `r(mean)'
local judge_mal_share: di %5.4f 1 - `r(mean)'

/* statistic to be stored: judge religion shares in sample */
sum judge_muslim
local judge_mus_share: di %5.4f `r(mean)'
local judge_nm_share: di %5.4f 1 - `r(mean)'

/* write out saved statistics in a csv file */
store_validation_data `judge_fem_share' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Judge gender share: female") group("descriptive")
store_validation_data `judge_mal_share' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Judge gender share: male") group("descriptive")
store_validation_data `judge_mus_share' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Judge religion share: Muslim") group("descriptive")
store_validation_data `judge_nm_share' using $out/justice_paper_stats.csv, timestamp("$validation_logtime") test_type("Judge religion sahre: non-Muslim") group("descriptive")

/* generate an all variable */
gen all = 1

/* balance tables */
foreach o in $ovars judge_female judge_muslim {

  qui {
    
    /* summarize outcome if judge is female */
    mean `o' if judge_female == 1
    local mf: di %6.4f _b[`o']
    local sef: di %6.4f _se[`o']

    /* summarize outcome if judge is male */
    mean `o' if judge_female == 0
    local mm: di %6.4f _b[`o']
    local sem: di %6.4f _se[`o']

    /* summarize outcome if judge is Muslim */
    mean `o' if judge_muslim == 1
    local mmu: di %6.4f _b[`o']
    local semu: di %6.4f _se[`o']

    /* summarize outcome if judge is non-Muslim */
    mean `o' if judge_muslim == 0
    local mnm: di %6.4f _b[`o']
    local senm: di %6.4f _se[`o']

    /* summarize outcome for total column */    
    mean `o' if all == 1
    local mt: di %6.4f _b[`o']
    local set: di %6.4f _se[`o']

    /* store counts */
    count if judge_muslim == 1
    local nmus `r(N)'

    count if judge_muslim == 0
    local nnm `r(N)'

    count if judge_female == 1
    local nf `r(N)'

    count if judge_female == 0
    local nma `r(N)'

    count if all == 1
    local nt `r(N)'
  }

  /* store label */
  local y: variable label `o'    

  /* store results into csv */
  insert_into_file using $tmp/judge_summary.csv, key(mf_`o') value("`mf'") format(%6.4f)
  insert_into_file using $tmp/judge_summary.csv, key(sef_`o') value("`sef'") format(%6.4f)
  insert_into_file using $tmp/judge_summary.csv, key(mm_`o') value("`mm'") format(%6.4f)
  insert_into_file using $tmp/judge_summary.csv, key(sem_`o') value("`sem'") format(%6.4f)  
  insert_into_file using $tmp/judge_summary.csv, key(mmu_`o') value("`mmu'") format(%6.4f)    
  insert_into_file using $tmp/judge_summary.csv, key(semu_`o') value("`semu'") format(%6.4f)  
  insert_into_file using $tmp/judge_summary.csv, key(mnm_`o') value("`mnm'") format(%6.4f)    
  insert_into_file using $tmp/judge_summary.csv, key(senm_`o') value("`senm'") format(%6.4f)  
  insert_into_file using $tmp/judge_summary.csv, key(nmus) value("`nmus'") format(%12.0fc)
  insert_into_file using $tmp/judge_summary.csv, key(nnm) value("`nnm'") format(%12.0fc)  
  insert_into_file using $tmp/judge_summary.csv, key(nf) value("`nf'") format(%12.0fc)  
  insert_into_file using $tmp/judge_summary.csv, key(nma) value("`nma'") format(%12.0fc)  
  insert_into_file using $tmp/judge_summary.csv, key(nt) value("`nt'") format(%12.0fc)  
  insert_into_file using $tmp/judge_summary.csv, key(mt_`o') value("`mt'") format(%6.4f)
  insert_into_file using $tmp/judge_summary.csv, key(set_`o') value("`set'") format(%6.4f)
}


/* write out table */
table_from_tpl, t($jcode/tex/judge_balance_tpl.tex) r($tmp/judge_summary.csv) o($out/judge_summary.tex)


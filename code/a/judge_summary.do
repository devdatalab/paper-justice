/* bring in analysis dataset */
use $jdata/justice_analysis, clear

/* drop bail obs */
drop if bail == 1

/* generate tenure */
gen tenure = tenure_end - tenure_start

/* generate convicted */
gen convicted = 1 - non_convicted

/* set outcome vars */
global ovars decision acquitted convicted tenure 

/* generate number of cases at judge level */
bys judge: gen count = _N

/* collapse data at judge level */
collapse $ovars judge_female judge_muslim [aweight = count], by(judge)

/* generate an all variable */
gen all = 1

/* balance tables */
foreach o in $ovars judge_female judge_muslim{

  qui{
    
/* summarize outcome if judge is female */
  mean `o' if judge_female == 1
  local mf: di %6.3f _b[`o']
  local sef: di %6.3f _se[`o']

/* summarize outcome if judge is male */
  mean `o' if judge_female == 0
  local mm: di %6.3f _b[`o']
  local sem: di %6.3f _se[`o']

/* summarize outcome if judge is Muslim */
  mean `o' if judge_muslim == 1
  local mmu: di %6.3f _b[`o']
  local semu: di %6.3f _se[`o']

/* summarize outcome if judge is non-Muslim */
  mean `o' if judge_muslim == 0
  local mnm: di %6.3f _b[`o']
  local senm: di %6.3f _se[`o']

/* summarize outcome for total column */    
  mean `o' if all == 1
  local mt: di %6.3f _b[`o']
  local set: di %6.3f _se[`o']

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
  insert_into_file using $tmp/judge_summary.csv, key(mf_`o') value("`mf'") format(%6.3f)
  insert_into_file using $tmp/judge_summary.csv, key(sef_`o') value("`sef'") format(%6.3f)
  insert_into_file using $tmp/judge_summary.csv, key(mm_`o') value("`mm'") format(%6.3f)
  insert_into_file using $tmp/judge_summary.csv, key(sem_`o') value("`sem'") format(%6.3f)  
  insert_into_file using $tmp/judge_summary.csv, key(mmu_`o') value("`mmu'") format(%6.3f)    
  insert_into_file using $tmp/judge_summary.csv, key(semu_`o') value("`semu'") format(%6.3f)  
  insert_into_file using $tmp/judge_summary.csv, key(mnm_`o') value("`mnm'") format(%6.3f)    
  insert_into_file using $tmp/judge_summary.csv, key(senm_`o') value("`senm'") format(%6.3f)  
  insert_into_file using $tmp/judge_summary.csv, key(nmus) value("`nmus'") format(%12.0fc)
  insert_into_file using $tmp/judge_summary.csv, key(nnm) value("`nnm'") format(%12.0fc)  
  insert_into_file using $tmp/judge_summary.csv, key(nf) value("`nf'") format(%12.0fc)  
  insert_into_file using $tmp/judge_summary.csv, key(nma) value("`nma'") format(%12.0fc)  
  insert_into_file using $tmp/judge_summary.csv, key(nt) value("`nt'") format(%12.0fc)  
  insert_into_file using $tmp/judge_summary.csv, key(mt_`o') value("`mt'") format(%6.3f)
  insert_into_file using $tmp/judge_summary.csv, key(set_`o') value("`set'") format(%6.3f)

}
  

/* write out table */
table_from_tpl, t($out/judge_balance_temp.tex) r($tmp/judge_summary.csv) o($out/judge_summary.tex)     

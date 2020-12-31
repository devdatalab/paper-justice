/* import data */
use $jdata/justice_analysis, clear

/* drop bail obs */
drop if bail == 1

/* activate below depending on sample */
keep if women_crime == 1

/* drop women */
drop if def_female == 1

/* set outcome vars */
global ovars decision acquitted non_convicted positive_0 positive_1 

/* PROGRAM TO RUN CORELIGION / COGENDER TEST */
cap prog drop run_gender
prog def run_gender

  local sample wom

  di %15s " " %20s "f judge -> m def" 
  foreach y in $ovars {
    qui {
      qui reghdfe `y' judge_female def_muslim if lm_gender == 1 & def_female == 0, absorb(loc_month acts) cluster(judge)
      estimates store `y'_lm

      /* store N */
      local obs `e(N)'

      /* store control mean */
      sum `y' if def_female == 0 & lm_gender == 1 & judge_female == 0 & e(sample) == 1
      local cont: di %6.3f `r(mean)'
      local cont_est `cont'
      
      /* store effect of female judge on male defendant */
      local jfm: di %6.3f _b["judge_female"]
      local se: di %6.3f _se["judge_female"]
      local jfmse: di %6.3f _se["judge_female"]
      test judge_female = 0
      local p: di %5.2f (`r(p)')
      count_stars, p(`p')
      local jfm_est `jfm'`r(stars)' 
      
    }

    local demo "Female"
    local nondemo "Male"

    di %15s "`y': " %20s "`jfm_est'" %15s "(loc_month)"
    local A "A"
    local fe "Court-month"
    local identity "gender"
    
    /* store results into csv */
    insert_into_file using $tmp/glm_`sample'.csv, key(A) value("`A'") 
    insert_into_file using $tmp/glm_`sample'.csv, key(fe) value("`fe'") 
 
    /* store results into csv */
    insert_into_file using $tmp/glm_`sample'.csv, key(demo) value("`demo'") 
    insert_into_file using $tmp/glm_`sample'.csv, key(nondemo) value("`nondemo'") 
    insert_into_file using $tmp/glm_`sample'.csv, key(fjm_`y') value("`jfm_est'") format(%20s)
    insert_into_file using $tmp/glm_`sample'.csv, key(sefjm_`y') value("`jfmse'") format(%20s)
    insert_into_file using $tmp/glm_`sample'.csv, key(cons_`y') value("`cont_est'") format(%25s)
    insert_into_file using $tmp/glm_`sample'.csv, key(N_`y') value("`obs'") format(%25s)
    insert_into_file using $tmp/glm_`sample'.csv, key(id) value("`identity'") format(%25s)

    /* repeat with loc_year spec */
    qui {
      qui reghdfe `y' judge_female def_muslim if ly_gender == 1 & def_female == 0, absorb(loc_year acts) cluster(judge)
      estimates store `y'_ly

      /* store N */
      local obs `e(N)'

      /* store control mean */
      sum `y' if def_female == 0 & lm_gender == 1 & judge_female == 0 & e(sample) == 1
      local cont: di %6.3f `r(mean)'
      local cont_est `cont'
      
      /* store effect of female judge on male defendant */
      local jfm: di %6.3f _b["judge_female"]
      local se: di %6.3f _se["judge_female"]
      local jfmse: di %6.3f _se["judge_female"]
      test judge_female = 0
      local p: di %5.2f (`r(p)')
      count_stars, p(`p')
      local jfm_est `jfm'`r(stars)' 
      }

    local demo "Female"
    local nondemo "Male"
    
    di %15s "`y': " %20s "`jfm_est'" %15s "(loc_year)"
    local A "B"
    local fe "Court-year"
    local identity "gender"
    
    /* store results into csv */
    insert_into_file using $tmp/gly_`sample'.csv, key(A) value("`A'") 
    insert_into_file using $tmp/gly_`sample'.csv, key(fe) value("`fe'") 

    /* store results into csv */
    insert_into_file using $tmp/gly_`sample'.csv, key(demo) value("`demo'") 
    insert_into_file using $tmp/gly_`sample'.csv, key(nondemo) value("`nondemo'") 
    insert_into_file using $tmp/gly_`sample'.csv, key(fjm_`y') value("`jfm_est'") format(%20s)
    insert_into_file using $tmp/gly_`sample'.csv, key(sefjm_`y') value("`jfmse'") format(%20s)
    insert_into_file using $tmp/gly_`sample'.csv, key(cons_`y') value("`cont_est'") format(%25s)
    insert_into_file using $tmp/gly_`sample'.csv, key(N_`y') value("`obs'") format(%25s)
    insert_into_file using $tmp/gly_`sample'.csv, key(id) value("`identity'") format(%25s)
  }
end

/* DEFINE PROGRAM TO OUTPUT ANALYSIS RESULTS */x
cap prog drop output_gender
prog def output_gender

foreach fe in lm ly {

  local sample wom

    if "`fe'" == "lm" local label "Court-month FE"
    if "`fe'" == "ly" local label "Court-year FE"
    
  /* write estimates to tables */
  table_from_tpl, t($out/women_template.tex) r($tmp/g`fe'_`sample'.csv) o($out/g`fe'_`sample'.tex)     
}

end

/* set suffix for tex file output */
local sample wom

/* run defined programs */
run_gender
output_gender

la var group "state-dist-court no group"
ren date transitiondate
la var transitiondate "Transition date"
la var num_judges "# judges in the court"
la var num_mus_judges "# muslim judges in the court"
la var num_nm_judges "# non-muslim judges in the court"
la var num_male_judges "# male judges in the court"
la var num_female_judges "# female judges in the court"
la var num_judges_prev "# judges in the previous period"
la var num_judges_next "# judges in the next period"

foreach d in mus nm male female{
  la var `d'_judge_share "Share of `d' judges in court"
  la var num_`d'_judges_prev "# `d' judges in court in previous period"
  la var num_`d'_judges_next "# `d' judges in court in next period"
  la var `d'_judge_share_p "Share `d' judges in court in previous period"
  la var `d'_judge_share_n "Share `d' judges in court in next period"
}

la var date_start "tenure start of current judge"
la var date_end "a day prior to tenure start of next judge"
la var date_prev "date_start of previous judge"
la var date_next "date_end of next judge"

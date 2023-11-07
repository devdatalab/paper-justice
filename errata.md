# Errata 2023-11-07, REStat R&R

In revising this paper for the Review of Economics and Statistics, we came across the following two errors, which we have been corrected in the latest version. Here, we describe the errors in detail and show how the code has changed.

## Mis-coded fixed effects

In our previous submission, we had miscoded the court fixed effects, due to a mixup of variables describing the court complex (labeled `court_no`) and the court room in the building (`court`). The court * time fixed effect should refer to the court complex; we mistakenly calculated it using the court room variable. 

The previous code read:
```
/* generate fixed effect vars */
egen loc_month = group(state district court filing_year filing_month)
egen loc_year = group(state district court filing_year)
egen acts = group(act section)
egen judge = group(state district court judge_position tenure_start tenure_end)
```

We have replaced the `court_no` variable with `court`, such that the revised code reads:
```
/* generate fixed effect vars */
egen loc_month = group(state district court_no filing_year filing_month)
egen loc_year = group(state district court_no filing_year)
egen acts = group(act section)
egen judge = group(state district court_no judge_position tenure_start tenure_end)
```

Given the random assignment of judges, getting this fixed effect wrong should not substantively affect our results -- and it did not, but there are a few marginal changes:

* The in-group effect for judges and defendants who share last names falls from 3 percentage points to 2 percentage points, and is no longer statistically significant in the specification with court-month fixed effects (Table 6, p=0.11 and p=0.14 in Columns 3 and 5 respectively). It remains significant at the 5% level in the specification with court-year fixed effects (Table A23). We have also added Figure A7, which shows the effect is robust to alternate definitions of rare names. Our conclusions about in-group bias in this settings are not substantively changed by the new results, though we note in the paper that they are not robust to all specifications.

* In some specifications, we now find a small in-group effect on the speed of judge decision-making, which previously had been zero. Judges are 0.4 percentage points more likely to decide a case within six months if they have the same gender as the defendant. This is a small effect (1.5% of the mean), which we now discuss in the paper. Given the lack of effect on acquittals, we think the result is interesting but does not much change our overall claim that there we do not find much in-group bias.

## Incorrect Ramadan dates

In our previous submission, we reported a marginally significant heightening of in-group bias in the month of Ramadan. This was a spurious finding which resulted from a coding error in our specification of Ramadan dates, related to the order of operations of “and” and “or” operators. Correcting this error eliminated the Ramadan effect. Following referee advice, we extended this analysis to Hindu festival dates, where we also find null effects. We have updated the manuscript accordingly.

The previous submission had the following calculation of Ramadan dates:
```
gen ramadan = 0
replace ramadan = 1 if year == 2010 & (month(decision_date) == 08 & day(decision_date) >= 10) | (month(decision_date) == 09 & day(decision_date) <= 09)
replace ramadan = 1 if year == 2011 & (month(decision_date) == 07 & day(decision_date) >= 31) | (month(decision_date) == 08 & day(decision_date) <= 30)
replace ramadan = 1 if year == 2012 & (month(decision_date) == 07 & day(decision_date) >= 19) | (month(decision_date) == 08 & day(decision_date) <= 18)
replace ramadan = 1 if year == 2013 & (month(decision_date) == 07 & day(decision_date) >= 08) | (month(decision_date) == 08 & day(decision_date) <= 07)
replace ramadan = 1 if year == 2014 & (month(decision_date) == 06 & day(decision_date) >= 28) | (month(decision_date) == 07 & day(decision_date) <= 28)
replace ramadan = 1 if year == 2015 & (month(decision_date) == 06 & day(decision_date) >= 17) | (month(decision_date) == 07 & day(decision_date) <= 17)
replace ramadan = 1 if year == 2016 & (month(decision_date) == 06 & day(decision_date) >= 06) | (month(decision_date) == 07 & day(decision_date) <= 05)
replace ramadan = 1 if year == 2017 & (month(decision_date) == 05 & day(decision_date) >= 26) | (month(decision_date) == 06 & day(decision_date) <= 24)
replace ramadan = 1 if year == 2018 & (month(decision_date) == 05 & day(decision_date) >= 15) | (month(decision_date) == 06 & day(decision_date) <= 14)
```

This calculation has two errors: (1) The variable `year` refers to a case's filing year, rather than the decision year, while the month and day variables correctly are calculated from the date the case was decided. (2) The order of operations is wrong: a date will be classified as Ramadan if the final condition is true, even if the year condition is false.

The code has been corrected to the following:

```
  /* manually set ramadan dates */
  gen ramadan = 0
  replace ramadan = 1 if (year(decision_date) == 2010) & (((month(decision_date) == 08) & (day(decision_date) >= 10)) | ((month(decision_date) == 09) & (day(decision_date) <= 09)))
  replace ramadan = 1 if (year(decision_date) == 2011) & (((month(decision_date) == 07) & (day(decision_date) >= 31)) | ((month(decision_date) == 08) & (day(decision_date) <= 30)))
  replace ramadan = 1 if (year(decision_date) == 2012) & (((month(decision_date) == 07) & (day(decision_date) >= 19)) | ((month(decision_date) == 08) & (day(decision_date) <= 18)))
  replace ramadan = 1 if (year(decision_date) == 2013) & (((month(decision_date) == 07) & (day(decision_date) >= 08)) | ((month(decision_date) == 08) & (day(decision_date) <= 07)))
  replace ramadan = 1 if (year(decision_date) == 2014) & (((month(decision_date) == 06) & (day(decision_date) >= 28)) | ((month(decision_date) == 07) & (day(decision_date) <= 28)))
  replace ramadan = 1 if (year(decision_date) == 2015) & (((month(decision_date) == 06) & (day(decision_date) >= 17)) | ((month(decision_date) == 07) & (day(decision_date) <= 17)))
  replace ramadan = 1 if (year(decision_date) == 2016) & (((month(decision_date) == 06) & (day(decision_date) >= 06)) | ((month(decision_date) == 07) & (day(decision_date) <= 05)))
  replace ramadan = 1 if (year(decision_date) == 2017) & (((month(decision_date) == 05) & (day(decision_date) >= 26)) | ((month(decision_date) == 06) & (day(decision_date) <= 24)))
  replace ramadan = 1 if (year(decision_date) == 2018) & (((month(decision_date) == 05) & (day(decision_date) >= 15)) | ((month(decision_date) == 06) & (day(decision_date) <= 14)))
  replace ramadan = 1 if (year(decision_date) == 2019) & (((month(decision_date) == 05) & (day(decision_date) >= 05)) | ((month(decision_date) == 06) & (day(decision_date) <= 03)))
```


/* open the coefficient file from the literature */
use $tmp/lit_coefs, clear

/* create nicer labels */
replace study = "Lim et al. (2016)" if strpos(study, "Lim, Sil")
replace study = "Sloan (2020)" if strpos(study, "Carly")
replace study = "G-A & S-K (2010)" if strpos(study, "Gazal")
replace study = "Depew et al. (2017)" if strpos(study, "Depew")
replace study = "Knepper (2018)" if strpos(study, "Knep")
replace study = "Anwar et al. (2012)" if strpos(study, "Anwar")
replace study = "Shayo & Zussman (2011)" if strpos(study, "Shayo")
replace study = "Didwania (2020)" if strpos(study, "Stephanie")
replace study = "Ash et al. (2021)" if strpos(name, "India")
replace study = "Grossman et al. (2015)" if strpos(study, "Grossman et al")

/* shorten India study names */
replace study = substr(study, 5, 1) if strpos(study, "ash")

/* keep the standardized effects only */
keep study name std_effect_size std_se this
ren std_effect_size coef
ren std_se se

/* make coefficient size an absolute value */
label var coef "In-Group Bias Effect"
label var se   "Standard Error of In-Group Bias Effect"

/* get a regression coefficient */
reg coef se if this == 0
local b: di %2.1f _b["se"]
local se: di %2.1f _se["se"]
test se = 0
local p: di %6.3f `r(p)'

/* get the correlation coefficient */
corr coef se if this == 0

/* create four additional points for the significance threshold lines */
count
local n = `r(N)' + 2
set obs `n'
replace se = 0 if _n == `n' - 1
replace se = .2 if _n == `n'

/* calculate the 1.96 significant threshold */
gen threshold95 = se * 1.96
gen threshold90 = se * 1.96
gen mthreshold95 = -se * 1.96
gen mthreshold90 = -se * 1.96

global fitcolor 150 110 50

/* hide labels from current study for graph legibility */
replace study = "" if this == 1

/* draw the graph with the t=1.96 threshold */
sort se
twoway ///
    (scatter se coef if this == 1, msymbol(circle hollow) mlabel(study) mlabposition(3) mlabsize(vsmall) mlabcolor(black) mcolor(red)) ///
    (scatter se coef if this == 0, mlabel(study) mlabposition(12) mlabsize(vsmall) mlabcolor(black)) ///
    (line se threshold95, lpattern(dash) color("$fitcolor")) ///
    (line se mthreshold95, lpattern(dash) color("$fitcolor")) ///
    , xlabel(-.6(.2).6) xscale(range(-0.6 0.6)) xtitle("Standardized In-Group Bias Effect") ylabel(0(.05).2) ysc(reverse) ///
    legend(size(small) region(lcolor(black)) ring(0) pos(1) order(1 2) lab(1 "This study") lab(2 "Prior studies")) ///
    text(.47 .83 "Threshold where" "95% CI excludes 0", color("$fitcolor") justification(left) size(vsmall))

graphout pub_bias, pdf

exit
exit
exit

/* draw a graph without our study for twitter */
sort se
twoway ///
    (scatter se coef if this == 0, mlabel(study) mlabposition(12) mlabsize(vsmall) mlabcolor(black)) ///
    (line se threshold95, lpattern(dash) color("$fitcolor")) ///
    (line se mthreshold95, lpattern(dash) color("$fitcolor")) ///
    , xscale(range(-1.1 1.1)) xtitle("Standardized In-Group Bias Effect") ylabel(0(.1).5) ysc(reverse) legend(off) ///
    text(.47 .83 "Threshold where" "95% CI excludes 0", color("$fitcolor") justification(left) size(vsmall))

graphout pub_bias_not_us, pdf

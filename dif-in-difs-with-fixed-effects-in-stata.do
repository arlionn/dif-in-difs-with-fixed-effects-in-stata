***============================================================================
*	Using Stata to estimate difference-in-differences models with fixed effects
*	Author: Nicholas Poggioli (poggi005@umn.edu)
*	Stata version: 13.1
***============================================================================
clear all
set seed 61047

***==============
*	Generate data
***==============
set obs 400

* Firms
gen firm=_n

* Periods (24 quarters = 6 years)
expand 24
bysort firm: gen t=_n

* Periods--Assume single treatment event for all firms occurs in period 14
gen d=(t>=14)
label var d "=1 if post-treatment"

* Treatment and control groups
gen r=rnormal()
qui sum r, d
bysort firm: gen i=(r>=r(p50)) if _n==1
bysort firm: replace i=i[_n-1] if i==. & _n!=1
drop r
label var i "=1 if treated group, =0 if untreated group"

* Error
gen e = rnormal()
label var e "normal random variable"


***=========================================================================
*	Specify model
*	The effect of treatment is the coefficient on the interaction term = .56
***=========================================================================
gen y = .3 + .19*i + 1.67*d + .56*i*d + e


***===============
*	Estimate model
***===============
est clear

///	Pooled regression
*	Misspecified model
reg y i d
* This model omits the interaction. Estimates of i and d are badly biased.
reg y i d, robust
reg y i d, cluster(firm)
* Robust errors and clustering by firm do nothing to biased estimates.

*	Correctly specified model
reg y i d i.i##i.d
eststo pooled
* The interaction estimate is close
* Estimates of i and d are also close


///	areg
areg y i d i.i##i.d, absorb(firm)
eststo areg


///	Panel regression
xtset firm t, quarter

*	Misspecified model
xtreg y i d
xtreg y i d, fe
* i cannot be estimated because it is time invariant within panel id of firm
xtreg y i d, fe robust

*	Correctly specified model, random effects
xtreg y i d i.i##i.d
eststo xtreg_re
* This random-effects model produces identical estimates as correctly-specified pooled regression.

*	Correctly specified model, fixed effects
xtreg y i d i.i##i.d, fe
eststo xtreg_fe
* This fixed-effects model produces the same point estimates for the interaction
* and for d, but i is omitted because it does not vary within the panel id.
* The random-effects model can estimate i because it also uses across firm variation,
* and i varies across firms.



estout *, title("Actual parameter values are i = .19, d = 1.67, and i*d = .56") ///
	cells(b(star fmt(%9.3f)) se(par))   ///
	stats(N N_g, fmt(%9.0f %9.0g) label(N Groups))      	///
    legend collabels(none) varlabels(_cons Constant) keep(i d 1.i#1.d)

	
/*
estout * using "C:\Dropbox\GitHub\dif-in-difs-with-fixed-effects-in-stata\comparison-table.txt", ///
	title("Actual parameter values are i = .19, d = 1.67, and i*d = .56") ///
	style(fixed) replace				///
	cells(b(star fmt(%9.3f)) se(par))   ///
	stats(N N_g, fmt(%9.0f %9.0g) label(N Groups))      	///
    legend collabels(none) varlabels(_cons Constant) keep(i d 1.i#1.d)
*/



*END

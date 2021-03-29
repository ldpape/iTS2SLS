{smcl}
{* *! version 1.0 22march2021}{...}
{vieweralsosee "[R] poisson" "help poisson"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "ppml" "help ppml"}{...}
{vieweralsosee "ppmlhdfe" "help ppmlhdfe"}{...}
{viewerjumpto "Syntax" "iOLS_ivreg2##syntax"}{...}
{viewerjumpto "Description" "iOLS_ivreg2##description"}{...}
{viewerjumpto "Citation" "iOLS_ivreg2##citation"}{...}
{viewerjumpto "Authors" "iOLS_ivreg2##contact"}{...}
{viewerjumpto "Examples" "iOLS_ivreg2##examples"}{...}
{viewerjumpto "Description" "iOLS_ivreg2##Testing"}{...}
{viewerjumpto "Stored results" "iOLS_ivreg2##results"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:iOLS_ivreg2} {hline 2}}Iterated Two Stage Least Squares i2SLS) {p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:iOLS_OLS}
{depvar} [{indepvars}]
{ifin} {it:{weight}} {cmd:,} [{help iOLS_ivreg2##options:options}] {p_end}

{marker opt_summary}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opth a:bsorb(iOLS_ivreg2##indepvars:indepvars)}} list of explanatory variables{p_end}


{syntab:SE/Robust}
{synopt:{opt vce}{cmd:(}{help iOLS_OLS##opt_vce:vcetype}{cmd:)}}{it:vcetype}
may be {opt r:obust} (default) or {opt cl:uster} {help fvvarlist} (allowing two- and multi-way clustering){p_end}


{marker description}{...}
{title:Description}

{pstd}{cmd:iOLS_OLS} iterated Ordinary Least Squares,
as described by {browse "https://sites.google.com/site/louisdanielpape/":Bellego, Benatia, and Pape (2021)}.

{pstd}This package:

{pmore} 1. relies on Stata's ivreg2 procedure for estimation.{p_end}

{pmore} 2. assumes the iOLS exogeneity condition with delta = 1 with instrument Z. {p_end}


{title:Background}

{pstd} i2SLS_delta is a solution to the problem of the log of zero with endogenous variables.  The parameter associated with a log-transformed dependent variable can be interpreted as an elasticity. 


{marker absvar}{...}
{title:Syntax for absorbed variables}

{synoptset 22}{...}
{synopthdr: variables}
{synoptline}
{synopt:{it:depvar}} Dependent variable{p_end}
{synopt:{it:indepvars}} List of explanatory variables {p_end}
{synoptline}
{p2colreset}{...}


{marker caveats}{...}
{title:Caveats}

{pstd}Convergence is decided based on coefficients and not on the modulus of the contraction mapping. {opth tol:erance(#)}.


{pstd}The {help reg postestimation##predict:predict}, {help test}, and {help margins} postestimation commands are available after {cmd:iOLS_OLS}.


{marker contact}{...}
{title:Authors}

{pstd}Louis Pape {break}
CREST {break}
Email: {browse "mailto:louis.pape@polytechnique.edu":louis.pape@polytechnique.edu}
{p_end}




{marker citation}{...}
{title:Citation}

{pstd}
Citation to be defined. 


{marker examples}{...}
{title:Examples}

{pstd}First, we will replicate Example 1 from Stata's
{browse "https://www.stata.com/manuals/rpoisson.pdf":poisson manual}.
{p_end}
{hline}
{phang2}{cmd:. use "http://www.stata-press.com/data/r14/airline"}{p_end}
{phang2}{cmd:. iOLS_ivreg2 injuries (XYZowned=n) , vce(robust)}{p_end}
{phang2}{cmd:. ivpois injuries (XYZowned=n)}{p_end}
{hline}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:iOLS_ivreg2} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N)}}number of observations{p_end}

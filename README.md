# i2SLS
Provides the endogenous regressor approach to iOLS based on Bellego, Benatia and Pape (2021)

This code relies on the "ivreg2" function of Stata and is appropriate for models which are able to be estimated using this function.

To install this code into Stata, run the following :

cap ado uninstall iOLS_ivreg2

net install iOLS_ivreg2, from("https://raw.githubusercontent.com/ldpape/i2SLS/master/")

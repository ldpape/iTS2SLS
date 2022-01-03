#  Iterated Two Sample Two Stage Least Squares (iT2SLS) for any delta>0

# /!\ Still preliminary : use at your own risk.
To install this code into Stata, run the following (requires at least Stata 14): 

>cap ado uninstall iTS2SLS

>net install iTS2SLS, from("https://raw.githubusercontent.com/ldpape/i2SLS/master/")

You will need to have the following packages installed using:
>ssc install moremata

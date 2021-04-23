program define i2SLS_ivreg2, eclass
	syntax [anything] [if]  [in] [aweight pweight fweight iweight]  [, DELta(real 1) gmm2s Robust CLuster(varlist numeric)]
	marksample touse
	
	if "`gmm2s'" !="" {
		local opt0 = "`gmm2s' "
	}
	if  "`robust'" !="" {
		local opt1  = "`robust' "
	}
	if "`cluster'" !="" {
		local opt2 = "cluster(`cluster') "
	}
	local option = "`opt0'`opt1'`opt2'"
		
	local list_var `anything'
	* Remarque : la fct gettoken utilise directement des local variables 
	* en 2e et 3e argument, donc pas besoin de prÃ©ciser que ce sont des
	* local variable en ajoutant les guillemets stata : `'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
    * get endogenous variables and instruments
	gettoken endog list_var : list_var, bind
	gettoken endog endog : endog, p("(")
    gettoken endog instr_temp : endog , p("=")
    gettoken equalsign instr_temp : instr_temp , p("=")
	gettoken instr instr_temp : instr_temp, p(")")
	
	*di `"`depvar'"'
	*di `"`indepvar'"'
	*di `"`endog'"'
	*di `"`instr'"'
	
	*** Initialisation de la boucle
	tempvar y_tild 
	gen `y_tild' = log(`depvar' + 1)
	quietly ivreg2 `y_tild' `indepvar' (`endog' = `instr') [`weight'`exp'] if `touse', `option'
	matrix beta_new = e(b)
	local k = 0
	local eps = 1000	
	*** ItÃ©rations iOLS
	_dots 0
	while (`k' < 1000 & `eps' > 1e-15) {
		matrix beta_initial = beta_new
		* Nouveaux beta
		tempvar xb_hat
		predict `xb_hat', xb
		tempname cste_hat
		scalar `cste_hat' = _b[_cons]
		* Calcul de phi_hat
		tempvar temp1
		gen `temp1' = `depvar' * exp(-(`xb_hat' - `cste_hat'))
		quietly sum `temp1' [`weight'`exp'] if e(sample)
		tempname phi_hat
		scalar `phi_hat' = log(`r(mean)')
		* Calcul de c_hat
		tempvar temp2
		gen `temp2' = log(`depvar' + `delta'*exp(`phi_hat' + (`xb_hat' - `cste_hat'))) - (`phi_hat' + (`xb_hat' - `cste_hat'))
		quietly sum `temp2' [`weight'`exp'] if e(sample)
		tempname c_hat
		scalar `c_hat' = `r(mean)'
		* Update d'un nouveau y_tild et regression avec le nouvel y_tild
		quietly replace `y_tild' = log(`depvar' + `delta' * exp(`xb_hat')) - `c_hat'
		quietly ivreg2 `y_tild' `indepvar' (`endog' = `instr')  if `touse' [`weight'`exp'] , `option' // ffirst saverf
		matrix beta_new = e(b)
		* DiffÃ©rence entre les anciens betas et les nouveaux betas
		matrix diff = beta_initial - beta_new
		mata : st_matrix("abs_diff", abs(st_matrix("diff")))
		mata : st_matrix("abs_diff2", st_matrix("abs_diff"):*st_matrix("abs_diff"))
		mata : st_matrix("criteria", rowsum(st_matrix("abs_diff2"))/cols(st_matrix("abs_diff2")))
		local eps = criteria[1,1]
		local k = `k'+1
		_dots `k' 0
	}

	*** Calcul de la bonne matrice de variance-covariance
	* Calcul du "bon" rÃ©sidu
	preserve
	keep if e(sample)	
	tempvar xb_hat
	predict `xb_hat', xb
	tempvar ui
	gen `ui' = exp(`y_tild' + `c_hat' - `xb_hat') - `delta'
	matrix beta_final = e(b)
	quietly sum [`weight'`exp'] if e(sample)
	tempname nobs
	scalar `nobs' = r(N)
	* Calcul de Sigma_0, de I-W, et de Sigma_tild
	matrix Sigma = e(V)
	tempname cste
	gen `cste' = 1
	tempvar ui_bis
	gen `ui_bis' = 1 - `delta'/(`delta' + `ui')
	local var_list `indepvar' `endog' `cste'
	local instr_list `indepvar' `instr' `cste'
	mata : X=.
	mata : Z=.
	mata : IW=.
	mata : st_view(X,.,"`var_list'")
	mata : st_view(Z,.,"`instr_list'")
	mata : st_view(IW,.,"`ui_bis'")
	mata : IW = diag(IW)
	mata : Pz = Z*invsym(Z'*Z)*Z'
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = (X'*Pz*X)*Sigma_hat*(X'*Pz*X)
	mata : invXpPzIWX = invsym(X'*(2)*(Pz*IW+IW*Pz)*X)
	mata : Sigma_tild = invXpPzIWX*Sigma_0*invXpPzIWX
	mata : list_Variance = diagonal(Sigma_tild)
	mata : list_std_err = sqrt(list_Variance)
	mata : st_matrix("list_std_err", list_std_err)
   mata: st_matrix("Sigma_tild", Sigma_tild) // used in practice
	*** Stocker les rÃ©sultats dans une matrice
	local names : colnames e(b)
	local nbvar : word count `names'
	*mat result=J(`=`nbvar'+5',3,.) //Defining empty matrix
	*mat rownames result = `names' "nobs" "niter" "criteria" "FStatWeakId" "And.Rub.FStat"
	*mat colnames result = "Beta" "Std.Er." "StdErApprox"
	*forv n=1/`nbvar' {
	*	mat result[`n',1] = beta_final[1,`n']
	*	mat result[`n',2] = list_std_err[`n',1]
	*	mat result[`n',3] = sqrt(Sigma[`n',`n'])*(1+`delta')
	*}
	*mat result[`=`nbvar'+1',1] = `nobs'
	*mat result[`=`nbvar'+2',1] = `k'
	*mat result[`=`nbvar'+3',1] = `eps'
	*mat result[`=`nbvar'+4',1] = e(widstat)
	*mat result[`=`nbvar'+5',1] = e(arf)
	*mat list result
		mat rownames Sigma_tild = `names' 
    mat colnames Sigma_tild = `names' 
    ereturn post beta_final Sigma_tild , obs(`=r(N)') depname(`depvar') esample(`touse')  dof(`=r(df r)') 
	restore 
ereturn scalar delta = `delta'
ereturn  scalar eps =   `eps'
ereturn  scalar niter =  `k'
ereturn scalar widstat = e(widstat)
ereturn scalar arf = e(arf)
ereturn local cmd "i2SLS"
ereturn local vcetype `option'
ereturn display
end

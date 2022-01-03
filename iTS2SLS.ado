* 16/12 : change constant calculation to avoid a log of 0 & change eps.
* 19/12 change covariance matrix calculation for large data set
* 19/12 : add correction when no covariate is included.
* 21/12 : Manual iteration of 2SLS GMM + options to control nb iterations /convergence..

// need ivreg2, moremata
cap program drop iTS2SLS
program define iTS2SLS, eclass
	syntax [anything] [if]  [in] [aweight pweight fweight iweight]  [, DELta(real 1) LIMit(real 0.00001) MAXimum(real 1000) Robust CLuster(varlist numeric)]
	marksample touse
	preserve   // you need to enter x = xb_hat 
	quietly keep if `touse'
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
	*** Obtain lists of variables 
	local list_var `anything'
	gettoken depvar list_var : list_var
	if (strpos("`list_var'","(")==2){  // anormal case : no X, only Z 
	local list_var: subinstr local list_var "(" "", all
	local indepvar 
	gettoken endog list_var : list_var, bind
	gettoken endog instr_temp : endog , p("=")
	local list_var: subinstr local list_var "=" "", all
	gettoken instr list_var : list_var, bind
	}
	else{  // normal case : X exists 
	gettoken indepvar list_var : list_var, p("(")
	gettoken endog list_var : list_var, bind
	gettoken endog endog : endog, p("(")
	gettoken endog instr_temp : endog , p("=")
	gettoken equalsign instr_temp : instr_temp , p("=")
	gettoken instr instr_temp : instr_temp, p(")")
	}
			
	*** Initialisation de la boucle
	tempvar y_tild 
	quietly gen `y_tild' = log(`depvar' + 1)
	tempvar cste
	gen `cste' = 1
	** drop collinear variables
    _rmcoll `indepvar' `cste', forcedrop 
	local var_list `endog' `r(varlist)' `cste'  
	local instr_list `instr' `r(varlist)' `cste' 
	** prepare 2SLS
	*local var_list  `endog' `indepvar' `cste'
	*local instr_list `instr' `indepvar' `cste'
	mata : X=.
	mata : Z=.
	mata : y_tilde =.
	mata : y =.
	mata : st_view(X,.,"`var_list'")
	mata : st_view(Z,.,"`instr_list'")
	mata : st_view(y_tilde,.,"`y_tild'")
	mata : st_view(y,.,"`depvar'")
	mata : invPzX = invsym(cross(Z,Z)) // X1_hat in Inoue & Solon 
	mata : beta_initial = invPzX*cross(Z,y_tilde)
	mata : beta_t_1 = beta_initial // needed to initialize
	mata : beta_t_2 = beta_initial // needed to initialize
	mata : q_hat_m0 = 0
	local k = 1
	local eps = 1000	
	mata: q_hat = J(`maximum', 1, .)
	*** Iterations iOLS
	_dots 0
	while ((`k' < `maximum') & (`eps' > `limit' )) {
		* Nouveaux beta
	mata: alpha = log(mean(y:*exp(-X[.,1..(cols(X)-1)]*beta_initial[1..(cols(X)-1),1]) ))
	mata : beta_initial[(cols(X)),1] = alpha
	mata: xb_hat = X*beta_initial
		* Update d'un nouveau y_tild et regression avec le nouvel y_tild
	mata: y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat))- xb_hat)
		* 2SLS 
	mata: beta_new = invPzX*cross(Z,y_tilde)
		* DiffÃ©rence entre les anciens betas et les nouveaux betas
	mata: criteria = mean(abs(beta_initial - beta_new):^(2))
	mata: st_numscalar("eps", criteria)
	mata: st_local("eps", strofreal(criteria))
		* safeguard for convergence.
	if `k'==`maximum'{
		  di "There has been no convergence so far: increase the number of iterations."  
	}
	if `k'>4{
	mata: q_hat[`k',1] = mean(log( abs(beta_new-beta_initial):/abs(beta_initial-beta_t_2)):/log(abs(beta_initial-beta_t_2):/abs(beta_t_2-beta_t_3)))	
	mata: check_3 = abs(mean(q_hat)-1)
		if mod(`k'-4,50)==0{
    mata: q_hat_m =  mm_median(q_hat[((`k'-49)..`k'),.] ,1)
	mata: check_1 = abs(q_hat_m - q_hat_m0)
	mata: check_2 = abs(q_hat_m-1)
	mata: st_numscalar("check_1", check_1)
	mata: st_local("check_1", strofreal(check_1))
	mata: st_numscalar("check_2", check_2)
	mata: st_local("check_2", strofreal(check_2))
	mata: st_numscalar("check_3", check_3)
	mata: st_local("check_3", strofreal(check_3))
	mata: q_hat_m0 = q_hat_m
		if ((`check_1'<1e-4)&(`check_2'>1e-2)) {
di "delta is too small to achieve convergence -- update to larger value"
	local k = `maximum'
		}
		if ((`check_3'>0.5) & (`k'>500)) {
	local k = `maximum'
di "q_hat too far from 1"
		}
					  }
	}
	if `k'>2 { // keep in memory the previous beta_hat for q_hat 
	mata:   beta_t_3 = beta_t_2
	mata:   beta_t_2 = beta_initial
	}
	mata: beta_initial = beta_new // beta_hat_t and beta_hat_t_1
	local k = `k'+1
	_dots `k' 0
	}
	*** Calcul de la bonne matrice de variance-covariance
	* Calcul du "bon" rÃ©sidu
	mata: xb_hat = X*beta_new
	mata : y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat)) - xb_hat)
	* 	gen `ui' = exp(`y_tild' + `c_hat' - `xb_hat') - `delta'
	mata: ui = y:*exp(-xb_hat)
	mata: ui = ui:/(`delta' :+ ui)
	* Retour en Stata 
	cap drop y_tild 
	quietly mata: st_addvar("double", "y_tild")
	mata: st_store(.,"y_tild",y_tilde)
	quietly reg y_tild `r(varlist)' `instr' [`weight'`exp'] if `touse', `option'  // regress on xb_hat and other covariates. 
	* Calcul de Sigma_0, de I-W, et de Sigma_tild
	matrix beta_final = e(b) // 	mata: st_matrix("beta_final", beta_new)
	matrix Sigma = e(V)
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = (cross(X,Z)*invsym(cross(Z,Z))*cross(Z,X))*Sigma_hat*(cross(X,Z)*invsym(cross(Z,Z))*cross(Z,X)) // recover original HAC 
	mata : invXpPzIWX = invsym(0.5*cross(X,Z)*invsym(cross(Z,Z))*cross(Z,ui,X)+ 0.5*cross(X,ui,Z)*invsym(cross(Z,Z))*cross(Z,X))
*	mata : invXpPzIWX = invsym(0.5*X'*(Z*invsym(cross(Z,Z))*(Z':*ui')+ (ui:*Z)*invsym(cross(Z,Z))*Z')*X)
	*mata : invXpPzIWX = invsym(0.5*X'*(Pz*IW+IW*Pz)*X)
	mata : Sigma_tild = invXpPzIWX*Sigma_0*invXpPzIWX
    mata: st_matrix("Sigma_tild", Sigma_tild) // used in practice
	*** Stocker les resultats dans une matrice
	local names : colnames e(b)
	local nbvar : word count `names'
	mat rownames Sigma_tild = `names' 
    mat colnames Sigma_tild = `names' 
    ereturn post beta_final Sigma_tild , obs(`=e(N)') depname(`depvar') esample(`touse')  dof(`=e(df r)') 
	restore 
ereturn scalar delta = `delta'
ereturn  scalar eps =   `eps'
ereturn  scalar niter =  `k'
ereturn local cmd "iTS2SLS"
ereturn local vcetype `option'
ereturn display
end

/*

        * get clustered variance estimate for first stage
        mat Vx2cluster = e(V)
		* number of predicted variables
        scalar kx = e(df_m)
        * number of exogenous variables, here constant because Art Unit-app year FEs are partialled out
        scalar ke = 1
        * predicted values from first stage
        predict `endog'h
        *** construct Chat (eq. 11 Picini-Windmeijer) ***

         * adjust Chat for exogenous Art Unit-app year FEs
       // mat Chat = Chat,(J(kx,ke,0)\I(ke))
         *** TS2SLS point estimates ***
            areg `outcome' `endog'h, absorb(auy_numeric)
            * get instrumented point estimates
            mat b2s = e(b)
      //      mat b2sx = b2s[1,1..kx]'
            *** get clustered second stage variance estimate ***
            areg `outcome' `instrument', cluster(appnum) absorb(auy_numeric)
            * clustered variance estimate of piy1 from Picini-Windmeijer
            mat Vy1cluster = e(V)
            * calculating clustered standard errors (eq. 12 Picini-Windmeijer)
            mat var1cluster =  Chat*Vy1cluster*Chat' + (b2s' # Chat)*Vx2cluster*(b2s # Chat')

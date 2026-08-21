function dydt = bank_model(t,y,alpha_D,K_D,omega,alpha_L,K_L,eta,delta,alpha_p,alpha_E,r_A,r_E,c_D,c_L,c_E,r_L,r_D,rho,lambda)
    D = y(1); L = y(2); E = y(3);
    A = (1-rho)*D + E - L;
    
    % Profit
    Pi = ((1-eta)*r_L - r_A - c_L)*L + ((1-rho)*r_A + (omega-1)*r_D - c_D)*D + (r_A - r_E)*E;
    
    % Modal Adjustment (l)
    ratio = E/(D+E);
    if ratio >= lambda
        l = 0;
    else
        l = alpha_E*((lambda*D)/(1-lambda) - E);
    end
    
    dDdt = alpha_D*D*(1 - D/K_D) - omega*D;
    dLdt = alpha_L*A*L*(1 - L/K_L) - (eta + delta*(1-eta))*L;
    dEdt = alpha_p*Pi - eta*L + l-c_E*E;
    
    dydt = [dDdt; dLdt; dEdt];
end
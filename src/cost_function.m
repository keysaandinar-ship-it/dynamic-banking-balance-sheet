function cost = cost_function(param,tdata,Ddata,Ldata,Edata,r_L,r_D,eta)
    aD=param(1); KD=param(2); om=param(3); aL=param(4); KL=param(5); 
    de=param(6); ap=param(7); aE=param(8); rA=param(9); rE=param(10); 
    cD=param(11); cL=param(12); cE = param(13); 
    
   
    lambda = 0.03;
    rho    = 0.075;
    
    
    % Constraint Ekonomi (Jika dilanggar, beri cost tinggi tapi jangan langsung mati)
    if (rA - rE) <= 0 || (1 - eta)*r_L <= rA + cL
        cost = 1e12; 
        return;
    end

    try
        y0 = [Ddata(1) Ldata(1) Edata(1)];
        [~, y] = ode15s(@(t,y) bank_model(t,y,aD,KD,om,aL,KL,eta,de,ap,aE,rA,rE,cD,cL, cE ,r_L,r_D,rho,lambda), tdata, y0);
        
        if size(y,1) < length(tdata)
            cost = 1e10; return;
        end
        
        Dsim = y(:,1); Lsim = y(:,2); Esim = y(:,3);
        
        mD = mean(abs((Ddata-Dsim)./max(Ddata,1e-6)))*100;
        mL = mean(abs((Ldata-Lsim)./max(Ldata,1e-6)))*100;
        mE = mean(abs((Edata-Esim)./max(Edata,1e-6)))*100;
        
        cost = 1.3*mD + mL + mE;
    
    catch
        cost = 1e12;
    end
end
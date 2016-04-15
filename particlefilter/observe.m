function w = observe( GQRS,WABP,GQRS_HR,WABP_HR,ecg_sqi,abp_sqi,x,t,window,indices )
%OBSERVE Summary of this function goes here
%   Detailed explanation goes here

if indices(1) && ecg_sqi(t) >= .8
    if indices(2) && abp_sqi(t) == 1 && ~isnan(WABP_HR(t)) && ...
            ~isnan(GQRS_HR(t)) && (GQRS_HR(t) > 1.5*WABP_HR(t))
        w = observeABP(WABP(t),WABP_HR(t),x,t,window);
    else
        w = observeECG(GQRS(t),GQRS_HR(t),x,t,window);    
    end
elseif indices(2) && abp_sqi(t) == 1
    w = observeABP(WABP(t),WABP_HR(t),x,t,window);
else
    if indices(1)
        w = observeECG(GQRS(t),GQRS_HR(t),x,t,window);
    else
        w = observeABP(WABP(t),WABP_HR(t),x,t,window);
    end
end

w(isnan(w))=0;
if sum(w) == 0
    w = 1/2*ones(1,numel(w));
end
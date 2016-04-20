function w = observeABP(WABP,WABP_HR,x,t,window)
TrueHR = x(1,:);
LastPeakABP = x(9,:);
ABPpeak = x(6,:);
ABPart = x(7,:);

beat_prob = prob_function(t-LastPeakABP, TrueHR, window);
beat_prob(isnan(beat_prob)) = 0;
soft_beat_prob = (beat_prob + .5)/2;

w1 = (ABPpeak==0).*(ABPart==0).*(WABP==0).*(1-beat_prob) + ...
(ABPpeak==0).*(ABPart==0).*(WABP==1).*beat_prob + ...
(ABPpeak==0).*(ABPart==1).*(WABP==0).*(1-soft_beat_prob) + ...
(ABPpeak==0).*(ABPart==1).*(WABP==1).*soft_beat_prob + ...   % spurious detection
(ABPpeak==1).*(ABPart==0).*(WABP==0)*0.01 + ...
(ABPpeak==1).*(ABPart==0).*(WABP==1)*0.99 + ...
(ABPpeak==1).*(ABPart==1).*(WABP==0)*0.3 + ...   % missing detection
(ABPpeak==1).*(ABPart==1).*(WABP==1)*0.7;

w2 = normpdf(WABP_HR,TrueHR,1/4*abs(TrueHR));

if isnan(WABP_HR)
    w = w1;
else
    w = w1.*w2;
end


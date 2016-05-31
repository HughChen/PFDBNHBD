function w = observeECG(GQRS,GQRS_HR,x,t,window)
% Calculates weight for particle based on given heart rate, GQRS
% annotation observations, time, and the state of the particle 
TrueHR = x(1,:);
ECGart = x(2,:);
ActualBeat = x(3,:);
LastPeak = x(4,:);

beat_prob = prob_function(t-LastPeak, TrueHR, window);
beat_prob(isnan(beat_prob)) = 0;
soft_beat_prob = (beat_prob + .5)/2;

w1 = (ActualBeat==0).*(ECGart==0).*(GQRS==0).*(1-beat_prob) + ...
(ActualBeat==0).*(ECGart==0).*(GQRS==1).*beat_prob + ...
(ActualBeat==0).*(ECGart==1).*(GQRS==0).*(1-soft_beat_prob) + ...
(ActualBeat==0).*(ECGart==1).*(GQRS==1).*soft_beat_prob + ...   % spurious detection
(ActualBeat==1).*(ECGart==0).*(GQRS==0)*0.01 + ...
(ActualBeat==1).*(ECGart==0).*(GQRS==1)*0.99 + ...
(ActualBeat==1).*(ECGart==1).*(GQRS==0)*0.3 + ...   % missing detection
(ActualBeat==1).*(ECGart==1).*(GQRS==1)*0.7;

w2 = normpdf(GQRS_HR,TrueHR,1/4*abs(TrueHR));

if isnan(GQRS_HR)
    w = w1;
else
    w = w1.*w2;
end


function x = prior(N,window,averageHR)
% prior for heart beat annotation model
x = zeros(9,N);
RestingHR = min(max(40,averageHR+10*randn(1,N)),100);
TrueHR = RestingHR + 5*randn(1,N);
ECGart = rand(1,N)>0.99; % no artifact wp 0.99
LastPeak = zeros(1,N);
for i=1:N;
    LastPeak(i) = -1*randi(round(60./(window*TrueHR(i))),1);
end
ActualPeak = rand(1,N)>0.99; % no peak wp 0.99
Latency = .2/window + 1*randn(1,N);
Delay = round( Latency + (Latency/10).*randn(1,N) );
ABPart = rand(1,N)>0.99;
ABPpeak = (0 == (LastPeak + Delay) );
LastPeakABP = LastPeak + Delay;

x(1,:) = TrueHR;
x(2,:) = ECGart;
x(3,:) = ActualPeak;
x(4,:) = LastPeak;
x(5,:) = RestingHR;
x(6,:) = ABPpeak;
x(7,:) = ABPart;
x(8,:) = Latency;
x(9,:) = LastPeakABP;

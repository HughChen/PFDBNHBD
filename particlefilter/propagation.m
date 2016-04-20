function y = propagation(x,t,window)
% Propagate according to the system dynamics
N = size(x,2);
TrueHR_old = x(1,:);
ECGart_old = x(2,:);
ActualPeak_old = x(3,:);
LastPeak_old = x(4,:);
RestingHR = x(5,:);
ABPpeak_old = x(6,:);
ABPart_old = x(7,:);
Latency = x(8,:);
LastPeakABP_old = x(9,:);

Delay = ones(1,numel(Latency)).*round(mean(Latency));
ABPpeak_new = (t == (LastPeak_old + Delay) );
TrueHR_new = 0.8*TrueHR_old + 0.2*RestingHR + 15*randn(1,N);
ECGart_new = (ECGart_old==0).*(rand(1,N)>0.99) + (ECGart_old==1).*(rand(1,N)<0.99);
probability = prob_function(t-LastPeak_old,TrueHR_new,window);
ActualPeak_new = rand(1,N)< probability;
LastPeak_new = (ActualPeak_new==1).*t + (ActualPeak_new==0).*LastPeak_old;
ABPart_new = (ABPart_old==0).*(rand(1,N)>0.99) + (ABPart_old==1).*(rand(1,N)<0.99);
LastPeakABP_new = (ABPpeak_new==1).*t + (ABPpeak_new==0).*LastPeakABP_old;

y = zeros(4,N);
y(1,:) = TrueHR_new;
y(2,:) = ECGart_new;
y(3,:) = ActualPeak_new;
y(4,:) = LastPeak_new;
y(5,:) = RestingHR;
y(6,:) = ABPpeak_new;
y(7,:) = ABPart_new;
y(8,:) = Latency;
y(9,:) = LastPeakABP_new;
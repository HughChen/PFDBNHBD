function y = prob_function(difference, TrueHR,window)
% Utilizes a repeated binomial distribution to determine the 
% probability of the next beat.

beat_window = 60./(window*TrueHR);
k = mod(difference,floor(beat_window));
n = round((3/2)*floor(beat_window));
p = 2/3;
neg = (n < 0)|(k < 0)|(n-k < 0)|(difference < (1/3)*beat_window);
n(neg) = 1;
k(neg) = 1;
choose_value = round(exp(gammaln(n+1)-gammaln(k+1)-gammaln(n-k+1)));
y1 = choose_value.*(p.^k).*((1-p).^(n-k));
y1(neg) = 0;
k = k + floor(beat_window);
neg = (n < 0)|(k < 0)|(n-k < 0)|(difference < (1/3)*beat_window);
n(neg) = 1;
k(neg) = 1;
choose_value = round(exp(gammaln(n+1)-gammaln(k+1)-gammaln(n-k+1)));
y2 = choose_value.*(p.^k).*((1-p).^(n-k));
y2(neg) = 0;
y = max(y1,y2);
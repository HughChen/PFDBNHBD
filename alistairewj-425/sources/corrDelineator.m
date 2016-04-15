function [onset,peak] = corrDelineator(signal,peakp,onsetp,Fs,doCorr)
% Correct location of peaks detected using delineator
%

if nargin < 5
    doCorr = 0;
end
onset = onsetp;
peak = peakp;
L = length(signal);
w = round(.2*Fs);
for i = 1 : length(peakp)
    ind = max([1 peakp(i)-w]):min([L peakp(i)+w]);
    [~, indMax] = max(signal(ind));
    peak(i) = ind(indMax);
end
peak = peak(:);
d = diff(peak);
if doCorr
for i = 2 : length(d)-1
    if d(i)>=d(i-1)*1.8 && d(i)<=d(i-1)*2.2
        [~,ind] = max(signal(peak(i)+.2*Fs:peak(i+1)+.2*Fs));
        peak = [peak; ind];
    end
end
end
peak = sort(peak);

end
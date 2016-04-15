function abpview(bingosig,bingoanns,bingoannp,bingoannd)
% To visualize delineation results
% Inputs:
%   bingosig: input pulse waveform signals;
%   bingoanns: the beginning index of each beat;
%   bingoannp: indices of systolic peaks;
%   bingoannd: indices of dicrotic notches;

% Reference:
%   BN Li, MC Dong & MI Vai (2010) 
%   On an automatic delineator for arterial blood pressure waveforms
%   Biomedical Signal Processing and Control 5(1) 76-81.

% LI Bing Nan @ University of Macau, Feb 2007
%   Revision 2.0.5, Apr 2009

abp=bingosig;
onsetp=bingoanns;
peakp=bingoannp;
dicron=bingoannd;

t  = 1:length(abp);
h  = plot(t, abp, ...
    onsetp, abp(onsetp), 'm>', ...
    peakp, abp(peakp), 'r^', ...
    dicron, abp(dicron), 'g*');
legend('Pulse Waveforms', 'Onset', 'Speak', 'Dicron');
set(h, 'Markersize', 6);
xlabel('Time, Samples');
ylabel('Signal & Delineation'); 
grid on
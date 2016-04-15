function [ sqi, tsqi ] = ecgsqi_mod( ann1, ann2, THR )

if nargin < 3
    THR = 0.15; % window for matching two peaks
end

% Use histc to bin each jqrs into bins centered on gqrs
xi = [ann1' - THR;
    ann1' + THR];
xi = xi(:);

% we now replace monotonically non-decreasing entries with their avg
% normally, we have two ECG beats next to each other, and windows do
% not overlap, i.e.:   |  x  |     l  x  l

% where 'x' is a beat with || and ll define the +- window

% sometimes the beats are too close however, and the windows overlap
% the following code changes windows like this:  |  l |  l
% to windows like this:                          |   |l  l

idxFix = [false;diff(xi) < 0];
xi_fixed = [xi(idxFix),xi([idxFix(2:end);false])];
xi_fixed = mean(xi_fixed,2);

xi(idxFix) = xi_fixed;
xi([idxFix(2:end);false]) = xi_fixed;

%=== now place gqrs into bins centered on jqrs
N_J = histc(ann2,xi);

%=== repeat for the other way round
xi = [ann2' - THR;
    ann2' + THR];
xi = xi(:);
idxFix = [false;diff(xi) < 0];
xi_fixed = [xi(idxFix),xi([idxFix(2:end);false])];
xi_fixed = mean(xi_fixed,2);

xi(idxFix) = xi_fixed;
xi([idxFix(2:end);false]) = xi_fixed;
N_G = histc(ann1,xi);


% for each peak in gqrs, N_G indicates whether it has a matching peak
% in jqrs (and vice versa for N_J)
N_J = N_J(1:2:end);
N_G = N_G(1:2:end);
N_J = N_J(:);
N_G = N_G(:);

% now bin jqrs/gqrs into the SQI windows

% create windows for the SQI
xi1 = (0:opt.REG_WIN:opt.LG_REC)';
xi2 = xi1+opt.SIZE_WIND;
F1_1 = zeros(opt.N_WIN,1);
F1_2 = zeros(opt.N_WIN,1);

for w=1:numel(xi1)
    idx1 = ann1>xi1(w) & ann1<xi2(w);
    idx2 = ann2>xi1(w) & ann2<xi2(w);
    F1_1(w) = mean( N_J(idx1)==1 );
    F1_2(w) = mean( N_G(idx2)==1 );
end

% We take the minimum of these two to ensure we have a good match
F1 = min(F1_1,F1_2);
% NaN values indicate no ECG data for either lead - definitely bad quality
F1(isnan(F1)) = 0;

% Remove the non-relevant segments
idxRem = xi1 >= opt.LG_REC;
F1(idxRem) = [];
xi1(idxRem) = [];

%% Now smooth the SQI (F1)
if size(F1,1) < (opt.LG_MED*2+1)
    F1smooth = F1;
else
    F1smooth = nan(size(F1,1),2*opt.LG_MED+1);
    for k=1:opt.LG_MED
        % create a lagged version of F1
        F1smooth(:,k) = vertcat(ones(k,1),F1(1:end-k));
        
        % create a led version of F1
        F1smooth(:,k+opt.LG_MED) = vertcat(F1(k+1:end),ones(k,1));
    end
    F1smooth(:,end) = F1;
    % take the min in a window of 3 samples around the current F1 score
    F1smooth = min(F1smooth,[],2);
end
sqi = F1smooth;
tsqi = xi1;

end
function [ sqi, sqi_abp, header ] = aSQI( record_name, window_off, lead )
%BSQI Uses calcABPSQI and fills in the empty windows with the nearest
% sqi value (since calcABPSQI just finds SQI for beats).
%
% Required Parameters:
%
% record_name
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% window_offset
%       Specifies how large the window offset for calculating average
%       heart rate should be, in seconds
%
% lead
%       The index of the lead to be analyzed.
%
% Returns:
%
% sqi
%       Signal quality index calculated for each beat in a window range.
%       Number matched divided by total number of beats (gqrs number +
%       wqrs number - number matched).
sig_info = wfdbdesc(record_name);
[~, signal] = rdsamp(record_name);
samples_num = sig_info(1).LengthSamples;
[~, freq] = get_N_and_freq(record_name);
wabp(record_name,[],[],[],lead);
[wabpAnn,~,~,~,~,~] = rdann(record_name, 'wabp');
wabpAnn = wabp_fix(wabpAnn, lead, signal);
[ sqi_abp, header ] = calcABPSQI(signal(:,lead), wabpAnn, freq);

sqi_combined = sqi_abp(:,1);
windows_num = round(samples_num/(freq*window_off));
sqi_final = zeros(1,windows_num);
wabpAnn_in_windows = wabpAnn./(freq*window_off);
curr_index = 1;
next_index = 2;
for j=1:windows_num
    if curr_index < length(wabpAnn_in_windows)
        curr = wabpAnn_in_windows(curr_index);
        next = wabpAnn_in_windows(next_index);
        if abs(curr-j) > abs(next-j)
            curr_index = curr_index + 1;
            next_index = next_index + 1;
        end
    end
    sqi_final(j) = sqi_combined(curr_index);
end
sqi = sqi_final;
end
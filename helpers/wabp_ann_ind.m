function [beat_ann_time, beat_ann_arr] = wabp_ann_ind(record_name, window_size, signal_index)
%% Finds beat annotations for ABP waveforms using the wabp function.
%
% Returns two arrays, one corresponding to the time of each measurement and
% the other corresponding ot the number of annotations in a specific
% window.
%
% Required Parameters:
%
% record_name
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% window_size
%       Specifies how long the window for beat annotations is
%
% signal_index
%       Index of relevant lead
%
% Returns:
%
% beat_ann_time
%       Array corresponding to the time in seconds of each window
%       measurement
%
% beat_ann_arr
%       Array corresponding to the number of beat annotations of each window measurement

% gets some metadata of the signal
[N, freq] = get_N_and_freq(record_name);

% start index (use 1 for the whole file)
start_index = 1;

[start_time, ~] = wfdbtime(record_name,start_index);
[end_time, ~] = wfdbtime(record_name,N);

% calls wabp on the whole signal for that specific signal
wabp(record_name,start_time{1},end_time{1},0,signal_index);

% plots the signal from the start time to end time, along with ABP
% annotations. Shifts the annotations so times match correctly.
[ann,~,~,~,~,~]=rdann(record_name,'wabp');

% Ameliorate double annotations
sig_info = wfdbdesc(record_name);
abp_leads = get_abp_lead_indices(sig_info);
[tm, signal] = rdsamp(record_name);
ann = wabp_fix(ann, abp_leads(1), signal); 

% Finds annotations for the given record in each window

% calculates windowing constants
time_unit = freq;
window_size_samples = window_size * time_unit;
window_offset_samples = window_size * time_unit;
window_end = start_index + window_size_samples - 1;
% these arrays store the measurements of interest
beat_ann_arr = [];
beat_ann_time = [];
% iterates until we run out of samples
while window_end <= N
    % finds all heart rate annotations in range of the window
    in_range = ann(ann > window_end - window_size_samples & ann <= window_end);
    num_annotations = numel(in_range);
    % appends window end time and number of annotations to relevant arrays
    beat_ann_arr = [beat_ann_arr num_annotations];
    beat_ann_time = [beat_ann_time (window_end / freq)];
    % shifts the window
    window_end = window_end + window_offset_samples;
end

end
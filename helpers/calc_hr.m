function [ heart_rate_time, heart_rate_arr ] = calc_hr( record_name, ann, window_size, window_offset )
%CALC_HR Calculates average heartrates across some windows.
%
% Required Parameters:
%
% record_name
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% ann
%       Annotations in terms of samples number.
%
% window_size
%       Specifies how long the window for calculating average heart rate
%       should be, in seconds
%
% window_offset
%       Specifies how large the window offset for calculating average 
%       heart rate should be, in seconds
%
% Returns:
% 
% heart_rate_time
%       Array corresponding to the time in seconds of each window
%       measurement
% 
% heart_rate_arr
%       Array corresponding to the heart rate of each window measurement[N, freq] = get_N_and_freq(record_name);
[N, freq] = get_N_and_freq(record_name);
start_index = 1;
time_unit = freq;
window_size_samples = window_size * time_unit;
window_offset_samples = window_offset * time_unit;
% window_end = start_index + window_size_samples - 1;
window_end = 1;
% these arrays store the measurements of interest
heart_rate_arr = [];
heart_rate_time = [];
% iterates until we run out of samples
while window_end <= N
    % finds all heart rate annotations in range of the window
    in_range = ann(ann > window_end - window_size_samples & ann <= window_end);
    % calculates heart rate for the given window
    start_times = in_range(1:end-1,:);
    end_times = in_range(2:end,:);
    sec_per_beat = mean(end_times - start_times)/freq;
    heart_rate = 1/(sec_per_beat/60);
    % appends window end time and heart rate to relevant arrays
    heart_rate_arr = [heart_rate_arr heart_rate];
    heart_rate_time = [heart_rate_time (window_end / freq)];
    % shifts the window
    window_end = window_end + window_offset_samples;
end

end


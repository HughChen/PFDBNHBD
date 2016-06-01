function [ sqi ] = bSQI( record_name, window_size, window_offset, lead )
%BSQI Uses ecgsqi and sets everything up
%
% Required Parameters:
%
% record_name
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% window_size
%       Specifies how long the window for calculating average heart rate
%       should be, in seconds
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
%       sqrs number - number matched).
sig_info = wfdbdesc(record_name);
[N, freq] = get_N_and_freq(record_name);
start_index = 1;
samples_num = sig_info(lead).LengthSamples;

gqrs(record_name,N,start_index,lead);
[gqrs_ann,~,~,~,~,~] = rdann(record_name,'qrs',[]);

sqrs(record_name,N,start_index,lead);
[sqrs_ann,~,~,~,~,~] = rdann(record_name,'qrs',[]);

% wqrs(record_name,N,start_index,lead);
% [wqrs_ann,~,~,~,~,~] = rdann(record_name,'wqrs',[]);

opt = struct();
opt.THR = 0.15; % window for matching two peaks
opt.LG_MED = 3; % take the median SQI across X seconds
opt.SIZE_WIND = window_size;
%opt.REG_WIN = .5; % one window per second
opt.REG_WIN = window_offset; % one window per second
opt.HALF_WIND = opt.SIZE_WIND/2;
opt.LG_REC = samples_num/freq;  % length of the record in seconds
opt.N_WIN = round(opt.LG_REC/opt.REG_WIN); % number of windows in the signal

% [ sqi, ~ ] = ecgsqi( gqrs_ann/freq, wqrs_ann/freq, opt );
[ sqi, ~ ] = ecgsqi( gqrs_ann/freq, sqrs_ann/freq, opt );
end


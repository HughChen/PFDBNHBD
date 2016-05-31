%% Gets the sampling frequency and number of samples for a given record.
% 
% Assumes that all signals are the same duration and use the same sampling
% frequency
%
% Required Parameters:
%
% record_name
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% Returns:
% 
% N
%       Number of samples for signals in the given record
% 
% freq
%       Sampling frequency for these signals
% 
function [N, freq] = get_N_and_freq(record_name)

    sig_info=wfdbdesc(record_name);
    freq = sig_info(1).('SamplingFrequency');
    freq = double(freq);
    N = sig_info(1).('LengthSamples');

end
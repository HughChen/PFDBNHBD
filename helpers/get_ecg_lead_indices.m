function [ecg_leads] = get_ecg_lead_indices(sig_info)
% Function that gets all the ecg lead indices.
%
% Required parameters:
%
% sig_info
%       Signal info for a particular record.
%
% Returns:
%
% ecg_leads
%       Cell array of present ecg leads
possible_ecg_lead_two = ['II          '; 'ECG 2       '; 'ECG II      '; ...
    'ECG lead II '; 'ECG Lead II '; 'ECG lead 2  ';];
possible_ecg_leads = ['I           ';  'III         '; ...
    'V           '; 'ECG         '; 'ECG III     ';  ...
    'ECG lead I  '; 'ECG Lead I  '; 'ECG lead V  '; 'ECG Lead V  '; ...
    'ECG Lead III'; 'ECG lead AVL'; 'ECG Lead AVF'];
possible_ecg_leads = cellstr(possible_ecg_leads);
possible_ecg_lead_two = cellstr(possible_ecg_lead_two);
ecg_leads = [];
for i=1:numel(sig_info)
    info = sig_info(i);
    % updates index if it finds a match (also get rid of trailing and
    % leading whitespace)
    for j=1:length(possible_ecg_lead_two)
        if ~isempty(info.('Description')) && strcmp(strtrim(info.('Description')), possible_ecg_lead_two{j})
            % Prioritizes all ECG Lead 2 records the most.
            ecg_leads = [i ecg_leads];
        end
    end
    for j=1:length(possible_ecg_leads)
        if ~isempty(info.('Description')) && strcmp(strtrim(info.('Description')), possible_ecg_leads{j})
            ecg_leads = [ecg_leads i];
        end
    end
end
end
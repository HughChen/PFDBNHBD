function [abp_leads] = get_abp_lead_indices(sig_info)
% Function that gets all the abp lead indices.
%
% Required parameters:
%
% sig_info
%       Signal info for a particular record.
%
% Returns:
%
% abp_leads
%       Cell array of present abp leads
possible_abp_leads = ['PLETH     '; 'ABP       '; 'BP        '; 'ART       '; 'PAP       '; 
 'CVP       '; 'Pressure  '; 'Pressure 1'; 'Pressure 2'; 'Pressure 3'; 'Pressure 4'; 'Pressure1 '];
possible_abp_leads = cellstr(possible_abp_leads);
abp_leads = [];
for i=1:numel(sig_info)
    info = sig_info(i);
    % updates index if it finds a match (also get rid of trailing and
    % leading whitespace)
    for j=1:length(possible_abp_leads)
        if ~isempty(info.('Description')) && strcmp(strtrim(info.('Description')), possible_abp_leads{j})
            abp_leads = [abp_leads i];
        end
    end
end
end
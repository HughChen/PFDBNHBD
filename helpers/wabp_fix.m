function [ new_wabp_ann ] = wabp_fix( wabp_ann, abp_lead, signal )
%WABP_FIX Summary of this function goes here
%   Detailed explanation goes here

w_half = 5;
new_wabp_ann = [];
amplitudes = signal(wabp_ann,abp_lead);

if (std(amplitudes) > 12)
    for i = 1:numel(wabp_ann)
        lower = max(1, i-w_half);
        upper = min(numel(wabp_ann), i+w_half);
        even = amplitudes(lower+1:2:upper);
        odd = amplitudes(lower:2:upper);
        
        even_mu = mean(even);
        even_std = std(even);
        odd_mu = mean(odd);
        odd_std = std(odd);
        min_mu = min(even_mu, odd_mu);
        max_mu = max(even_mu, odd_mu);

        curr_amp = amplitudes(i);

        if ((odd_std < 5) && (even_std < 5))
            if (abs(even_mu-odd_mu) > 15)
                if (abs(curr_amp-min_mu) > abs(curr_amp-max_mu))
                    continue;
                end
            end
        end
        new_wabp_ann = [new_wabp_ann wabp_ann(i)];
    end
    new_wabp_ann = new_wabp_ann';
else
    new_wabp_ann = wabp_ann;
end

end


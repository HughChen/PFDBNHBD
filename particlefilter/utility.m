%% Comparing the annotations
ref_ann_name = 'Actual Annotation';
[ref_ann] = rdann(record_name, 'atr');
gqrs_ann_name = 'GQRS Annotation';
gqrs(record_name);
[gqrs_ann] = rdann(record_name, 'qrs');
wabp_ann_name = 'WABP Annotation';
% wabp(record_name,[],[],[],abp_leads(1));
% [wabp_ann] = rdann(record_name, 'wabp');
%pf_ann_name = 'Particle Filter ECG Results';
pf_abp_ann_name = 'DBN-PF Results';

% close all
% plot_annotations(record_name, 'ecg', ecg_leads(1), ref_ann_name, ref_ann, ...
%     gqrs_ann_name, gqrs_ann);
% 
% plot(tm,signal(:,ecg_leads(1)));hold on;grid on
% plot(tm(ref_ann),signal(ref_ann,ecg_leads(1)),'r.','MarkerSize',30)
% 
% plot(tm(gqrs_ann),signal(gqrs_ann,ecg_leads(1)),'r.','MarkerSize',30, ...
%     'MarkerEdgeColor','g')
% 
% plot(tm(wabp_ann),signal(wabp_ann,ecg_leads(1)),'r.','MarkerSize',30, ...
%     'MarkerEdgeColor','b')
% 
% title('Red:Actual, Green:GQRS, Blue:WABP');
% 
% plot(tm(abp_heart_beats),signal(abp_heart_beats,ecg_leads(1)),'r.', ...
%  'MarkerSize',30,'MarkerEdgeColor','b')

% plot_annotations(record_name, 'abp', abp_leads(1), ref_ann_name, ref_ann, ...
%     gqrs_ann_name, gqrs_ann, wabp_ann_name, wabp_ann, ...
%     pf_abp_ann_name, abp_heart_beats);

% plot_annotations(record_name, 'abp', abp_leads(1), ref_ann_name, ref_ann, ...
%     gqrs_ann_name, gqrs_ann);
plot_annotations(record_name, 'abp', abp_leads(1), wabp_ann_name, wabp_ann);

%%
set(gcf, 'PaperUnits', 'normalized')
set(gcf, 'PaperPosition', [0 0 .8 1])
% set(gcf, 'PaperPositionMode', 'auto')
% set(gcf, 'Units', 'pixels', 'Position', [10, 100, 1000, 400])
print -depsc /Users/hughchen/Desktop/2602/ECGART
%%
style = hgexport('factorystyle');
style.Color = 'gray';
hgexport(gcf,'test.eps',style);

%%
close all
plot_annotations(record_name, abp_leads(1), ref_ann_name, ref_ann, ...
    gqrs_ann_name, gqrs_ann, wabp_ann_name, wabp_ann, ...
    pf_abp_ann_name, abp_heart_beats);
% savefig(['/Users/hughchen/Desktop/' file_num '-AllAnnOnECG']);
%% Plot where we do well - Plotting abp_heart_beats
ann1 = ref_ann;
% ann2 = gqrs_ann;
% ann2 = wabp_ann;
ann2 = abp_heart_beats;

threshold = .15*freq;
xi = [ann1' - threshold;
    ann1' + threshold];
xi = xi(:);

idxFix = [false;diff(xi) < 0];
xi_fixed = [xi(idxFix),xi([idxFix(2:end);false])];
xi_fixed = mean(xi_fixed,2);

xi(idxFix) = xi_fixed;
xi([idxFix(2:end);false]) = xi_fixed;

N_ann = histc(ann2,xi);

xi = [ann2' - threshold;
    ann2' + threshold];
xi = xi(:);
idxFix = [false;diff(xi) < 0];
xi_fixed = [xi(idxFix),xi([idxFix(2:end);false])];
xi_fixed = mean(xi_fixed,2);

xi(idxFix) = xi_fixed;
xi([idxFix(2:end);false]) = xi_fixed;
N_pf = histc(ann1,xi);

N_ann = N_ann(1:2:end);
N_pf = N_pf(1:2:end);
N_ann = N_ann(:);
N_pf = N_pf(:);

true_pos = false(1,num);
for j=1:length(N_pf)
    index = ann2(j);
    if N_pf(j) == 1
        true_pos(index) = true;
    end
end

false_pos = false(1,num);
for j=1:length(N_pf)
    index = ann2(j);
    if N_pf(j)==0
        false_pos(index) = true;
    end
end

missed_actual = false(1,num);
for j=1:length(N_ann)
    index = ann1(j);
    if N_ann(j)==0
        missed_actual(index) = true;
    end
end

test_sens = sum(N_ann>0)/length(N_ann);
test_pp = sum(N_pf==1)/length(N_pf);
fprintf([num2str(test_sens) '\n'])
fprintf([num2str(test_pp) '\n'])

%% Generate total plot for ABP
lead = abp_leads(1);
close all
plot(tm,signal(:,lead));hold on;grid on
plot(tm(true_pos),signal(true_pos,lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','g', ...
    'Marker','square')
plot(tm(missed_actual),signal(missed_actual,lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','y', ...
    'Marker','diamond')
plot(tm(false_pos),signal(false_pos,lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','r', ...
    'Marker','o')
title('Overall Performance against ABP','fontsize',24);
xlabel('Time (in seconds)','fontsize',21);
ylabel('Pressure (in mmHg)','fontsize',14);
set(gca,'FontSize',18)
% savefig(['/Users/hughchen/Desktop/' file_num '-AnnOnABP']);
%% Generate total plot for ECG
lead = ecg_leads(1);
close all
plot(tm,signal(:,lead));hold on;grid on
p1 = plot(tm(true_pos),signal(true_pos,lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','g', ...
    'Marker','square');
p2 = plot(tm(missed_actual),signal(missed_actual,lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','y', ...
    'Marker','diamond');
p3 = plot(tm(false_pos),signal(false_pos,lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','r', ...
    'Marker','o');
h = legend([p1, p2, p3], 'True Pos', 'Missed Ann', 'False Pos');
title('PF Overall Performance against ECG','fontsize',24);
xlabel('Time (in seconds)','fontsize',21);
ylabel('Voltage (in mV)','fontsize',14);
set(gca,'FontSize',18)
% savefig(['/Users/hughchen/Desktop/' file_num '-AnnOnECG']);
%% Plot HR
close all
TrueHRStats = statistics(1,:);
[~, actual_hr] = calc_hr(record_name, ref_ann, 10, window);
[~, gqrs_hr] = calc_hr(record_name, gqrs_ann, 5, window);
[~, wabp_hr] = calc_hr(record_name, wabp_ann, 5, window);
x = [1:numel(actual_hr)];
p1 = plot(x*window, TrueHRStats, 'b', 'LineWidth', 2);hold on;
p2 = plot(x*window, actual_hr, 'g', 'LineWidth', 2);
p3 = plot(x*window, gqrs_hr, 'm', 'LineWidth', 2);
% axis([0 600 0 260])
% p4 = plot(x*window, wabp_hr, 'm', 'LineWidth', 2);
h = legend([p1, p2, p3], 'TrueHR', 'ActualHR', 'GQRSHR');
set(h,'Location','northwest')
% legend([p1, p2, p3, p4], 'TrueHR', 'ActualHR', 'GQRSHR', 'WABPHR')
% plot(wabp_hr, 'm');
title('Heart Rate Plot','fontsize',24);
xlabel('Time (in seconds)','fontsize',21);
ylabel('Heart Rate (in bpm)','fontsize',21);
set(gca,'FontSize',18)
%% Plot Latency
close all
ecgart = statistics(2,:);
x = [1:numel(ecgart)];
plot(x*window, ecgart);hold on;
title('ECGART');
% savefig(['/Users/hughchen/Desktop/' file_num '-HR']);
%% Compare the ecg peaks against the abp peaks
h1=subplot(2,1,1);
plot(1:T,statistics(3,:));
title('ECG Peaks');
h2=subplot(2,1,2);
plot(1:T,statistics(6,:));
linkaxes([h1,h2],'x');
title('ABP Peaks');
% savefig(['/Users/hughchen/Desktop/' file_num '-PeakComparison']);
%% Plot ECG SQI
[tm, signal] = rdsamp(record_name);
ecg_lead = ecg_leads(1);
samples_num = sig_info(ecg_lead).LengthSamples;

sqi_yes = false(1,samples_num);
sqi_maybe_yes = false(1,samples_num);
sqi_maybe_no = false(1,samples_num);
sqi_no = false(1,samples_num);
for j=1:length(ecg_sqi)
    index = round((j-1)*samples_num/length(ecg_sqi)) + 1;
    if ecg_sqi(j)>.8
        sqi_yes(index) = true;
    elseif .8>=ecg_sqi(j) && ecg_sqi(j)>.5
        sqi_maybe_yes(index) = true;
    elseif .5>=ecg_sqi(j) && ecg_sqi(j)>.2
        sqi_maybe_no(index) = true;
    else
        sqi_no(index) = true;
    end
end

close all
plot(tm,signal(:,ecg_lead));hold on;grid on

p1 = plot(tm(sqi_yes),signal(sqi_yes,ecg_lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','g', ...
    'Marker','square');
p2 = plot(tm(sqi_maybe_yes),signal(sqi_maybe_yes,ecg_lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','y', ...
    'Marker','diamond');
plot(tm(sqi_maybe_no),signal(sqi_maybe_no,ecg_lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','y', ...
    'Marker','diamond')
p3 = plot(tm(sqi_no),signal(sqi_no,ecg_lead),'r.', ...
    'MarkerSize',10, 'MarkerEdgeColor','r', ...
    'Marker','o');
h = legend([p1, p2, p3], 'SQI >= .8', '.2 < SQI < .8', 'SQI <= .2');
set(h,'Location','northwest')
axis([0 600 -2 4.2])

title('ECGSQI','fontsize',24);
xlabel('Time (in seconds)','fontsize',21);
ylabel('ECGSQI (no units)','fontsize',21);
set(gca,'FontSize',18)
% savefig(['/Users/hughchen/Desktop/' file_num '-ECGSQI']);
%% Plot ABP SQI
[tm, signal] = rdsamp(record_name);

abp_lead = abp_leads(1);
samples_num = sig_info(abp_lead).LengthSamples;
close all
sqi_abp_yes = false(1,samples_num);
sqi_abp_no = false(1,samples_num);
for j=1:length(abp_sqi)
    index = round((j-1)*samples_num/length(abp_sqi)) + 1;
    if abp_sqi(j) == 1
        sqi_abp_yes(index) = true;
    else
        sqi_abp_no(index) = true;
    end
end
plot(tm,signal(:,abp_lead));hold on;grid on
plot(tm(sqi_abp_yes),signal(sqi_abp_yes,abp_lead),'r.', ...
    'MarkerSize',4, 'MarkerEdgeColor','g')
plot(tm(sqi_abp_no),signal(sqi_abp_no,abp_lead),'r.', ...
    'MarkerSize',4, 'MarkerEdgeColor','r')
title('ABPSQI');
% savefig(['/Users/hughchen/Desktop/' file_num '-ABPSQI']);
%% 
h1=subplot(2,1,1);
plot(tm,signal(:,ecg_leads(1)));
title('ECG','fontsize',18);
xlabel('Time (in sec)','fontsize',14);
ylabel('Voltage (in mV)','fontsize',14);
set(gca,'FontSize',12)
h2=subplot(2,1,2);
plot(tm,signal(:,abp_leads(1)));
linkaxes([h1,h2],'x');
title('ABP','fontsize',18);
xlabel('Time (in seconds)','fontsize',14);
ylabel('Pressure (in mmHg)','fontsize',14);
set(gca,'FontSize',12)
%% Plot ECGART
art = tsmovavg(statistics(2,:),'s',500);
x = [1:numel(art)];
plot(x*window, art)
title('ECGART','fontsize',24);
xlabel('Time (in seconds)','fontsize',21);
ylabel('ECGART Avg (no units)','fontsize',21);
set(gca,'FontSize',18)
%%
x = [0:.1:200];
y = prob_function(x, 60*ones(1,numel(x)), .025);
plot(x,y)
title('Probability Function','fontsize',24);
xlabel('P (from 0 to 1)','fontsize',21);
ylabel('Difference (in windows)','fontsize',21);
set(gca,'FontSize',18)
%% Testing 
clear; close all; clc;
curr_path = pwd;
split_path = strsplit(curr_path, '/physionet');
path_prefix = split_path{1};
file_num = '1033';
record_name = strcat(path_prefix, ...
    '/physionet/data/extended_training_2014/', ...
    file_num);
[num, freq] = get_N_and_freq(record_name);
sig_info = wfdbdesc(record_name);
window = 0.025;
beat_threshold = .12;
[tm, signal] = rdsamp(record_name);
abp_leads = get_abp_lead_indices(sig_info);
ref_ann_name = 'Actual Annotation';
[ref_ann] = rdann(record_name, 'atr');

wabp_ann_name = 'WABP Annotation';
new_wabp_ann_name = 'New WABP Annotation';
[~,WABP] = wabp_ann_ind(record_name,window,abp_leads(1));
wabp(record_name,[],[],[],abp_leads(1));
[wabp_ann] = rdann(record_name, 'wabp');
new_wabp_ann = wabp_fix(wabp_ann, abp_leads(1), signal); 
%%
amplitudes = signal(wabp_ann,abp_leads(1));

%
w_half = 5;
new_wabp_ann = [];

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
%%
plot_annotations(record_name, 'abp', abp_leads(1), ref_ann_name, ref_ann, ...
    new_wabp_ann_name, new_wabp_ann, wabp_ann_name, wabp_ann);

%%

temp = (jqrs_mod(signal(:,ecg_leads(1)),0.250,0.6,freq,[],0))';
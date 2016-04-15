clc; clear all; close all;
restoredefaultpath
curr_path = pwd;
split_path = strsplit(curr_path, '/particlefilter');
path_prefix = split_path{1};
addpath(strcat(path_prefix, '/data'), '../wfdb-app-toolbox-0-9-9/mcode');
addpath(strcat(path_prefix, '/alistairewj-425/sources'));

savepath
file_num = '2602';
record_name = strcat(path_prefix, '/data/setp2/', file_num);

% Initialize
% Index 1 -> ecg, index 2 -> abp, 3 -> ecg_backup, 4 -> abp_backup
tic
indices = [0,0,0,0];
[num, freq] = get_N_and_freq(record_name);
sig_info = wfdbdesc(record_name);
window = 0.025;
beat_threshold = .12;
[tm, signal] = rdsamp(record_name);

ecg_leads = get_ecg_lead_indices(sig_info);
if numel(ecg_leads) > 0
    try
        indices(1) = 1;
        [~,GQRS] = ecg_ann_ind(record_name,window,ecg_leads(1));
        gqrs(record_name, [], [], ecg_leads(1));
        [gqrs_ann] = rdann(record_name, 'qrs');
        [~, gqrs_hr] = calc_hr(record_name, gqrs_ann, 5, window);
        [ecg_sqi] = bSQI(record_name,10,window,ecg_leads(1));
        average_hr = nanmean(gqrs_hr);
    catch E
        indices(1) = 0;
        GQRS = [];
        gqrs_hr = [];
        ecg_sqi = [];
    end    
else
    GQRS = [];
    gqrs_hr = [];
    ecg_sqi = [];
end

if numel(ecg_leads) == 2
    try
        indices(3) = 1;
        [~,GQRS_backup] = ecg_ann_ind(record_name,window,ecg_leads(2));
        gqrs(record_name, [], [], ecg_leads(2));
        [gqrs_ann_backup] = rdann(record_name, 'qrs');
        [~, gqrs_hr_backup] = calc_hr(record_name, gqrs_ann_backup, 5, window);
        [ecg_sqi_backup] = bSQI(record_name,10,window,ecg_leads(2));
        if (sum(ecg_sqi) < sum(ecg_sqi_backup))
            average_hr = nanmean(gqrs_hr_backup);
        end
    catch E
        indices(3) = 0;
        GQRS_backup = [];
        gqrs_hr_backup = [];
        ecg_sqi_backup = [];
    end
else
    GQRS_backup = [];
    gqrs_hr_backup = [];
    ecg_sqi_backup = [];
end
T = length(GQRS);

abp_leads = get_abp_lead_indices(sig_info);
if numel(abp_leads) > 0 
    try
        indices(2) = 1;
        [~,WABP] = wabp_ann_ind(record_name,window,abp_leads(1));
        wabp(record_name,[],[],[],abp_leads(1));
        [wabp_ann] = rdann(record_name, 'wabp');
        wabp_ann = wabp_fix(wabp_ann, abp_leads(1), signal); 
        [~, wabp_hr] = calc_hr(record_name, wabp_ann, 5, window);
        [abp_sqi] = aSQI(record_name, window,abp_leads(1));
        for i=1:numel(abp_sqi)
            index = round(i*window*freq);
            abp_signal = signal(:, abp_leads(1));
            if index < numel(abp_signal) && abp_signal(index) < 0
                abp_sqi(i) = 0;
            end
        end
        if numel(ecg_leads) == 0
            average_hr = nanmean(wabp_hr);
            T = length(WABP);
        end
    catch E
        indices(2) = 0;
        WABP = [];
        wabp_hr = [];
        abp_sqi = [];
    end    
else
    WABP = [];
    wabp_hr = [];
    abp_sqi = [];
end    

if numel(abp_leads) == 2
    try
        indices(4) = 1;
        [~,WABP_backup] = wabp_ann_ind(record_name,window,abp_leads(2));
        wabp(record_name,[],[],[],abp_leads(2));
        [wabp_ann_backup] = rdann(record_name, 'wabp');
        [~, wabp_hr_backup] = calc_hr(record_name, wabp_ann_backup, 5, window);
        [abp_sqi_backup] = aSQI(record_name, window,abp_leads(2));
    catch E
        indices(2) = 0;
        WABP_backup = [];
        wabp_hr_backup = [];
        abp_sqi_backup = [];
    end
else
    WABP_backup = [];
    wabp_hr_backup = [];
    abp_sqi_backup = [];
end
% Particle Filter
t=1;
N = 2000;
states = prior(N,window,average_hr);

w = observe(GQRS,WABP,gqrs_hr,wabp_hr,ecg_sqi,abp_sqi,states,t,window,indices);
ind = randp(w,1,N);
states = states(:,ind);
% return statistics
statistics = zeros(10, T);
average = mean(states, 2);
statistics(1:9, t) = average;
statistics(10,t) = std(states(1,:));
% Propagate-Weight-Resample
for t=2:T;
    % propagate
    states = probs(states,t,window);
    % weight
    w = observe(GQRS,WABP,gqrs_hr,wabp_hr,ecg_sqi,abp_sqi,states,t,window,indices);
    % resample
    ind = randp(w,1,N);
    states = states(:,ind);
    % return statistics
    average = mean(states, 2);
    statistics(1:9, t) = average;
    statistics(10,t) = std(states(1,:));
end
toc
% Annotating the peaks
ArtifactStats = statistics(2,:);
ActualPeak = statistics(3,:);
ABPPeak = statistics(6,:);
[tm, signal] = rdsamp(record_name);

actual_heart_beats = [];
abp_heart_beats = [];
for t = 1:T
    if ActualPeak(t) > beat_threshold
        annotation_sample = round(t*window*freq + window*freq/2);
        annotation_time = t*window;
        actual_heart_beats = [actual_heart_beats annotation_sample];
    end
    if ABPPeak(t) > beat_threshold
        delay = round(statistics(8,t)*window*freq);
        annotation_sample = round(t*window*freq + window*freq/2 - delay);
        abp_heart_beats = [abp_heart_beats annotation_sample];
    end
end
actual_heart_beats = transpose(actual_heart_beats);
abp_heart_beats = transpose(abp_heart_beats);
temp_heart_beats = abp_heart_beats;
for j=1:numel(abp_heart_beats)
    if abp_heart_beats(j) < 0
        temp_heart_beats = temp_heart_beats(2:end);
    end
end
abp_heart_beats = temp_heart_beats;
% Slight post processing
latency = states(8,:);
last_latency = latency(end);
max_size = sig_info.LengthSamples;
if (gqrs_ann(end)+last_latency*freq*window > max_size)
    abp_heart_beats = [abp_heart_beats ; gqrs_ann(end)];
end
% Generates the pf annotation file and check it against the actual.
start_time = wfdbtime(record_name, 1);

[ref_ann] = rdann(record_name, 'atr');
report_file = [record_name 'report.txt'];

% Checks accuracy for abp heart beats
wrann(record_name,'qrs',abp_heart_beats);
if exist(report_file, 'file') == 2
    delete(report_file);
end
begin_time = wfdbtime(record_name,1);
report = bxb(record_name,'atr','qrs',report_file,begin_time{1});

data = report.data;
QTP = sum(sum(data(1:5,1:5)));
QFN = sum(sum(data(1:5,6:7)));
QFP = sum(sum(data(6:7,1:5)));
PF_ABP_sens = QTP/(QTP + QFN);
PF_ABP_pos_pred = QTP/(QTP + QFP);

if numel(ecg_leads) > 0
    % Generates the gqrs annotation file and check it against the actual.
    gqrs(record_name);
    if exist(report_file, 'file') == 2
        delete(report_file);
    end
    report = bxb(record_name, 'atr', 'qrs', report_file, begin_time{1});

    data = report.data;
    QTP = sum(sum(data(1:5,1:5)));
    QFN = sum(sum(data(1:5,6:7)));
    QFP = sum(sum(data(6:7,1:5)));
    GQRS_QRS_sens = QTP/(QTP + QFN);
    GQRS_QRS_pos_pred = QTP/(QTP + QFP);
else
    gqrs_ann = [];
    GQRS_QRS_sens = 0;
    GQRS_QRS_pos_pred = 0;
end
    
% Generates the wabp annotation file and check it against the actual.
if numel(abp_leads) > 0
    wabp(record_name,[],[],[],abp_leads(1));
    if exist(report_file, 'file') == 2
        delete(report_file);
    end
    report = bxb(record_name, 'atr', 'wabp', report_file, begin_time{1});

    data = report.data;
    QTP = sum(sum(data(1:5,1:5)));
    QFN = sum(sum(data(1:5,6:7)));
    QFP = sum(sum(data(6:7,1:5)));
    WABP_QRS_sens = QTP/(QTP + QFN);
    WABP_QRS_pos_pred = QTP/(QTP + QFP);
else
    wabp_ann = [];
    WABP_QRS_sens = 0;
    WABP_QRS_pos_pred = 0;
end

% Print the number of annotations
fprintf('Actual Annotation Number: %d; GQRS Annotation Number: %d; \n', ...
    length(ref_ann), length(gqrs_ann))
fprintf('PF Annotation Number: %d; PF_ABP Annotation Number: %d \n', ...
    length(actual_heart_beats), length(abp_heart_beats))
fprintf('PF_ABP pos pred: %g; PF_ABP sens: %g \n', PF_ABP_pos_pred, PF_ABP_sens)
fprintf('GQRS pos pred: %g; GQRS sens: %g \n ', GQRS_QRS_pos_pred, GQRS_QRS_sens)
fprintf('WABP pos pred: %g; WABP sens: %g \n ', WABP_QRS_pos_pred, WABP_QRS_sens)
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
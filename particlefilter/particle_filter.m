clc; clear all; close all;
restoredefaultpath
curr_path = pwd;
split_path = strsplit(curr_path, '/particlefilter');
path_prefix = split_path{1};
addpath(strcat(path_prefix, '/helpers'), '../wfdb-app-toolbox-0-9-9/mcode');
addpath(strcat(path_prefix, '/alistairewj_sqi/sources'));

savepath
file_num = '2602';
record_name = strcat(path_prefix, '/data/setp2/', file_num);

% Initialize
% Index 1 -> ecg, index 2 -> abp
tic
indices = [0,0];
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
        fprintf('Error with gqrs\n');
    end    
else
    GQRS = [];
    gqrs_hr = [];
    ecg_sqi = [];
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
        if numel(ecg_leads) == 0 || exist('average_hr', 'var') ~= 1
            % Uses the average_hr from WABP if there's no available ECG
            % information
            average_hr = nanmean(wabp_hr);
            T = length(WABP);
        end
    catch E
        indices(2) = 0;
        WABP = [];
        wabp_hr = [];
        abp_sqi = [];
        fprintf('Error with wabp\n');
    end    
else
    WABP = [];
    wabp_hr = [];
    abp_sqi = [];
end    

% Particle Filter
t=1;
N = 2000;
states = prior(N,window,average_hr);
w = observe(GQRS,WABP,gqrs_hr,wabp_hr,ecg_sqi,abp_sqi,states,t,window,indices);
ind = randp(w,1,N);
states = states(:,ind);
% Calculate some relevant statistics
statistics = zeros(10, T);
average = mean(states, 2);
statistics(1:9, t) = average;
statistics(10,t) = std(states(1,:));
% Propagate-Weight-Resample
for t=2:T;
    % propagate
    states = propagation(states,t,window);
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
% Removes any negative time values for heart beats
for j=1:numel(abp_heart_beats)
    if abp_heart_beats(j) < 0
        temp_heart_beats = temp_heart_beats(2:end);
    end
end
abp_heart_beats = temp_heart_beats;
% Slight post processing to add last beat if WABP failed to annotate it
latency = states(8,:);
last_latency = latency(end);
max_size = sig_info.LengthSamples;
if exist('gqrs_ann', 'var') == 1
    if (gqrs_ann(end)+last_latency*freq*window > max_size)
        abp_heart_beats = [abp_heart_beats ; gqrs_ann(end)];
    end
end
% Generates the pf annotation file and check it against the actual.
start_time = wfdbtime(record_name, 1);

% Reads reference annotations. Other datasets might have different
% extensions. Make sure to change the extension for rdann and bxb if
% necessary
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

if numel(ecg_leads) > 0 && exist('gqrs_ann', 'var') == 1
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
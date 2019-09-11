clc;
clear;
close all;

PATH_TO_FUNCTIONS = 'YOUR_PATH';
PATH_TO_CLIPS = 'YOUR_PATH';

addpath(PATH_TO_FUNCTIONS);
cd (PATH_TO_CLIPS);

SAMPLE_RATE = 96000;
FRAME_SIZE = 0.5;
CLIP_SIZE = 10;

% Pick your audio clips to be filtered
name_audio = {'Human_combo';'Mechanical_combo';'Music_combo';'Nature_combo'};
name_algo = {'No Algorithm';'Boll';'Berouti';'Kamath'};

path_mic = 'mic.wav';
[y_mic,Fs_mic] = audioread(path_mic);

y_mic = y_mic(:,1);
t_mic = (1:size(y_mic))/Fs_mic;

y_mic = resample(y_mic,SAMPLE_RATE,Fs_mic);

accuracy = zeros(length(name_algo),CLIP_SIZE);
accuracy_average = zeros(length(name_algo),length(name_audio));
quality = zeros(length(name_algo),CLIP_SIZE);
quality_average = zeros(length(name_algo),length(name_audio));
algorithm_signals = cell(length(name_algo),CLIP_SIZE);
algorithm_noise = cell(length(name_algo),CLIP_SIZE);

for i = 1:length(name_audio)
    disp(name_audio{i});
    path_source = strcat(name_audio{i},'.wav');
    [y_source,Fs_source] = audioread(path_source);
    
    % Only take real values
    y_source = y_source(:,1);

    % Resample to SAMPLE_RATE
    y_source = resample(y_source,SAMPLE_RATE,Fs_source);
    Fs_source = SAMPLE_RATE;

    y_source = y_source(:,1);
    t_source = (1:size(y_source))/Fs_source;
    y_source_envelope = envelope(y_source, 150, 'peak');

    % Find the start of the recording
    mic_delay = finddelay(y_source, y_mic);

    % Adjust the time frame to make it line up
    y_mic_clip = y_mic(mic_delay+1:mic_delay + SAMPLE_RATE*40);
    
    % Loop through all slices in each clip (10)
    for j = 1:CLIP_SIZE
        y_mic_slice = y_mic_clip((j-1)*SAMPLE_RATE+1:(j+3)*SAMPLE_RATE);
        
        % Put lowest noise part at the beginning
        power_min = inf;

        % Find the FRAME_SIZE s clip at which the power is the lowest
        step = SAMPLE_RATE*FRAME_SIZE;
        for k = 1:floor((length(y_mic_slice)/SAMPLE_RATE) / FRAME_SIZE)-1
            power_signal = mean(abs(y_mic_slice(k*step:(k+1)*step)).^2);
            if power_signal < power_min
                power_min = power_signal;
                power_min_index = k;
            end
        end

        clip_start = power_min_index*step;
        clip_end = (power_min_index + 1)*step;

        power_min = y_mic_slice(clip_start:clip_end);

        y_mic_slice(clip_start:clip_end) = [];

        y_mic_slice = [power_min; y_mic_slice];


        % No algorithm first
        algorithm_signals{1}{j} = y_mic_slice;
        algorithm_signals{2}{j} = SSBoll79(y_mic_slice, SAMPLE_RATE);
        algorithm_signals{3}{j} = SSBerouti79(y_mic_slice, SAMPLE_RATE);
        algorithm_signals{4}{j} = SSMultibandKamath02(y_mic_slice, SAMPLE_RATE);

        for k = 1:length(name_algo)
            algorithm_noise{k}{j} = mean(algorithm_signals{k}{j}(round(SAMPLE_RATE*0.1):round(SAMPLE_RATE*0.5)).^2);

            % Reconstruct the signal (put the first part back where it belongs)
            algorithm_signals{k}{j} = [
                                        algorithm_signals{k}{j}(step:min(step+clip_start,end));
                                        algorithm_signals{k}{j}(1:step);
                                        algorithm_signals{k}{j}(step+clip_start:end)
                                       ];

            subplot(length(name_algo),1,k);

            % Coherence
            y_source_slice = y_source((j-1)*SAMPLE_RATE+1:(j-1)*SAMPLE_RATE+length(algorithm_signals{k}{j}));
            
            [coherence, f] = mscohere(algorithm_signals{k}{j}, y_source_slice, [], [], [], SAMPLE_RATE);
            coherence_envelope = envelope(coherence, 100, 'peak');

            accuracy(k,j) = mean(coherence_envelope);

            power_signal = mean(algorithm_signals{k}{j}.^2);

            power_signal = power_signal - algorithm_noise{k}{j};

            quality(k,j) = power_signal/algorithm_noise{k}{j};
            quality(k,j) = 10*log(quality(k,j));
        end
    end

    colours = [[0 0.4470 0.7410];
               [0.8500 0.3250 0.0980];
               [0.9290 0.6940 0.1250];
               [0.4660 0.6740 0.1880]];

    % Plot each category
    subplot(length(name_audio),1,i);

    plot(t_source,y_mic_clip);
    hold on
    plot(t_source,y_source_envelope);
    hold off
    set(gca, 'YLim',[-1 1]);
    set(gca, 'XLim',[0 20]);
    title(strrep(name_audio{i}, '_', ' '));

    for j = 1:length(name_algo)
        accuracy_average(j,i) = mean(accuracy(j,1:10));
        quality_average(j,i) = mean(quality(j,1:10));
    end
    t = table(name_algo,accuracy_average(:,i),quality_average(:,i));
    t.Properties.VariableNames = {'Algorithm','Accuracy','SNR'};
    disp(t)
end

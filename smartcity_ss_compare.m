clc;
clear;
close all;

cd 'C:/Users/Evan/Dropbox/Matlab'
addpath('functions/');

SAMPLE_RATE = 44100;

% Pick your audio clips that were filtered
name_audio = {'Human9';'Mechanical1';'Music17';'Nature1'};
name_algo = {'No Algorithm';'Boll';'Berouti';'Kamath'};
accuracy = length(name_algo);
quality= length(name_algo);
algorithm_signals = cell(4,1);
algorithm_noise = cell(4,1);

for k = 1:length(name_audio)
    figure;
    disp(name_audio{k});
    path_source = strcat(name_audio{k},'.wav');
    [y_source,Fs_source] = audioread(path_source);
    
    % Only take real values
    y_source = y_source(:,1);

    % Resample to 44100
    y_source = resample(y_source,SAMPLE_RATE,Fs_source);
    Fs_source = SAMPLE_RATE;

    path_mic = 'all_noise_most.wav';
    [y_mic,Fs_mic] = audioread(path_mic);

    y_source = y_source(:,1);
    t_source = (1:size(y_source))/Fs_source;
    y_source_envelope = envelope(y_source, 100, 'peak');

    y_mic = y_mic(:,1);
    t_mic = (1:size(y_mic))/Fs_mic;

    % No algorithm
    algorithm_signals{1} = y_mic;

    algorithm_signals{2} = SSBoll79(y_mic, Fs_mic);

    algorithm_signals{3} = SSBerouti79(y_mic, Fs_mic);

    algorithm_signals{4} = SSMultibandKamath02(y_mic, Fs_mic);

    % Find the start of the recording
    mic_delay = finddelay(y_source, y_mic);
    if (contains(name_audio{k},"Mech"))
        mic_delay = mic_delay - 9500;
    end

    for i = 1:4
        algorithm_noise{i} = mean(algorithm_signals{i}(round(SAMPLE_RATE*0.1):round(SAMPLE_RATE*0.5)).^2);
        
        % Adjust the time frame to make it line up
        algorithm_signals{i} = algorithm_signals{i}(mic_delay+1:mic_delay + SAMPLE_RATE*4);
        
        if (contains(name_audio{k},"Human") || contains(name_audio{k},"Mech"))
            algorithm_signals{i} = algorithm_signals{i}(1:SAMPLE_RATE*3.5);
        end
    end

    colours = [[0 0.4470 0.7410];
               [0.8500 0.3250 0.0980];
               [0.9290 0.6940 0.1250];
               [0.4660 0.6740 0.1880]];

    % Plot each algorithm
    for i = 1:length(name_algo)
        % Uncomment to play each clip before and after algorithm
%         player = audioplayer(algorithm_signals{i},Fs_source);
%         player.play;
%         pause(4);

        subplot(length(name_algo),1,i);

        plot(t_source(1:length(algorithm_signals{i})),algorithm_signals{i});
        hold on
        plot(t_source,y_source_envelope);
        hold off
        set(gca, 'YLim',[-1 1]);
        set(gca, 'XLim',[0 3.5]);
    end

    % Coherence
    for i = 1:length(name_algo)
        subplot(length(name_algo),1,i);

        [coherence, f] = mscohere(algorithm_signals{i}, y_source(1:length(algorithm_signals{i})), [], [], [], SAMPLE_RATE);
        coherence_envelope = envelope(coherence, 100, 'peak');

        accuracy(i) = mean(coherence_envelope);

        power_signal = mean(algorithm_signals{i}.^2);
       
        power_signal = power_signal - algorithm_noise{i};

        quality(i) = power_signal/algorithm_noise{i};
        quality(i) = 10*log(quality(i));
    end

    t = table(name_algo,accuracy',quality');
    t.Properties.VariableNames = {'Algorithm','Accuracy','SNR'};
    disp(t)
end
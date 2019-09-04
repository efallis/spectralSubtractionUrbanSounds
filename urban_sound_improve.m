clc;
clear;
close all;

PATH_TO_FUNCTIONS = 'C:/Users/Evan/Dropbox/Matlab/functions/';
PATH_TO_CLIPS = 'C:/Users/Evan/Documents/UrbanSound8K';

% addpath('C:/Users/Evan/Dropbox/Matlab/functions/');
% cd 'C:/Users/Evan/Documents/UrbanSound8K'

addpath(PATH_TO_FUNCTIONS);
cd (PATH_TO_CLIPS)

SAMPLE_RATE = 96000;
FRAME_SIZE = 0.5;

% Uncomment to pick the algorithm to filter the data
name_algo = 'boll';
%name_algo = 'berouti';
%name_algo = 'kamath';
%name_algo = 'none';

folder_source = 'fold8';
folder_dest = strcat(folder_source,'_',name_algo,'/');

% Check if directory exists, create if not
if exist(folder_dest, 'dir') == 0
    mkdir(folder_dest);
end

audio_files = dir(strcat(folder_source,'/*.wav'));

for file = audio_files'
    disp(file)

    [y_source,Fs_source] = audioread(strcat(folder_source,'/',file.name));
    y_source = y_source(:,1);   % Only take real values

    Fs_old = Fs_source;
    
    snr_source = snr(y_source,Fs_source);
    
    % Resample to SAMPLE_RATE
    y_source = resample(y_source,SAMPLE_RATE,Fs_source);
    Fs_source = SAMPLE_RATE;
    
    power_signal_old = mean(abs(y_source));
    
    if(file.bytes > 64000 && length(y_source)/Fs_source >= 3)
        power_min = inf;
        
        % Find the FRAME_SIZE s clip at which the power is the lowest
        % Chunks of FRAME_SIZE s
        for i = 1:floor((length(y_source)/Fs_source) / FRAME_SIZE)-1
            power_signal = mean(abs(y_source(i*FRAME_SIZE*Fs_source:(i+1)*FRAME_SIZE*Fs_source)));
            if power_signal < power_min
                power_min = power_signal;
                power_min_index = i;
            end
        end
        
        clip_start = power_min_index*FRAME_SIZE*Fs_source;
        clip_end = (power_min_index + 1)*FRAME_SIZE*Fs_source;
        
        power_min = y_source(clip_start:clip_end);
        
        y_source(clip_start:clip_end) = [];
        
        y_source = [power_min; y_source];
        
        if (strcmp(name_algo,'boll'))
            algorithm_signal = SSBoll79(y_source, Fs_source, FRAME_SIZE);
        elseif (strcmp(name_algo,'berouti'))
            algorithm_signal = SSBerouti79(y_source, Fs_source, FRAME_SIZE);
        elseif (strcmp(name_algo,'kamath'))
            algorithm_signal = SSMultibandKamath02(y_source, Fs_source, FRAME_SIZE);
        elseif (strcmp(name_algo,'none'))
            algorithm_signal = y_source;
        else
            print "Algorithm not recognized"
            return
        end
        
        algorithm_signal = (mean(abs(y_source))/mean(abs(algorithm_signal))) * y_source;
        algorithm_signal = algorithm_signal*2;
    else
        disp('Ignore');
        algorithm_signal = y_source;
    end
    
    audiowrite(strcat(folder_dest,file.name),algorithm_signal,Fs_source);
end

disp(strcat(folder_source,', ',name_algo));

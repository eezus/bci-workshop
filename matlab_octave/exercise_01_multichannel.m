% BCI workshop 2015
% Exercise 1: A neurofeedback interface (multi-channel)
% 
% Description:
% In this exercise, we'll try and play around with a simple interface that
% receives EEG from one electrode, computes standard frequency band powers 
% and displays both the raw signals and the features.
% 

clear;
close all;

addpath(genpath('bci_workshop_tools\'));
global stop_loop
stop_loop = false;

% MuLES connection parameters    
mules_ip = '127.0.0.1';
mules_port = 30000;

% Creates a mules_client
mules_client = MulesClient(mules_ip, mules_port);
params = mules_client.getparams();

%% Set the experiment parameters
    
eeg_buffer_secs = 15;  % Size of the EEG data buffer used for plotting the 
                       % signal (in seconds) 
win_test_secs = 1;     % Length of the window used for computing the features 
                       % (in seconds)
overlap_secs = 0.5;    % Overlap between two consecutive windows (in seconds)
shift_secs = win_test_secs - overlap_secs;
index_channel = 1;     % Index of the channnel to be used (with the Muse, we 
                       % can choose from 0 to 3)


name_of_channels   = params{6};
sampling_frequency = params{3};

% Get name of features
names_of_features = feature_names(name_of_channels);

%% Initialize the buffers for storing raw EEG and features

% Initialize raw EEG data buffer (for plotting)
eeg_buffer = zeros(sampling_frequency * eeg_buffer_secs , numel(name_of_channels)); 

% Compute the number of windows in "eeg_buffer_secs" (used for plotting)
n_win_test = floor((eeg_buffer_secs - win_test_secs) / shift_secs) + 1;

% Initialize the feature data buffer (for plotting)
feat_buffer = zeros(n_win_test , numel(names_of_features));

% Initialize the plots
h_eeg_fig = figure('CloseRequestFcn',@fig_closereq);
h_eeg_ax = axes();
h_featt_fig = figure('CloseRequestFcn',@fig_closereq);
h_feat_ax = axes();


%% Start pulling data
mules_client.flushdata();  % Flush old data from MuLES       
tone(500,500); % Beep sound
             
disp('To stop the exercise execution, close any of the figure windows');

while ~stop_loop
    % 1- ACQUIRE DATA 
    eeg_data = mules_client.getdata(shift_secs, false); % Obtain EEG data from MuLES  
    eeg_buffer = updatebuffer(eeg_buffer, eeg_data); % Update EEG buffer

    % 2- COMPUTE FEATURES 
    % Get newest samples from the buffer 
    data_window = getlastdata(eeg_buffer, win_test_secs * sampling_frequency);
    % Compute features on "data_window" 
    feat_vector = compute_feature_vector(data_window, sampling_frequency);
    feat_buffer = updatebuffer(feat_buffer, feat_vector); % Update the feature buffer

    % 3- VISUALIZE THE RAW EEG AND THE FEATURES        
    plot_channels(h_eeg_ax, eeg_buffer, sampling_frequency, name_of_channels);
    plot_channels(h_feat_ax, feat_buffer, 1/shift_secs, names_of_features);
    % Limits for X axes
    xlim(h_eeg_ax, [0, eeg_buffer_secs]);
    xlim(h_feat_ax, [0, eeg_buffer_secs]); 
    
    pause(0.00001);
   
end

% Close figures
delete(h_eeg_fig);
delete(h_featt_fig);

% Close connection with MuLES
mules_client.disconnect();

% Re-plotting figures
h_eeg_fig = figure();
h_eeg_ax = axes();
h_featt_fig = figure();
h_feat_ax = axes();
plot_channels(h_eeg_ax, eeg_buffer, sampling_frequency, name_of_channels);
plot_channels(h_feat_ax, feat_buffer, 1/shift_secs, names_of_features);
xlim(h_eeg_ax, [0, eeg_buffer_secs]);
xlim(h_feat_ax, [0, eeg_buffer_secs]);

rmpath(genpath('bci_workshop_tools\'));

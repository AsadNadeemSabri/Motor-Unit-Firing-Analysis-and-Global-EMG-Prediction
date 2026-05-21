% Interfacing the Neuromuscular System
% Applications to Human/Machine Interfaces and Neurophysiology
% Exercise 02
% By: Asad Nadeem Sabri

%% --- TASK 1.1 ---

% --- Load Data ---
load('E2_Data_1.mat');  % Replace with E2_Data_2.mat to process second subject

% --- Conversion Constant ---
adc_to_mv = (5 / 2^16 / 150) * 1000;

% --- Filtering Parameters ---
fs = fsamp;
low_cut = 20;     % Hz
high_cut = 500;   % Hz
notch_freq = 50;  % Hz

% --- Design Bandpass Filter (Butterworth 4th Order) ---
[b_bp, a_bp] = butter(4, [low_cut high_cut] / (fs / 2), 'bandpass');

% --- Design Notch Filter (IIR Notch at 50Hz) ---
wo = notch_freq / (fs / 2);      % Normalized frequency
bw = wo / 35;                    % Bandwidth (related to Q-factor)
[b_notch, a_notch] = iirnotch(wo, bw);

% --- Preprocess EMG Signals ---
SIG_preprocessed = cell(size(SIG));
for ch = 1:numel(SIG)
    raw = double(SIG{ch});
    mv_signal = raw * adc_to_mv;              % Convert ADC to millivolts
    bandpassed = filtfilt(b_bp, a_bp, mv_signal);    % Bandpass filter
    notch_filtered = filtfilt(b_notch, a_notch, bandpassed);  % Notch filter
    SIG_preprocessed{ch} = notch_filtered;
end
%% --- TASK 1.2 ---

% Copy preprocessed data to a new variable for further cleaning
SIG_clean = SIG_preprocessed;

% Discard noisy channels based on discardChannelsVec
for ch = 1:numel(SIG_clean)
    if discardChannelsVec(ch) == 1
        SIG_clean{ch} = NaN;  % Replace entire channel with NaN
    end
end
%% --- TASK 1.3 ---

% Define window sizes in milliseconds
window_ms_list = [15, 30, 60];
fs = fsamp;
num_units = length(MUPulses);

% Convert window sizes to samples
window_samples_list = round(window_ms_list / 1000 * fs);

% Initialize STA output structure
STA = cell(length(window_samples_list), num_units);

% Loop over window sizes
for w = 1:length(window_samples_list)
    half_win = floor(window_samples_list(w) / 2);

    % For each motor unit
    for mu = 1:num_units
        spikes = MUPulses{mu};  % spike indices
        mu_STA = cell(size(SIG_clean));  % store per-channel STA

        % Loop through EMG channels
        for ch = 1:numel(SIG_clean)
            signal = SIG_clean{ch};

            if isnumeric(signal) && ~any(isnan(signal))
                snippets = [];

                % Extract snippets centered around each spike
                for s = 1:length(spikes)
                    idx = spikes(s);
                    if idx - half_win >= 1 && idx + half_win <= length(signal)
                        segment = signal((idx - half_win):(idx + half_win));
                        snippets(end + 1, :) = segment;
                    end
                end

                % Average the snippets if available
                if ~isempty(snippets)
                    mu_STA{ch} = mean(snippets, 1);
                else
                    mu_STA{ch} = NaN;
                end
            else
                mu_STA{ch} = NaN;
            end
        end

        % Store STA for this MU and window size
        STA{w}{mu} = mu_STA;
    end
end
%% --- TASK 1.4.1 ---

% --- Parameters ---
mu_idx = 3;                % Motor unit number
win_idx = 2;               % Window index for 30 ms (2nd in list [15,30,60])
rows = 8;
cols = 24;

muap_grid = STA{win_idx}{mu_idx};  % Extract MUAP data for MU 3 at 30ms

% --- Create Figure ---
figure('Name', 'MUAP Grid: MU 3, 30ms', 'Position', [100, 100, 1800, 1000]);

for ch = 1:numel(muap_grid)
    [r, c] = ind2sub([rows, cols], ch);  % Convert index to grid position
    subplot(rows, cols, ch);

    waveform = muap_grid{ch};

    if isnumeric(waveform) && ~any(isnan(waveform))
        plot(waveform, 'k');  % plot MUAP waveform
        ptp = max(waveform) - min(waveform);  % peak-to-peak amplitude
        title(sprintf('%.2f mV', ptp), 'FontSize', 6);
    else
        title('NaN', 'FontSize', 6);
    end

    axis off;
end

sgtitle('MUAP Grid for Motor Unit 3 (30 ms Window)', 'FontWeight', 'bold');

%% --- TASK 1.4.2 ---

% --- Parameters ---
mu_list = 1:5;
window_ms_list = [15, 30, 60];
fs = fsamp;

% --- Create figure ---
figure('Name', 'MUAP Comparison: MUs 1–5 (15, 30, 60 ms)', 'Position', [100, 100, 1200, 800]);

for mu_idx = 1:length(mu_list)
    mu = mu_list(mu_idx);

    for w = 1:length(window_ms_list)
        muap_all_channels = STA{w}{mu};

        % Find channel with highest peak-to-peak amplitude
        max_ptp = -Inf;
        best_waveform = NaN;

        for ch = 1:numel(muap_all_channels)
            waveform = muap_all_channels{ch};
            if isnumeric(waveform) && ~any(isnan(waveform))
                ptp = max(waveform) - min(waveform);
                if ptp > max_ptp
                    max_ptp = ptp;
                    best_waveform = waveform;
                end
            end
        end

        % Plot the best waveform
        subplot(length(mu_list), length(window_ms_list), (mu_idx - 1)*3 + w);
        if isnumeric(best_waveform) && ~any(isnan(best_waveform))
            t = (0:length(best_waveform)-1) / fs * 1000;  % convert to ms
            plot(t, best_waveform, 'k');
            xlabel('Time (ms)');
            ylabel('Amplitude (mV)');
            title(sprintf('MU #%d – %d ms', mu, window_ms_list(w)));
        else
            title(sprintf('MU #%d – %d ms (NaN)', mu, window_ms_list(w)));
            axis off;
        end
    end
end

sgtitle('MUAP Comparison for MUs 1–5 at 15, 30, 60 ms', 'FontWeight', 'bold');

%% --- TASK 2.1 ---

% --- Parameters ---
window_ms = 200;
win_samples = round(window_ms / 1000 * fsamp);  % Convert window to samples

% Assume all signals have same length (pick first non-NaN channel)
valid_idx = find(~cellfun(@isempty, SIG_clean) & ~cellfun(@(x) all(isnan(x)), SIG_clean), 1);
signal_len = length(SIG_clean{valid_idx});

% --- Initialize channel-wise RMS matrix ---
channel_rms = nan(numel(SIG_clean), signal_len - win_samples + 1);

% --- Compute RMS per channel ---
for ch = 1:numel(SIG_clean)
    signal = SIG_clean{ch};

    if isnumeric(signal) && ~any(isnan(signal))
        for i = 1:(signal_len - win_samples + 1)
            segment = signal(i : i + win_samples - 1);
            channel_rms(ch, i) = sqrt(mean(segment.^2));  % RMS for this window
        end
    end
end

% --- Compute Global EMG RMS (average across all valid channels) ---
global_EMG_RMS = nanmean(channel_rms, 1);  % size: [1 x time_samples]
time_vector = (0:length(global_EMG_RMS)-1) / fsamp;  % time in seconds

%% --- TASK 2.2.1 ---

% --- Parameters ---
window_ms = 400;
win_samples = round(window_ms / 1000 * fsamp);  % 400 ms in samples

% Create normalized Hann window
hann_win = hann(win_samples);
hann_win = hann_win / sum(hann_win);  % Normalize for smoothing

% Preallocate discharge rate matrix
signal_len = length(SIG_clean{valid_idx});
num_units = length(MUPulses);
discharge_rates = zeros(num_units, signal_len);

% --- Loop over all motor units ---
for mu = 1:num_units
    spike_train = zeros(1, signal_len);         % Binary train
    spike_indices = MUPulses{mu};
    
    % Ensure valid spike indices
    spike_indices(spike_indices < 1 | spike_indices > signal_len) = [];
    spike_train(spike_indices) = 1;

    % Smooth the spike train using Hann window
    smoothed = conv(spike_train, hann_win, 'same');

    % Convert to pulses per second (pps)
    smoothed_pps = smoothed * fsamp;

    discharge_rates(mu, :) = smoothed_pps;
end

%% --- TASK 2.2.2 ---

% Ensure discharge_rates and global_EMG_RMS are same length
discharge_rates = discharge_rates(:, 1:length(global_EMG_RMS));

% Normalize global EMG RMS (range 0 to 1)
global_EMG_norm = global_EMG_RMS / max(global_EMG_RMS);

% Create time vector
time_vector = (0:length(global_EMG_RMS)-1) / fsamp;

% --- Plot ---
figure('Name', 'sCST vs Global EMG RMS', 'Position', [100, 100, 1200, 250 * num_units]);

for mu = 1:num_units
    subplot(num_units, 1, mu);
    
    % Plot sCST
    plot(time_vector, discharge_rates(mu, :), 'k', 'LineWidth', 1.2);
    hold on;

    % Plot scaled global RMS on same axis
    scaled_rms = global_EMG_norm * max(discharge_rates(mu, :));
    plot(time_vector, scaled_rms, 'r--', 'LineWidth', 1);
    hold off;

    title(sprintf('Motor Unit #%d', mu));
    xlabel('Time (s)');
    ylabel('Discharge Rate (pps)');
    legend('sCST', 'Normalized Global EMG RMS');
end

%% --- TASK 2.3 ---

% --- Prepare Data ---
X = discharge_rates.';                    % [time x units]
Y = global_EMG_RMS(:);                   % [time x 1]

% Remove any NaNs (though unlikely)
valid_idx = all(~isnan(X), 2) & ~isnan(Y);
X = X(valid_idx, :);
Y = Y(valid_idx);

% --- Fit Linear Regression Model ---
B = X \ Y;                                % Least squares solution
Y_pred = X * B;

% --- Compute R² Score ---
SS_res = sum((Y - Y_pred).^2);
SS_tot = sum((Y - mean(Y)).^2);
R_squared = 1 - (SS_res / SS_tot);

% --- Compute Correlation Coefficient ---
corr_coeff = corr(Y, Y_pred);

% --- Time Vector (adjusted for valid indices) ---
t = time_vector(valid_idx);

% --- Plot ---
figure('Name', 'Linear Regression: sCST → Global EMG RMS', 'Position', [100, 100, 1000, 400]);
plot(t, Y, 'k', 'LineWidth', 1.5); hold on;
plot(t, Y_pred, 'r--', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Global EMG RMS (mV)');
legend('Actual RMS', 'Predicted RMS');
title(sprintf('Linear Regression: R^2 = %.3f, Corr = %.3f', R_squared, corr_coeff));

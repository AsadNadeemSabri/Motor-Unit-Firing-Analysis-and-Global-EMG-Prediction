# 🧠 EMG Signal Processing & Motor Unit Analysis (MATLAB)

A MATLAB-based pipeline for processing **High-Density Surface EMG (HD-sEMG)** signals, extracting **Motor Unit Action Potentials (MUAPs)** via Spike-Triggered Averaging, computing discharge rates, and predicting global muscle activity using linear regression.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Installation](#installation)
- [Pipeline Walkthrough](#pipeline-walkthrough)
- [Results](#results)
- [Usage](#usage)

---

## Overview

This project processes high-density surface EMG recordings from two subjects:

- **Subject 1** — HD-sEMG data stored in `E2_Data_1.mat`
- **Subject 2** — HD-sEMG data stored in `E2_Data_2.mat`

The pipeline covers signal loading, ADC-to-millivolt conversion, notch and bandpass filtering, noisy channel removal, Spike-Triggered Averaging (STA) for MUAP extraction, smoothed cumulative spike train (sCST) computation, and ultimately predicts global EMG amplitude from motor unit discharge rates using multiple linear regression.

---

## Project Structure

```
├── E2_Data_1.mat            # HD-sEMG dataset — Subject 1
├── E2_Data_2.mat            # HD-sEMG dataset — Subject 2
├── emg_processing.m         # Main MATLAB processing script
└── README.md
```

---

## Requirements

- MATLAB R2018b or later
- Signal Processing Toolbox (`butter`, `filtfilt`, `iirnotch`, `hann`)
- Statistics and Machine Learning Toolbox (`corr`)

---

## Installation

1. Clone or download this repository into your MATLAB working directory.
2. Place `E2_Data_1.mat` and `E2_Data_2.mat` in the same folder as the script.
3. Open `emg_processing.m` in MATLAB and run:
   - **Full script**: press `F5`
   - **Section by section**: press `Ctrl+Enter` inside each `%%` cell block

---

## Pipeline Walkthrough

### Task 1.1 — Load & Preprocess EMG

Both `.mat` files are loaded using MATLAB's `load()`. The raw EMG signal is converted from ADC counts to millivolts using the conversion formula:

```
mV = (counts × 5) / (2^16 × 150) × 1000
```

Two filters are applied sequentially to all channels:

| Filter | Type | Parameters |
|--------|------|------------|
| Notch | IIR Notch | 50 Hz, bandwidth = `wo / 35` |
| Bandpass | 4th-order Butterworth | 20–500 Hz |

Both filters use zero-phase `filtfilt` to eliminate phase distortion. Result stored in `SIG_preprocessed`.

---

### Task 1.2 — Discard Noisy Channels

Channels flagged with a `1` in `discardChannelsVec` are replaced with `NaN` and excluded from all downstream processing. Clean signals are stored in `SIG_clean`.

---

### Task 1.3 — Spike-Triggered Averaging (STA)

For each motor unit and three window sizes, signal snippets are extracted centered on every spike and averaged per channel:

| Window Size | Samples (at typical fs) |
|-------------|------------------------|
| 15 ms | short |
| 30 ms | medium |
| 60 ms | long |

Result stored in `STA{window_index}{mu_index}` — a cell array of per-channel averaged MUAP waveforms.

---

### Task 1.4.1 — MUAP Grid Visualization

The MUAP waveform of **Motor Unit 3** at the **30 ms** window is plotted across the full **8×24 electrode grid**. Each subplot shows the waveform in black with its **peak-to-peak amplitude (mV)** as the title. Channels with no valid data are labelled `NaN`.

---

### Task 1.4.2 — MUAP Best-Channel Comparison

For each of **Motor Units 1–5** and all three window sizes, the channel with the **highest peak-to-peak amplitude** is selected and plotted. Results are displayed as a **5×3 grid** with time in milliseconds on the x-axis.

---

### Task 2.1 — Global EMG RMS

A sliding-window RMS is computed with a **200 ms** window (step = 1 sample) across all valid channels. The channel-wise RMS values are averaged using `nanmean` to produce a single **global EMG RMS** time series in mV.

---

### Task 2.2.1 — Smoothed Cumulative Spike Train (sCST)

Each motor unit's spike times are converted into a binary spike train, then convolved with a normalized **400 ms Hann window** and multiplied by `fsamp` to express discharge rate in **pulses per second (pps)**. Result stored in `discharge_rates` — a matrix of size `[num_units × signal_length]`.

---

### Task 2.2.2 — sCST vs Global RMS Plot

Each motor unit's sCST (black solid) is plotted alongside the **normalized global EMG RMS** (red dashed) on the same axis, scaled to match the sCST y-range. One subplot per motor unit with a shared time axis.

---

### Task 2.3 — Force Prediction via Linear Regression

All motor unit discharge rates are used as predictors (`X`) and the global EMG RMS as the target (`Y`). A **least-squares linear model** is fitted using MATLAB's backslash operator.

Performance is evaluated using two metrics:

```
R²   = 1 - (SS_residual / SS_total)
Corr = Pearson correlation between actual and predicted RMS
```

Actual (black) and predicted (red dashed) RMS are plotted over time.

---

## Results

| Task | Metric | Value |
|------|--------|-------|
| 2.3 | R² (sCST → Global RMS) | Computed at runtime |
| 2.3 | Pearson Correlation | Computed at runtime |

---

## Usage

1. Update the filename at the top of the script if needed:

```matlab
load('E2_Data_1.mat');  % Replace with E2_Data_2.mat for second subject
```

2. Run the script. All figures will display sequentially. To save figures to disk, add after each plot:

```matlab
saveas(gcf, 'output_figure.png');
% or
exportgraphics(gcf, 'output_figure.png', 'Resolution', 150);
```

---

## 📄 License

This project is for academic and research purposes — FAU Erlangen-Nürnberg, INS Exercise 2.

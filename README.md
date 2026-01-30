# Gaze-Preprocessing-Code

## Overview
This repository contains the gaze data preprocessing and analysis pipeline for the manuscript **"Two Distinct Attentional Priorities Guide Exploratory and Exploitative Gaze."** The codebase is designed to transform raw session data into interpretable visualizations and statistical classifications. It focuses on two primary analytical outputs: spatial heatmaps representing gaze density and temporal classification of eye events (saccades, fixations, and smooth pursuit) (Voloh et al., 2020). Other data related with the paper can be found on [Zenodo](https://zenodo.org/records/18310415).

## Analysis Pipeline & Logic

The analysis functions through a three-stage pipeline that moves from raw data ingestion to spatial and temporal processing.

### 1. Data Ingestion and Parsing
The entry point of the analysis is the standardization of raw session folders into MATLAB-compatible formats. [cite_start]The system utilizes `ProcessingSingleSessionData.m` to parse the raw directory structure[cite: 3, 4]. [cite_start]This function extracts independent data streams—specifically gaze vectors, frame timestamps, and block information—and consolidates them into synchronized tables (`GazeData.mat`, `TrialData.mat`)[cite: 3, 8]. [cite_start]This step ensures that the high-frequency gaze data (sampled at 600 Hz) is correctly aligned with the lower-frequency experimental frame data[cite: 21].

### 2. Spatial Density Analysis (Heatmap Generation)
To visualize attentional allocation, the pipeline converts discrete gaze coordinates into a continuous spatial density map. [cite_start]The script `GazeDataAnalysis.m` executes this transformation[cite: 12].
* **Coordinate Transformation:** Raw ADCS coordinates are mapped to the screen resolution (1920x1080).
* **Binning and Smoothing:** The script generates a 2D histogram of gaze positions using `histcounts2` and applies a Gaussian convolution kernel (sigma=8) to smooth the data. This converts raw point data into a visualizable probability density function.
* **Object Overlay:** The logic retrieves trial-specific stimuli data (`relevantStims`) to overlay the positions of target objects, distinguishing between selected targets (red) and distractors (blue).

### 3. Temporal Event Classification (`ana_extractEyeEvents_new.m`)
The final stage segments the continuous gaze stream into discrete behavioral events. [cite_start]The function `ana_extractEyeEvents_new` processes the coordinate data to identify distinct oculomotor behaviors[cite: 15].

**Mathematical Methods & Algorithms:**
* **Binocular Fusion & Offset Correction:**
    The function integrates left and right eye streams into a single cyclopean gaze vector using `nanmean`. It applies a dynamic offset correction algorithm: if one eye's data is lost (NaN), the remaining eye's signal is shifted to match the mean of the binocular signal, preventing artificial jumps in position.
* **Coordinate Conversion:**
    Raw screen coordinates are converted into **Degrees of Visual Angle (DVA)** using distance estimation (`pos2dva`). This ensures that velocity thresholds are biologically valid (deg/s) rather than pixel-based.
* **Differentiation via Savitzky-Golay Filtering:**
    To classify events, the code computes the first derivative (Velocity) and second derivative (Acceleration) of the gaze position. It utilizes a **Savitzky-Golay filter** (2nd order polynomial, `sgolay` function) rather than simple finite differences. This method smooths the position signal while simultaneously calculating derivatives, preserving high-frequency signal characteristics essential for detecting saccade onsets.
* **Event Definitions:**
    Using the calculated Velocity and Acceleration profiles, the data is segmented into:
    1.  **Saccades** (High velocity/acceleration ballistic movements)
    2.  **Post-Saccadic Oscillations (PSO)**
    3.  **Fixations** (Stable, low-velocity periods)
    4.  **Smooth Pursuit** (Consistent non-ballistic motion)
   

## Usage Instructions

### Prerequisites
* MATLAB (versions compatible with the `imagesc` and `histcounts2` functions).
* The raw data folder structure must match the `Session_1__Subject...` format expected by the parser.

### Step 1: Import Gaze Data
Run the processing function to generate the `.mat` files for a specific session. Ensure the `gazeArgs` is set to `'proceed'`.

```matlab
ProcessingSingleSessionData('dataFolder', '/path/to/Session_Folder', ...
                            'gazeArgs', 'proceed', ...
                            'folderName', 'MazeGame_M1_v01_Set01')
```

### Step 2: Generate Spatial Heatmaps

Load the processed `GazeData.mat` and `TrialData.mat` into your workspace. Run the analysis script to generate the smoothed heatmap overlaid with object positions.

```matlab
% Ensure gazeData and trialData are in the workspace
GazeDataAnalysis
```

### Step 3: Classify and Plot Gaze Events

Execute the event extraction function on the gaze data, followed by the classification visualization tool.

```matlab
[SacStructOut, processedGaze] = ana_extractEyeEvents_new(mazeGazeData, 'spectrum');
processing_classified_data(processedGaze)
```

## Repository Structure

`GazeDataAnalysis.m`: Main script for spatial heatmap generation and object overlay.
`ProcessingSingleSessionData.m`: Parses raw session folders. 
`ana_extractEyeEvents_new.m`: Core algorithm for gaze event classification using Savitzky-Golay filtering.
`processing_classified_data.m`: Visualizes classified time-series data.

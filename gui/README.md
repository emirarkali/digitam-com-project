# MATLAB Graphical User Interface — Project 7

This directory contains the interactive GUI for the Project 7 Digital Communication System.

## Implementation Architecture: Programmatic `.m` GUI

In accordance with Section 5 of the Master Specification, the GUI is implemented as a self-contained, robust programmatic MATLAB App in `Project7_GUI.m`.

### Why Programmatic `Project7_GUI.m` over Binary `.mlapp`:
1. **Source Control Integrity:** MATLAB `.mlapp` files are proprietary ZIP-compressed binary containers holding XML definitions. They cannot be reliably inspected, diffed, merged, or generated headlessly without risking archive corruption.
2. **Platform & Version Compatibility:** Programmatic GUI construction using MATLAB's modern App building components (`uifigure`, `uigridlayout`, `uiaxes`, `uibutton`, `uidropdown`, `uislider`, `uitabgroup`) is 100% portable across MATLAB R2020a through R2026b and requires zero toolboxes.
3. **Automated Testing:** Programmatic figures can be launched, programmatically inspected, exercised via event callbacks, and safely destroyed in automated headless Continuous Integration (CI) test suites.

---

## Features & Capabilities

- **1. Audio Input Source Selection:**
  - *Deterministic Synthetic Speech:* Clean, reproducible multi-harmonic signal with natural amplitude envelope.
  - *WAV File Selection:* Interactive file picker via `uigetfile` supporting any mono or multichannel `.wav` file.
  - *Live Microphone Capture:* Real-time recording via MATLAB's `audiorecorder` with graceful fallback if no audio device is detected.
- **2. Parameter Configuration:**
  - *Quantization Resolution:* Dropdown selection for 8-bit (256 levels), 4-bit (16 levels), or 3-bit (8 levels) uniform $\mu$-law quantization ($\mu = 255$).
  - *Channel SNR:* Interactive slider from $0.0$ to $10.0\text{ dB}$ ($E_s/N_0$).
- **3. Interactive Visualizations:**
  - *Audio Waveforms Tab:* Compares original input, $\mu$-law quantized, and channel-reconstructed waveforms.
  - *QPSK Constellation Tab:* Visualizes received noisy I/Q symbols against ideal Gray-mapped constellation coordinates.
  - *BER vs SNR Tab:* Plots Monte Carlo simulation curves (coded-bit BER, info-bit BER, uncoded QPSK, and theoretical limit).
  - *DM vs ADM Tab:* Displays tracking waveforms and error signals comparing fixed-step DM and geometric ADM.
- **4. Audio Playback:**
  - Dedicated buttons to listen to the original audio vs the channel-degraded/reconstructed audio via `sound`.
- **5. Export Functions:**
  - Export reconstructed audio as standard WAV (`data/output/`).
  - Export BER sweep and performance tables as CSV (`results/tables/`).

---

## How to Launch the GUI

From within MATLAB:
```matlab
cd('/home/emir/digital-com-project');
addpath(genpath(pwd));
Project7_GUI
```

From Linux terminal (Keeps window open until closed):
```bash
LC_ALL=C.UTF-8 matlab -batch "launch_gui"
# Or:
LC_ALL=C.UTF-8 matlab -batch "addpath(genpath(pwd)); uiwait(Project7_GUI);"
```

From Linux terminal (Interactive MATLAB desktop session):
```bash
LC_ALL=C.UTF-8 matlab -nosplash -r "addpath(genpath(pwd)); Project7_GUI"
```
*(Note: MATLAB `-batch` automatically terminates MATLAB when execution finishes; `launch_gui` or `uiwait` instructs MATLAB to wait until the GUI window is closed by the user).*

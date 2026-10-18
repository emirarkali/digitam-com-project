# Project 7: Digital Communication System

A complete, end-to-end baseband digital communication system implemented in MATLAB for transmitting speech audio over an Additive White Gaussian Noise (AWGN) channel.

```text
Audio Source -> mu-law PCM Encoder -> (8,4) SECDED Channel Encoder -> Gray QPSK Modulator
             -> Complex AWGN Channel -> ML QPSK Demodulator -> Syndrome SECDED Decoder
             -> mu-law PCM Decoder -> Audio Reconstruction & Playback
```

---

## Key Highlights

- **Complete End-to-End Pipeline:** Source coding ($\mu$-law PCM, $3, 4, 8$ bits), linear block channel coding ($(8,4)$ SECDED), Gray-mapped QPSK modulation, complex AWGN channel, ML demodulation, syndrome error correction, and audio reconstruction.
- **Zero Toolbox Dependencies:** Pure core MATLAB arithmetic, matrices, and graphics. No Communications Toolbox (`comm.*`, `pskmod`, `pskdemod`, `awgn`, `encode`, `decode`, `biterr`), and no DSP Toolbox functions.
- **Extensively Tested & Verified:** Includes 6 comprehensive, assert-based unit and integration test suites covering 100% of single-bit errors (128/128) and double-bit error detections (448/448).
- **Interactive MATLAB GUI:** Single-run simulation, 0–10 dB Monte Carlo BER sweep, real-time waveform display, QPSK constellation plot, and audio playback (`Project7_GUI.m`).
- **High Performance:** Vectorized implementation processes an entire 10-second ($80,000$ samples, $1.28$ million coded bits) audio transmission in under $0.15$ seconds.

---

## System Requirements & Environment

- **MATLAB Version:** MATLAB R2026b (or R2020a+)
- **Operating System:** Linux (Ubuntu 24.04 tested), Windows, or macOS
- **Toolboxes:** **NONE REQUIRED.** Works with base MATLAB.

> [!IMPORTANT]
> **Linux Turkish Locale Notice:**  
> On Linux systems with Turkish locale (`LANG=tr_TR.UTF-8`), MATLAB's internal LXE symbol registry can fail on startup due to dotted/dotless 'I' character conversions. Always launch MATLAB with `LC_ALL=C.UTF-8`:
> ```bash
> LC_ALL=C.UTF-8 matlab
> ```

---

## Quick Start Guide

### 1. Launch MATLAB and Add Repository Path
Open MATLAB in the project directory:

```matlab
% In MATLAB Command Window:
cd('/home/emir/digital-com-project');
addpath(genpath(pwd));
```

### 2. Run the Main Demonstration
Executes single-run transmission at $6.0\text{ dB}$, runs a 0–10 dB Monte Carlo BER sweep, and exports figures and CSV tables:

```matlab
main
```

### 3. Run the Automated Test Suite
Executes all 6 unit and integration test modules with detailed timings and verification status:

```matlab
run_all_tests
```

### 4. Launch the Interactive GUI
Opens the interactive GUI window for audio selection, parameter tuning, simulation, and listening:

- **From MATLAB Command Window:**
  ```matlab
  Project7_GUI
  ```
- **From Linux Terminal (Keeps window open until closed):**
  ```bash
  LC_ALL=C.UTF-8 matlab -batch "launch_gui"
  # Or:
  LC_ALL=C.UTF-8 matlab -batch "addpath(genpath(pwd)); uiwait(Project7_GUI);"
  ```
- **From Linux Terminal (Interactive MATLAB desktop session):**
  ```bash
  LC_ALL=C.UTF-8 matlab -nosplash -r "addpath(genpath(pwd)); Project7_GUI"
  ```
*(Note: `-batch` exits MATLAB immediately upon command completion unless `uiwait` or `launch_gui` is used).*

---

## How to Use Your Own Audio (WAV Files)

1. Place your `.wav` file into the `data/input/` directory:
   ```bash
   cp /path/to/my_speech.wav data/input/
   ```
2. In the MATLAB GUI (`Project7_GUI`), select **"Select WAV File..."** from the Audio Source dropdown and choose your file.
3. Or programmatically via script:
   ```matlab
   config = struct();
   config.source = 'data/input/my_speech.wav';
   config.durationSec = 10;
   config.pcmBits = 8;
   config.snrDB = 6.0;
   results = run_full_system(config);
   ```
   The system automatically converts multichannel audio to mono, resamples to $8000\text{ Hz}$, enforces duration, and normalizes dynamic range to $[-1.0, +1.0]$.

---

## Repository Structure

```text
~/digital-com-project/
├── main.m                         # Master pipeline demonstration & sweep
├── README.md                      # Project manual and quick start guide
├── ANTIGRAVITY_PROJECT7_PROMPT.md # Project specification prompt
├── .gitignore                     # Git tracking exclusions
│
├── src/                           # Source code modules (by engineer role)
│   ├── person1_audio/             # Source coding, PCM, SQNR, DM/ADM
│   │   ├── audio_input.m
│   │   ├── pcm_encoder.m
│   │   ├── pcm_decoder.m
│   │   ├── calculate_sqnr.m
│   │   ├── dm_encoder.m
│   │   ├── dm_decoder.m
│   │   ├── adm_encoder.m
│   │   └── adm_decoder.m
│   ├── person2_channel_coding/    # (8,4) SECDED Linear Block Code
│   │   ├── generate_matrices.m
│   │   ├── channel_encoder.m
│   │   └── channel_decoder.m
│   ├── person3_modulation/        # QPSK, AWGN Channel, Demodulation, BER
│   │   ├── qpsk_mod.m
│   │   ├── qpsk_demod.m
│   │   ├── add_awgn.m
│   │   ├── calculate_ber.m
│   │   └── ber_simulation.m
│   └── common/
│       └── run_full_system.m      # Unified integration pipeline
│
├── gui/
│   ├── Project7_GUI.m             # Programmatic interactive GUI App
│   └── README.md                  # GUI documentation
│
├── tests/                         # Assertion-based unit & system tests
│   ├── run_all_tests.m            # Master test suite runner
│   ├── test_pcm.m                 # PCM companding and quantization tests
│   ├── test_dm_adm.m              # DM and ADM tracking and step tests
│   ├── test_channel_coding.m      # 128 single-bit & 448 double-bit tests
│   ├── test_qpsk.m                # Gray mapping, unit energy, ML tests
│   ├── test_awgn.m                # Noise variance and EsN0/EbN0 tests
│   └── test_full_system.m         # 80k-sample stress and integration tests
│
├── scripts/
│   └── generate_all_results.m     # Batch generation of figures & tables
│
├── data/
│   ├── input/                     # User/course input WAV files
│   └── output/                    # Reconstructed audio WAV files
│
├── results/
│   ├── figures/                   # Generated PNG plots (waveforms, BER, etc.)
│   └── tables/                    # Generated CSV tables (BER, SQNR, DM/ADM)
│
├── docs/
│   ├── ARCHITECTURE.md            # Architectural block diagram & data flow
│   ├── API.md                     # Complete function interface reference
│   ├── MATHEMATICS.md             # Theoretical derivations and SECDED proofs
│   ├── TEAM_TASKS.md              # Role distribution across 3 team members
│   ├── TEST_PLAN.md               # Test coverage and assertion strategy
│   ├── TEST_RESULTS.md            # Empirical execution log and timings
│   └── IMPLEMENTATION_PROGRESS.md # Progress tracking against master prompt
│
├── reports/
│   └── Final_Report.md            # English academic technical report draft
│
└── poster/
    └── A0_Poster_Content.md       # English A0 poster specification (841x1189 mm)
```

---

## Experimental Findings Summary

- **PCM SQNR:**
  - $3$-bit: $9.18\text{ dB}$ (8 levels)
  - $4$-bit: $13.80\text{ dB}$ (16 levels)
  - $8$-bit: $38.01\text{ dB}$ (256 levels)
- **DM vs ADM:**
  - Linear DM tracking MSE: $2.48 \times 10^{-1}$ (severe slope overload lag).
  - Adaptive DM tracking MSE: $1.03 \times 10^{-2}$ ($24\times$ lower MSE, $13.8\text{ dB}$ higher SQNR).
- **Channel Coding Performance:**
  - Orthogonality: $G \cdot H^T \equiv 0 \pmod 2$.
  - Single-Bit Errors: $128 / 128$ corrected ($100\%$).
  - Double-Bit Errors: $448 / 448$ detected without false corrections ($100\%$).
  - Coding Gain: At $\text{SNR} = 6\text{ dB}$, SECDED reduces bit errors by $6.9\times$ compared to uncoded QPSK. At $10\text{ dB}$, bit error rate reaches $0.00000$.

---

## Known Limitations

1. **SECDED Distance Bounds:** As with any code with $d_{\min} = 4$, 3-bit errors produce odd-weight syndromes that result in miscorrection.
2. **Hard-Decision Demodulation:** Coherent demodulator passes hard bits to the syndrome decoder; soft-decision Viterbi decoding would yield an additional $\approx 2\text{ dB}$ of coding gain.
3. **App Designer `.mlapp` Note:** The GUI is implemented programmatically in `gui/Project7_GUI.m` using MATLAB's standard UI components (`uifigure`, `uigridlayout`, `uiaxes`), which guarantees platform-independent compatibility without binary file corruption.

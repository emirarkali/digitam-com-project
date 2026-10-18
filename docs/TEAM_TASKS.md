# Team Task Allocation & Responsibilities — Project 7

This document formalizes the division of engineering responsibilities among the three development team members for the Project 7 Digital Communication System.

---

## Member Roles and Specific File Assignments

### Person 1: Source Coding, Speech Audio & Delta Modulation
- **Assigned Subsystem:** Source acquisition, $\mu$-law PCM companding, uniform quantization, SQNR evaluation, Delta Modulation, and Adaptive Delta Modulation.
- **Assigned Files (`src/person1_audio/`):**
  - `audio_input.m`: Multichannel audio handling, mono conversion, polyphase resampling, 10s duration enforcement, and normalization.
  - `pcm_encoder.m`: Non-linear $\mu$-law compander ($\mu=255$), mid-rise quantizer ($3, 4, 8$ bits), and toolbox-free bit packing.
  - `pcm_decoder.m`: Binary bit unpacking, reconstruction to midpoint levels, and inverse $\mu$-law expansion.
  - `calculate_sqnr.m`: Rigorous Signal-to-Quantization-Noise Ratio computation in dB with edge-case handling.
  - `dm_encoder.m` & `dm_decoder.m`: Linear Delta Modulation with fixed step size $\Delta$.
  - `adm_encoder.m` & `adm_decoder.m`: Adaptive Delta Modulation with geometric step-size adaptation ($\alpha, \beta$) and clamping ($\Delta_{\min}, \Delta_{\max}$).
- **Assigned Unit Tests:** `tests/test_pcm.m`, `tests/test_dm_adm.m`.
- **GUI Contributions:** Waveform axes visualization, audio input source dropdown, PCM bit-depth selection, and audio playback callbacks.

---

### Person 2: Channel Coding & SECDED Error Control
- **Assigned Subsystem:** $(8,4)$ Systematic Linear Block Code, Generator/Parity-Check matrix generation, encoding, and syndrome-based SECDED decoding.
- **Assigned Files (`src/person2_channel_coding/`):**
  - `generate_matrices.m`: Matrix creation for specified $H$ and $G = [I_4 \mid P]$, verifying $G \cdot H^T \equiv 0 \pmod 2$.
  - `channel_encoder.m`: Systematic encoding ($c = m \cdot G \pmod 2$) and zero-padding metadata handling.
  - `channel_decoder.m`: Fast syndrome computation ($S = r \cdot H^T \pmod 2$), odd-weight single-error correction, even-weight double-error detection, and status reporting (`0`: no error, `1`: single corrected, `2`: uncorrectable).
- **Assigned Unit Tests:** `tests/test_channel_coding.m` (verifying all 16 messages, all 128 single-bit error patterns, all 448 double-bit error patterns).
- **GUI Contributions:** Real-time decoding statistics display (corrected blocks, uncorrectable blocks).

---

### Person 3: Digital Modulation, AWGN Channel & BER Simulation
- **Assigned Subsystem:** Gray-mapped QPSK modulation, complex AWGN channel modeling, coherent ML demodulation, and Monte Carlo BER simulations.
- **Assigned Files (`src/person3_modulation/`):**
  - `qpsk_mod.m`: Gray constellation mapping with exact unit symbol energy ($E_s = 1.0$).
  - `qpsk_demod.m`: Maximum Likelihood (nearest-neighbor) coherent decision rule.
  - `add_awgn.m`: Complex Gaussian noise generator with $I/Q$ variance partitioning ($\sigma = \sqrt{N_0/2}$) and $E_s/N_0$ vs $E_b/N_0$ conversions.
  - `calculate_ber.m`: Vectorized bit error rate computation.
  - `ber_simulation.m`: Monte Carlo simulation across $0:1:10\text{ dB}$, evaluating coded-bit BER, info-bit BER, uncoded QPSK baseline, and theoretical $P_b = \frac{1}{2}\text{erfc}(\sqrt{E_b/N_0})$.
- **Assigned Unit Tests:** `tests/test_qpsk.m`, `tests/test_awgn.m`.
- **GUI Contributions:** Constellation scatter axes, BER vs SNR semilogy plot, and SNR control slider.

---

## Shared Integration & Deliverable Responsibilities

| Activity / Artifact | Lead Contributor | Reviewers / Collaborators |
|---|---|---|
| Pipeline Integration (`run_full_system.m`) | Person 3 | Persons 1 & 2 |
| Master Execution Script (`main.m`) | Person 1 | Persons 2 & 3 |
| Master Test Suite (`run_all_tests.m`, `test_full_system.m`) | Person 2 | Persons 1 & 3 |
| Interactive GUI (`gui/Project7_GUI.m`) | Person 3 | Persons 1 & 2 |
| Results & Figure Generator (`scripts/`) | Person 1 | Persons 2 & 3 |
| System Documentation (`docs/*.md`, `README.md`) | Persons 1, 2, 3 | Shared sign-off |
| Final Academic Report (`reports/Final_Report.md`) | Persons 1, 2, 3 | Shared sign-off |
| A0 Poster Content (`poster/A0_Poster_Content.md`) | Persons 1, 2, 3 | Shared sign-off |

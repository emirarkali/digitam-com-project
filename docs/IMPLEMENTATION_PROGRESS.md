# Implementation Progress — Project 7 Digital Communication System

## Environment Audit
- **Operating System:** Ubuntu 24.04.5 LTS (x86_64)
- **MATLAB Version:** MATLAB R2026b (26.2.0.3386108) at `/usr/local/MATLAB/R2026b`
- **Environment Note:** When running MATLAB in this environment, `LC_ALL=C.UTF-8` is required to avoid Turkish locale (`tr_TR.UTF-8`) character case mapping issues with internal MATLAB LXE built-in symbol registrations.
- **Toolbox Policy:** Pure core MATLAB functions only. Strictly no Communications Toolbox functions (`pskmod`, `pskdemod`, `awgn`, `comm.*`, `encode`, `decode`, `biterr`, etc.).

---

## Phase Checklist

### Phase A: Repository Audit & API Conventions
- [x] Inspect directory structure and existing files
- [x] Verify MATLAB runtime execution and headless test capability
- [x] Resolve environment/locale settings (`LC_ALL=C.UTF-8`)
- [x] Define exact API signatures and data conventions
- [x] Create `docs/IMPLEMENTATION_PROGRESS.md`

### Phase B: Core Independent Modules
- [ ] Person 1 (Audio): `audio_input.m`, `pcm_encoder.m`, `pcm_decoder.m`, `calculate_sqnr.m`
- [ ] Person 1 (Delta Modulation): `dm_encoder.m`, `dm_decoder.m`, `adm_encoder.m`, `adm_decoder.m`
- [ ] Person 2 (Channel Coding): `generate_matrices.m`, `channel_encoder.m`, `channel_decoder.m`
- [ ] Person 3 (Modulation & AWGN): `qpsk_mod.m`, `qpsk_demod.m`, `add_awgn.m`, `calculate_ber.m`, `ber_simulation.m`
- [ ] Unit Tests: `test_pcm.m`, `test_dm_adm.m`, `test_channel_coding.m`, `test_qpsk.m`, `test_awgn.m`

### Phase C: System Integration
- [ ] Common helper: `src/common/run_full_system.m`
- [ ] Pipeline script: `main.m` (synthetic test mode + WAV mode)
- [ ] Integration tests: `tests/test_full_system.m`
- [ ] Test master runner: `tests/run_all_tests.m`

### Phase D: GUI Implementation
- [ ] Programmatic UI: `gui/Project7_GUI.m` using `uifigure`, `uigridlayout`, `uiaxes`, controls, and event handlers
- [ ] Audio playback, export, BER sweep, constellation display, error traps

### Phase E: Experimental Verification & Results
- [ ] Automated generation script: `scripts/generate_all_results.m`
- [ ] BER vs SNR simulation (0:1:10 dB, coded vs uncoded vs theoretical)
- [ ] SQNR vs PCM bit depth (3, 4, 8 bits)
- [ ] DM vs ADM sinusoidal comparison (slope overload vs granular noise)
- [ ] Clean and noisy QPSK constellation plots
- [ ] Result data tables (`results/tables/*.csv`)
- [ ] Result figures (`results/figures/*.png`)

### Phase F: Documentation & Deliverables
- [ ] `README.md`: complete usage, quick start, architecture overview
- [ ] `docs/ARCHITECTURE.md`: block diagram, signal levels, rates, energy
- [ ] `docs/API.md`: signatures, inputs, outputs, data types, errors
- [ ] `docs/MATHEMATICS.md`: formulas, derivations, SECDED syndrome analysis
- [ ] `docs/TEAM_TASKS.md`: work breakdown among 3 personas
- [ ] `docs/TEST_PLAN.md`: unit and integration test definitions
- [ ] `docs/TEST_RESULTS.md`: actual execution output and verification log
- [ ] `reports/Final_Report.md`: academic English report
- [ ] `poster/A0_Poster_Content.md`: complete A0 poster content and layout

### Phase G: Final Audit & Verification
- [ ] Zero forbidden toolbox dependencies
- [ ] All unit and system tests passing
- [ ] Final implementation status report with commands

# Verification & Test Plan — Project 7 Digital Communication System

## 1. Testing Philosophy
- **Assertion-Based:** Every test is implemented as a standalone script using MATLAB's native `assert(...)` statements.
- **Zero Fabrication:** Test outcomes are strictly recorded from actual execution runs.
- **Toolbox Independence:** All tests execute using base MATLAB arithmetic, matrices, and core functions only.
- **Reproducibility:** Random processes use deterministic pseudo-random number generator seeds (`rng(seed)`).

---

## 2. Test Suite Architecture

| Test Script | Target Subsystem | Assertions & Coverage Criteria |
|---|---|---|
| `tests/test_pcm.m` | $\mu$-law PCM & Quantization | - Silence test: 1000 zero samples round-trip.<br>- Full-scale test: $\pm 1.0$ saturation.<br>- Clipping test: inputs $> 1$ clamped to $[-1, 1]$.<br>- Monotonicity: $\text{SQNR}_{3\text{b}} < \text{SQNR}_{4\text{b}} < \text{SQNR}_{8\text{b}}$.<br>- Reconstructed signal equals quantizer output.<br>- Column/row vector robustness.<br>- Bit packing/unpacking round-trip. |
| `tests/test_dm_adm.m` | Delta Modulation (DM & ADM) | - Constant signal test: hunting / granular noise.<br>- Sinusoid test: encoder-decoder synchronization.<br>- ADM step-size clamping: $\Delta \in [\Delta_{\min}, \Delta_{\max}]$.<br>- Steep ramp test: ADM MSE significantly lower than fixed DM. |
| `tests/test_channel_coding.m` | $(8,4)$ SECDED Channel Code | - Matrix dimensions: $G$ is $4 \times 8$, $H$ is $4 \times 8$.<br>- Orthogonality: $\text{mod}(G \cdot H^T, 2) == 0$.<br>- All 16 valid codewords have zero syndrome ($S = 0$).<br>- Exhaustive 128 single-bit error flips: 100% recovered to original message, status = 1.<br>- Exhaustive 448 double-bit error flips: 100% detected without miscorrection, status = 2.<br>- Padding test: arbitrary lengths ($1, 2, 3, 5, 7, 11, 23, 97$ bits). |
| `tests/test_qpsk.m` | Gray QPSK Mod / Demod | - Constellation coordinates: `00`, `01`, `11`, `10` match exact quadrants.<br>- Unit average energy: $|s|^2 == 1.0$ ($< 10^{-12}$).<br>- Noiseless round-trip: 50,000 random bits yield $\text{BER} = 0$.<br>- ML nearest-neighbor decision boundary checks with perturbations. |
| `tests/test_awgn.m` | Complex AWGN Channel | - Noise variance: 200,000 samples match theoretical $N_0$ within $2\%$.<br>- Quadrature balance: $\text{Var}(I) \approx \text{Var}(Q) \approx N_0/2$.<br>- I/Q independence: correlation coefficient $< 0.01$.<br>- $E_s/N_0$ vs $E_b/N_0$ numerical relationship.<br>- Seed reproducibility: identical noise for same seed. |
| `tests/test_full_system.m` | System-level Integration | - Noise-free pipeline: $\text{BER} = 0$, reconstructed audio equals quantizer output.<br>- Noisy pipeline: produces finite metrics.<br>- 0..10 dB sweep: 11 monotonically decreasing BER points.<br>- 10-second stress test: 80,000 samples $\times$ 8 bits = 640k info bits $\rightarrow$ 1.28M coded bits $\rightarrow$ 640k symbols under $1.0$ second. |
| `tests/run_all_tests.m` | Master Test Runner | - Executes all 6 test modules, measures wall-clock execution time, prints summary table, and returns overall boolean status. |

---

## 3. Execution Commands

From the project root directory:

```bash
# Terminal execution
LC_ALL=C.UTF-8 matlab -batch "addpath(genpath(pwd)); run_all_tests;"
```

Or from within the MATLAB Command Window:

```matlab
addpath(genpath(pwd));
run_all_tests
```

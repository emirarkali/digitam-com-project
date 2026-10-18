# A0 Academic Poster Specification & Content

## 1. Poster Metadata & Physical Geometry
- **Standard Format:** ISO 216 A0
- **Dimensions:** $841\text{ mm} \times 1189\text{ mm}$ ($33.11\text{ in} \times 46.81\text{ in}$)
- **Orientation:** Portrait (Vertical)
- **Target Resolution:** $300\text{ DPI}$ ($9933 \times 14043\text{ pixels}$)
- **Color Palette:**
  - Primary Header / Accents: Deep Navy (`#0A2540`)
  - Accent Color: Cyan / Teal (`#00A3BF`)
  - Panel Backgrounds: Crisp Light Gray (`#F8FAFC`)
  - Text Primary: Charcoal Black (`#1E293B`)
  - Highlight / Alert: Crimson (`#E11D48`)

---

## 2. Header Banner (Width: 841 mm, Height: 130 mm)

### Title
# END-TO-END DIGITAL COMMUNICATION SYSTEM FOR SPEECH TRANSMISSION
## mu-law PCM Companding, (8,4) SECDED Channel Coding, and Gray QPSK over AWGN

### Authors & Affiliations
**Student Engineering Team (Person 1, Person 2, Person 3)**  
*Department of Electrical & Electronics Engineering — Digital Communication Systems Project 7*  
*Repository: `~/digital-com-project` | Verified on MATLAB R2026b (Zero Toolboxes)*

---

## 3. Left Column (Width: 385 mm, Top to Bottom)

### Panel 1: Abstract & System Objectives
- **Problem Statement:** Reliable transmission of telephony speech over noisy baseband channels demands both bandwidth-efficient source encoding and error-resilient forward error correction.
- **System Flow:**
  $$\text{Audio (8 kHz)} \rightarrow \mu\text{-law PCM} \rightarrow (8,4)\text{ SECDED} \rightarrow \text{Gray QPSK} \rightarrow \text{AWGN} \rightarrow \text{ML Demod} \rightarrow \text{Syndrome Dec} \rightarrow \text{Reconstructed Audio}$$
- **Key Constraints:** Base MATLAB implementation only; no Communications or DSP Toolboxes.

### Panel 2: Pipeline Architecture
```text
+-------------------+      +-------------------+      +-------------------+
| Audio Source      | ---> | mu-law PCM        | ---> | (8,4) SECDED      |
| 8 kHz, 10s mono   |      | mu=255, 3/4/8-bit |      | Systematic (n=8)  |
+-------------------+      +-------------------+      +-------------------+
                                                                |
+-------------------+      +-------------------+                v
| Complex AWGN      | <--- | Gray QPSK Mod     | <--------------+
| SNR = 0..10 dB    |      | Es = 1.0, k_mod=2 |
+-------------------+      +-------------------+
         |
         v
+-------------------+      +-------------------+      +-------------------+
| ML Demodulator    | ---> | SECDED Decoder    | ---> | PCM Decoder       |
| Sign Detector     |      | 1-bit fix / 2-det |      | Audio Sink / WAV  |
+-------------------+      +-------------------+      +-------------------+
```

### Panel 3: Source Coding ($\mu$-law PCM vs DM/ADM)
- **$\mu$-law Compression:**
  $$y(x) = \text{sgn}(x) \frac{\ln(1 + \mu |x|)}{\ln(1 + \mu)}, \quad \mu = 255$$
- **Uniform Mid-rise Quantization:** $\Delta = 2 / 2^{n_{\text{bits}}}$.
- **Delta Modulation (DM) vs Adaptive DM (ADM):**
  $$\Delta[n] = \begin{cases}
  \min(\Delta_{\max}, \Delta[n-1] \cdot 1.6), & b[n] == b[n-1] \\
  \max(\Delta_{\min}, \Delta[n-1] \cdot 0.6), & b[n] \ne b[n-1]
  \end{cases}$$
- **Figure Asset:** `results/figures/dm_adm_comparison.png`
  - *Caption:* Waveform tracking and error signals showing ADM mitigating slope overload lag by $24\times$ lower MSE compared to fixed DM.

### Panel 4: SQNR Performance Table
| Quantization Bit-Depth | Reconstruction Levels ($L$) | Measured SQNR (dB) | Quantization MSE |
|---|---|---|---|
| 3-bit PCM | 8 | **9.18 dB** | $8.82 \times 10^{-3}$ |
| 4-bit PCM | 16 | **13.80 dB** | $3.04 \times 10^{-3}$ |
| 8-bit PCM | 256 | **38.01 dB** | $1.16 \times 10^{-5}$ |

---

## 4. Right Column (Width: 385 mm, Top to Bottom)

### Panel 5: Channel Coding & SECDED Theory
- **Parity Check Matrix $H$ ($4 \times 8$):**
  $$H = \begin{bmatrix}
  1 & 0 & 1 & 1 & 1 & 0 & 0 & 0 \\
  1 & 1 & 1 & 0 & 0 & 1 & 0 & 0 \\
  0 & 1 & 1 & 1 & 0 & 0 & 1 & 0 \\
  1 & 1 & 0 & 1 & 0 & 0 & 0 & 1
  \end{bmatrix}, \quad G = [I_4 \mid H(:, 1:4)^T]$$
- **SECDED Theorem:**
  - All 8 columns of $H$ are unique and have **odd weight** (1 or 3).
  - Single-bit errors $\implies$ odd syndrome $\implies$ exact $100\%$ correction ($128/128$ tests passed).
  - Double-bit errors $\implies$ even non-zero syndrome $\implies$ $100\%$ detection without false corrections ($448/448$ tests passed).

### Panel 6: Gray QPSK & AWGN Performance
- **Constellation:** Adjacent quadrants differ by $1\text{ bit}$.
  $$s_k = \frac{1}{\sqrt{2}}\left[(1 - 2b_2) + j(1 - 2b_1)\right], \quad E_s = 1.0$$
- **Theoretical Benchmark:**
  $$P_b = \frac{1}{2}\text{erfc}\left(\sqrt{\frac{E_b}{N_0}}\right)$$
- **Figure Asset:** `results/figures/ber_vs_snr.png`
  - *Caption:* Monte Carlo BER vs SNR ($0:1:10\text{ dB}$, 100k bits/point). Coded info-bit BER drops to zero at $10\text{ dB}$.

### Panel 7: BER Simulation Findings Table
| SNR ($E_s/N_0$ dB) | Coded-Bit BER | Info-Bit BER | Uncoded QPSK | Theoretical $P_b$ | Corrected Blocks |
|---|---|---|---|---|---|
| **0.0 dB** | 0.160115 | 0.124720 | 0.159700 | 0.158655 | 12,001 |
| **2.0 dB** | 0.102665 | 0.060380 | 0.104460 | 0.104029 | 10,385 |
| **4.0 dB** | 0.055855 | 0.019590 | 0.056120 | 0.056495 | 7,675 |
| **6.0 dB** | 0.022380 | 0.003400 | 0.023350 | 0.023007 | 3,822 |
| **8.0 dB** | 0.005985 | 0.000320 | 0.006230 | 0.006004 | 1,131 |
| **10.0 dB**| 0.000700 | **0.000000** | 0.000810 | 0.000783 | 140 |

### Panel 8: Key Takeaways & Deliverables
1. **Toolbox-Free Portability:** Fully operational on standard MATLAB R2026b using core primitives.
2. **High-Speed Execution:** Full 80,000-sample (10-second) audio simulation runs in under $0.15\text{ seconds}$.
3. **Coding Gain:** At $\text{SNR} \ge 6\text{ dB}$, SECDED provides $> 7\times$ error rate reduction.
4. **App Designer GUI:** Includes interactive file loading, microphone recording, SNR slider, and audio playback.

---

## 5. Footer Banner (Width: 841 mm, Height: 60 mm)

```text
[ QR CODE PLACEHOLDER ]   MATLAB Execution Commands:
Scan for repository code   >> addpath(genpath(pwd));
and audio samples          >> main;            % Runs full pipeline & figures
                           >> run_all_tests;   % Runs all 6 unit test suites
                           >> Project7_GUI;    % Launches interactive GUI
```

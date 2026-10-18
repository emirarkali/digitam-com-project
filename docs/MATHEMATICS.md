# Mathematical Foundations — Project 7 Digital Communication System

## 1. Non-linear Companding & $\mu$-law PCM

### 1.1 Compression Characteristic
Human hearing exhibits a logarithmic loudness perception. Standard $\mu$-law companding (ITU-T Recommendation G.711) dynamically compresses speech signals so that low-amplitude passages receive finer quantization resolution than high-amplitude peaks.

For a normalized audio input $x \in [-1.0, +1.0]$, the compressed signal $y(x)$ with companding parameter $\mu = 255$ is defined by:
$$y(x) = \text{sgn}(x) \frac{\ln(1 + \mu |x|)}{\ln(1 + \mu)}$$

Properties:
- For $x = 0$: $y(0) = 0$.
- For $|x| = 1$: $y(\pm 1) = \pm 1$.
- Differentiating with respect to $|x|$ gives the companding slope:
  $$\frac{dy}{d|x|} = \frac{\mu}{(1 + \mu |x|) \ln(1 + \mu)}$$
  Near $|x| \approx 0$, the slope is $\frac{\mu}{\ln(1 + \mu)} \approx \frac{255}{\ln(256)} \approx 45.98$, providing an effective gain of $\approx 33\text{ dB}$ for whisper-level audio.

### 1.2 Inverse $\mu$-law Expansion
Given a reconstructed value $\hat{y} \in [-1.0, +1.0]$, the linear signal $\hat{x}$ is restored by inverting the companding equation:
$$\hat{x}(\hat{y}) = \text{sgn}(\hat{y}) \frac{(1 + \mu)^{|\hat{y}|} - 1}{\mu}$$

### 1.3 Uniform Mid-rise Quantization
The compressed domain $y \in [-1.0, +1.0]$ is partitioned into $L = 2^{n_{\text{bits}}}$ uniform quantization intervals.
- Quantization step size:
  $$\Delta = \frac{2}{L} = \frac{2}{2^{n_{\text{bits}}}}$$
- For a mid-rise quantizer, the $k$-th bin ($k \in \{0, 1, \dots, L-1\}$) spans:
  $$I_k = \left[-1 + k\Delta, \; -1 + (k+1)\Delta\right)$$
- The integer quantization index $q$ is computed as:
  $$q = \text{clamp}\left(\left\lfloor \frac{y + 1}{\Delta} \right\rfloor, 0, L-1\right) = \text{clamp}\left(\left\lfloor \frac{(y + 1) L}{2} \right\rfloor, 0, L-1\right)$$
- The reconstruction level $\hat{y}$ is placed at the exact bin midpoint to minimize mean square error:
  $$\hat{y}_q = -1 + \left(q + \frac{1}{2}\right) \Delta$$

### 1.4 Signal-to-Quantization-Noise Ratio (SQNR)
For an input signal $s[n]$ and its quantized version $\hat{s}[n]$, the error sequence is $e[n] = s[n] - \hat{s}[n]$. The average signal and noise powers are:
$$P_{\text{sig}} = \frac{1}{N}\sum_{n=1}^N s[n]^2, \quad P_{\text{err}} = \frac{1}{N}\sum_{n=1}^N \left(s[n] - \hat{s}[n]\right)^2$$
$$\text{SQNR}_{\text{dB}} = 10 \log_{10}\left(\frac{P_{\text{sig}}}{P_{\text{err}}}\right)$$

For uniform quantization of an uncompressed full-scale sinusoid, theoretical SQNR is:
$$\text{SQNR}_{\text{uniform}} \approx 6.02 \cdot n_{\text{bits}} + 1.76 \text{ dB}$$
With $\mu$-law companding on speech signals with varying dynamic ranges, the measured SQNR is nearly invariant across a 30 dB input dynamic range, yielding $\approx 10\text{ dB}$ (3-bit), $\approx 15\text{ dB}$ (4-bit), and $\approx 38\text{ dB}$ (8-bit).

---

## 2. Linear Block Codes & $(8,4)$ SECDED Theory

### 2.1 Code Definition & Orthogonality
A linear block code $(n, k)$ maps a $k$-bit message vector $m \in \{0, 1\}^k$ to an $n$-bit codeword $c \in \{0, 1\}^n$ via a generator matrix $G \in \{0, 1\}^{k \times n}$:
$$c = m \cdot G \pmod 2$$

For the specified $(8,4)$ code, $k = 4$, $n = 8$, code rate $R_c = 4/8 = 1/2$. The parity-check matrix $H \in \{0, 1\}^{4 \times 8}$ is:
$$H = \begin{bmatrix}
1 & 0 & 1 & 1 & 1 & 0 & 0 & 0 \\
1 & 1 & 1 & 0 & 0 & 1 & 0 & 0 \\
0 & 1 & 1 & 1 & 0 & 0 & 1 & 0 \\
1 & 1 & 0 & 1 & 0 & 0 & 0 & 1
\end{bmatrix} = \left[ P^T \mid I_4 \right]$$
where $P^T = H(:, 1:4) \in \{0,1\}^{4 \times 4}$.

The systematic generator matrix $G$ is constructed as:
$$G = \left[ I_4 \mid P \right] = \begin{bmatrix}
1 & 0 & 0 & 0 & 1 & 1 & 0 & 1 \\
0 & 1 & 0 & 0 & 0 & 1 & 1 & 1 \\
0 & 0 & 1 & 0 & 1 & 1 & 1 & 0 \\
0 & 0 & 0 & 1 & 1 & 0 & 1 & 1
\end{bmatrix}$$

**Orthogonality Proof:**
$$G \cdot H^T = \left[ I_4 \mid P \right] \cdot \begin{bmatrix} P \\ I_4 \end{bmatrix} = I_4 P + P I_4 = P + P \equiv 0 \pmod 2$$
Therefore, for any valid message $m$, the codeword $c = mG$ satisfies:
$$c \cdot H^T = m \cdot (G \cdot H^T) \equiv 0 \pmod 2$$

### 2.2 SECDED Syndrome Properties
Let $r = c \oplus e$ be the received vector, where $e \in \{0, 1\}^8$ is the error vector. The syndrome vector $S \in \{0, 1\}^{1 \times 4}$ is:
$$S = r \cdot H^T = (c \oplus e) \cdot H^T = c H^T \oplus e H^T = 0 \oplus e H^T = e \cdot H^T \pmod 2$$

Key Structural Property of $H$:
Let $h_j = H(:, j)$ denote the $j$-th column of $H$ ($j = 1, \dots, 8$).
Inspection reveals:
- $h_1 = [1, 1, 0, 1]^T$ (weight 3)
- $h_2 = [0, 1, 1, 1]^T$ (weight 3)
- $h_3 = [1, 1, 1, 0]^T$ (weight 3)
- $h_4 = [1, 0, 1, 1]^T$ (weight 3)
- $h_5 = [1, 0, 0, 0]^T$ (weight 1)
- $h_6 = [0, 1, 0, 0]^T$ (weight 1)
- $h_7 = [0, 0, 1, 0]^T$ (weight 1)
- $h_8 = [0, 0, 0, 1]^T$ (weight 1)

**Theorem (SECDED Classification):**
1. **Zero Error ($e = 0$):**
   $S = [0, 0, 0, 0]^T$ (weight 0).
2. **Single-Bit Error ($w(e) = 1$ at position $j$):**
   $S = h_j$. Since every column $h_j$ has **odd weight** (1 or 3), $w(S) \in \{1, 3\}$. Furthermore, because all 8 columns of $H$ are distinct, $S$ uniquely identifies the erroneous bit index $j$. The error is corrected by flipping $r_j \leftarrow 1 - r_j$.
3. **Double-Bit Error ($w(e) = 2$ at positions $j_1 \ne j_2$):**
   $S = h_{j_1} \oplus h_{j_2}$. Because the modulo-2 sum of two odd-weight vectors has **even weight**:
   $$w(h_{j_1} \oplus h_{j_2}) \equiv w(h_{j_1}) + w(h_{j_2}) - 2 w(h_{j_1} \cap h_{j_2}) \equiv \text{odd} + \text{odd} - \text{even} \equiv \text{even}$$
   Since $j_1 \ne j_2$ and all columns are distinct, $S \ne 0$, meaning $w(S) \in \{2, 4\}$.
   Consequently, **no double-bit error can produce an odd-weight syndrome**. It can never match any column of $H$. Thus, double-bit errors are unambiguously detected without false correction.
4. **Triple-Bit Error ($w(e) = 3$):**
   Odd + odd + odd = odd weight syndrome. A 3-bit error produces an odd syndrome that matches an incorrect column, resulting in miscorrection (the fundamental limit of $d_{\min} = 4$).

---

## 3. Gray QPSK Modulation and Coherent Detection

### 3.1 Signal Constellation
QPSK maps pairs of bits $(b_1, b_2)$ to a complex symbol $s = I + j Q$. To minimize bit error rate, adjacent constellation points differ by exactly 1 bit (Gray coding):

| Bits $(b_1 b_2)$ | Quadrant | In-Phase $I$ | Quadrature $Q$ | Complex Symbol $s$ |
|---|---|---|---|---|
| `0 0` | 1 ($I>0, Q>0$) | $+1/\sqrt{2}$ | $+1/\sqrt{2}$ | $(+1 + j)/\sqrt{2}$ |
| `0 1` | 2 ($I<0, Q>0$) | $-1/\sqrt{2}$ | $+1/\sqrt{2}$ | $(-1 + j)/\sqrt{2}$ |
| `1 1` | 3 ($I<0, Q<0$) | $-1/\sqrt{2}$ | $-1/\sqrt{2}$ | $(-1 - j)/\sqrt{2}$ |
| `1 0` | 4 ($I>0, Q<0$) | $+1/\sqrt{2}$ | $-1/\sqrt{2}$ | $(+1 - j)/\sqrt{2}$ |

Symbol Energy:
$$E_s = |s|^2 = I^2 + Q^2 = \left(\frac{\pm 1}{\sqrt{2}}\right)^2 + \left(\frac{\pm 1}{\sqrt{2}}\right)^2 = \frac{1}{2} + \frac{1}{2} = 1.0$$

### 3.2 Maximum Likelihood Decision
Under AWGN, the ML decision rule selects the constellation point $s_k$ minimizing Euclidean distance $|r - s_k|^2$.
Because the Gray constellation is symmetric and axis-aligned, the decision decomposes into two independent one-dimensional sign tests:
$$b_1 = \begin{cases} 0, & \text{Im}(r) \ge 0 \\ 1, & \text{Im}(r) < 0 \end{cases}, \quad
  b_2 = \begin{cases} 0, & \text{Re}(r) \ge 0 \\ 1, & \text{Re}(r) < 0 \end{cases}$$

---

## 4. Complex AWGN Channel and SNR Relations

### 4.1 Channel Model
The received baseband symbol is:
$$r = s + w$$
where $w = w_I + j w_Q$ with independent components $w_I, w_Q \sim \mathcal{N}(0, \sigma^2)$. Total noise variance per complex symbol is:
$$\mathbb{E}[|w|^2] = \mathbb{E}[w_I^2] + \mathbb{E}[w_Q^2] = 2\sigma^2 = N_0 \implies \sigma = \sqrt{\frac{N_0}{2}}$$

### 4.2 SNR Definitions and Energy Bookkeeping
- **Symbol SNR ($E_s/N_0$):**
  $$\text{SNR}_{\text{EsN0, dB}} = 10 \log_{10}\left(\frac{E_s}{N_0}\right) \implies N_0 = \frac{E_s}{10^{\text{SNR}_{\text{dB}}/10}}$$
- **Information-Bit SNR ($E_b/N_0$):**
  Each symbol carries $k_{\text{mod}} = 2$ coded bits. With channel code rate $R_c$, each symbol represents $k_{\text{info}} = k_{\text{mod}} \cdot R_c$ information bits. Thus:
  $$E_s = (k_{\text{mod}} \cdot R_c) E_{b,\text{info}}$$
  $$\frac{E_s}{N_0} = (k_{\text{mod}} \cdot R_c) \frac{E_{b,\text{info}}}{N_0}$$
  - For the **$(8,4)$ Coded System** ($k_{\text{mod}} = 2, R_c = 1/2$):
    $$k_{\text{mod}} \cdot R_c = 2 \cdot \frac{1}{2} = 1.0 \implies \frac{E_s}{N_0} = \frac{E_{b,\text{info}}}{N_0}$$
    Symbol SNR and information-bit SNR are numerically identical in dB.
  - For **Uncoded QPSK** ($k_{\text{mod}} = 2, R_c = 1.0$):
    $$\frac{E_s}{N_0} = 2 \frac{E_b}{N_0} \implies \left(\frac{E_s}{N_0}\right)_{\text{dB}} = \left(\frac{E_b}{N_0}\right)_{\text{dB}} + 3.01 \text{ dB}$$

### 4.3 Theoretical Uncoded QPSK BER
The exact bit error probability for uncoded Gray QPSK over AWGN is:
$$P_b = Q\left(\sqrt{\frac{2 E_b}{N_0}}\right) = \frac{1}{2} \text{erfc}\left(\sqrt{\frac{E_b}{N_0}}\right)$$

---

## 5. Delta Modulation (DM) vs Adaptive Delta Modulation (ADM)

### 5.1 Linear Delta Modulation
In fixed-step DM with step $\Delta$, the predicted signal accumulator is updated as:
$$e[n] = x[n] - \hat{x}[n-1]$$
$$b[n] = \begin{cases} 1, & e[n] \ge 0 \\ 0, & e[n] < 0 \end{cases}$$
$$\hat{x}[n] = \hat{x}[n-1] + (2 b[n] - 1)\Delta$$

- **Slope Overload:** Occurs whenever the signal derivative exceeds the maximum tracking slope:
  $$\left|\frac{dx}{dt}\right| > \frac{\Delta}{T_s} = \Delta \cdot F_s$$
- **Granular Noise:** Occurs in flat regions where the step size $\Delta$ causes continuous hunting between adjacent levels.

### 5.2 Adaptive Delta Modulation (ADM)
ADM dynamically scales the step size $\Delta[n]$ based on consecutive bit patterns:
$$\Delta[n] = \begin{cases}
\min(\Delta_{\max}, \; \Delta[n-1] \cdot \alpha), & b[n] == b[n-1] \quad (\text{slope overload: expand}) \\
\max(\Delta_{\min}, \; \Delta[n-1] \cdot \beta), & b[n] \ne b[n-1] \quad (\text{granular hunting: contract})
\end{cases}$$
Typical parameters: $\alpha = 1.5, \beta = 0.6, \Delta_{\min} = 0.005, \Delta_{\max} = 0.25$.
This non-linear adaptation significantly reduces slope overload lag while maintaining fine granular precision in flat segments.

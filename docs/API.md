# API Reference — Project 7 Digital Communication System

This document outlines all public function interfaces, signatures, input/output structures, units, data conventions, and usage examples.

---

## 1. Audio Processing & Delta Modulation (`src/person1_audio/`)

### `audio_input`
Acquires audio from file, synthesis, or microphone, handles mono conversion, resampling, and dynamic range normalization.

```matlab
[audio, fs, metadata] = audio_input(source, fsTarget, durationSec)
```
- **Inputs:**
  - `source` (`char|string|numeric`): Filepath string to WAV, `'synthetic'` / `'sine'` (default), `'mic'` for live microphone, or direct numeric array.
  - `fsTarget` (`double`): Target sampling frequency in Hz (default: `8000`).
  - `durationSec` (`double`): Desired duration in seconds (default: `10.0`).
- **Outputs:**
  - `audio` (`N x 1 double`): Column vector normalized to $[-1.0, +1.0]$.
  - `fs` (`double`): Output sampling rate (equals `fsTarget`).
  - `metadata` (`struct`): Contains `sourceType`, `originalFs`, `originalNumSamples`, `peakScale`, and `filePath`.
- **Example:**
  ```matlab
  [aud, fs, meta] = audio_input('data/input/speech.wav', 8000, 10);
  ```

---

### `pcm_encoder`
Applies $\mu$-law compression and uniform mid-rise quantization.

```matlab
[bits, pcmMeta, quantizedSignal] = pcm_encoder(audio, nBits, mu)
```
- **Inputs:**
  - `audio` (`N x 1 double`): Audio samples bounded in $[-1.0, 1.0]$.
  - `nBits` (`double`): Quantizer bit depth $\in \{3, 4, 8\}$ (default: `8`).
  - `mu` (`double`): Companding factor (default: `255`).
- **Outputs:**
  - `bits` (`(N*nBits) x 1 double`): Serialized binary bits ($0$ or $1$, MSB first).
  - `pcmMeta` (`struct`): Quantizer metadata (`nBits`, `mu`, `L`, `delta`, `numSamples`, `numBits`).
  - `quantizedSignal` (`N x 1 double`): Quantized audio signal reconstructed in linear domain.
- **Example:**
  ```matlab
  [bits, pcmMeta, qSig] = pcm_encoder(aud, 8, 255);
  ```

---

### `pcm_decoder`
Decodes binary bitstream back into linear audio samples.

```matlab
[reconstructedAudio, recoveredLevels] = pcm_decoder(bits, pcmMeta)
```
- **Inputs:**
  - `bits` (`vector double`): Bitstream column vector of $0$s and $1$s. Length must be a multiple of `pcmMeta.nBits`.
  - `pcmMeta` (`struct`): Configuration struct from `pcm_encoder`.
- **Outputs:**
  - `reconstructedAudio` (`N x 1 double`): Decompressed audio vector in linear domain.
  - `recoveredLevels` (`N x 1 double`): Quantizer bin indices $q \in [0, L-1]$.

---

### `calculate_sqnr`
Computes Signal-to-Quantization-Noise Ratio in decibels.

```matlab
sqnrDB = calculate_sqnr(referenceAudio, reconstructedAudio)
```
- **Inputs:**
  - `referenceAudio` (`vector double`): Ground truth signal.
  - `reconstructedAudio` (`vector double`): Approximated or recovered signal.
- **Output:**
  - `sqnrDB` (`double`): SQNR in dB ($10 \log_{10}(P_{\text{sig}} / P_{\text{err}})$). Returns `Inf` for zero error.

---

### `dm_encoder` & `dm_decoder`
Linear Delta Modulation encoder and decoder.

```matlab
[bits, reconstructedSignal, state] = dm_encoder(signal, delta, initialVal)
reconstructedSignal = dm_decoder(bits, delta, initialVal)
```
- **Inputs:** `signal` (`N x 1 double`), `delta` (`double`, step size, default `0.05`), `initialVal` (`double`, default `0.0`).
- **Outputs:** `bits` (`N x 1 double`), `reconstructedSignal` (`N x 1 double`).

---

### `adm_encoder` & `adm_decoder`
Adaptive Delta Modulation with geometric step-size expansion and contraction.

```matlab
[bits, reconstructedSignal, state] = adm_encoder(signal, delta0, deltaMin, deltaMax, initialVal, alpha, beta)
reconstructedSignal = adm_decoder(bits, delta0, deltaMin, deltaMax, initialVal, alpha, beta)
```
- **Inputs:**
  - `delta0`: Initial step size (default: `0.02`).
  - `deltaMin`, `deltaMax`: Step clamping boundaries (defaults: `0.005`, `0.25`).
  - `alpha`: Expansion factor when $b[n] == b[n-1]$ (default: `1.5`).
  - `beta`: Contraction factor when $b[n] \ne b[n-1]$ (default: `0.6`).

---

## 2. Channel Coding (`src/person2_channel_coding/`)

### `generate_matrices`
Generates generator matrix $G$ ($4 \times 8$) and parity-check matrix $H$ ($4 \times 8$).

```matlab
[G, H] = generate_matrices()
```
- **Outputs:**
  - `G` (`4x8 double`): Systematic generator matrix $[I_4 \mid P]$.
  - `H` (`4x8 double`): Parity-check matrix $[P^T \mid I_4]$.

---

### `channel_encoder`
Encodes information bits into $(8,4)$ systematic block codewords.

```matlab
[encodedBits, padInfo] = channel_encoder(infoBits, G)
```
- **Inputs:**
  - `infoBits` (`vector double`): Binary information bits.
  - `G` (`4x8 double`, optional): Generator matrix.
- **Outputs:**
  - `encodedBits` (`N_coded x 1 double`): Codeword bitstream.
  - `padInfo` (`struct`): Records `originalLength`, `numPad`, `k=4`, `n=8`.

---

### `channel_decoder`
Performs syndrome-based Single Error Correction, Double Error Detection (SECDED).

```matlab
[decodedBits, decodeStats] = channel_decoder(receivedBits, H, padInfo)
```
- **Inputs:**
  - `receivedBits` (`vector double`): Received coded bits (multiple of 8).
  - `H` (`4x8 double`, optional): Parity-check matrix.
  - `padInfo` (`struct`, optional): Removes zero-padding if provided.
- **Outputs:**
  - `decodedBits` (`N_info x 1 double`): Reconstructed information bits.
  - `decodeStats` (`struct`): Error statistics (`numBlocks`, `noErrorBlocks`, `singleErrorCorrected`, `doubleErrorDetected`, `blockStatus`).

---

## 3. Modulation & Channel (`src/person3_modulation/`)

### `qpsk_mod`
Gray-coded QPSK modulator with unit symbol energy ($E_s = 1.0$).

```matlab
txSymbols = qpsk_mod(bits)
```
- **Input:** `bits` (`N x 1 double`): Binary bitstream ($0$ and $1$).
- **Output:** `txSymbols` (`(N/2) x 1 complex double`): Baseband QPSK symbols on the unit circle.

---

### `qpsk_demod`
Maximum Likelihood (nearest-neighbor) Gray QPSK demodulator.

```matlab
[rxBits, detectedSymbols] = qpsk_demod(rxSymbols)
```
- **Input:** `rxSymbols` (`N_sym x 1 complex double`): Received complex symbols.
- **Outputs:**
  - `rxBits` (`(2*N_sym) x 1 double`): Demodulated binary bits.
  - `detectedSymbols` (`N_sym x 1 complex double`): Closest constellation points.

---

### `add_awgn`
Adds complex white Gaussian noise with precise variance partitioning.

```matlab
[rxSymbols, channelMeta] = add_awgn(txSymbols, snrDB, snrDefinition, codeRate)
```
- **Inputs:**
  - `txSymbols` (`N_sym x 1 complex double`): Transmitted symbols.
  - `snrDB` (`double`): SNR in dB.
  - `snrDefinition` (`char`): `'EsN0'` (default) or `'EbN0'`.
  - `codeRate` (`double`): Code rate $R_c$ (default: `0.5`).
- **Outputs:**
  - `rxSymbols` (`N_sym x 1 complex double`): Noisy symbols.
  - `channelMeta` (`struct`): Noise parameters ($N_0$, $\sigma$, measured SNR).

---

### `calculate_ber`
Computes Bit Error Rate between reference and received bitstreams.

```matlab
[ber, numErrors, totalBits] = calculate_ber(referenceBits, receivedBits)
```

---

### `ber_simulation`
Executes Monte Carlo BER simulation over a range of SNRs.

```matlab
results = ber_simulation(config)
```
- **Config fields:** `snrRange` (`0:1:10`), `snrDefinition` (`'EsN0'`), `numBitsPerSNR`, `seed`, `verbose`.

---

## 4. Integration & GUI

### `run_full_system`
End-to-end execution of the full communication pipeline.

```matlab
results = run_full_system(config)
```

### `Project7_GUI`
Launches the interactive MATLAB App GUI.

```matlab
fig = Project7_GUI()
```

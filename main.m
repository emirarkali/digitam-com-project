%% PROJECT 7 - COMPLETE DIGITAL COMMUNICATION SYSTEM
% End-to-end Pipeline Demonstration & Performance Sweep
%
% Architecture:
%   Audio Source -> mu-law PCM -> (8,4) Channel Encoder -> Gray QPSK ->
%   Complex AWGN -> ML Demodulator -> SECDED Decoder -> PCM Reconstruction
%
% Authors:
%   Person 1: Audio Processing, mu-law PCM, Quantization, SQNR, DM/ADM
%   Person 2: Parity Check / Generator Matrices, SECDED Channel Coding
%   Person 3: QPSK Modulation, Complex AWGN Channel, Demodulation, BER Simulation

clear;
clc;
close all;

% Ensure all project subdirectories are on the MATLAB path
projectRoot = fileparts(mfilename('fullpath'));
if isempty(projectRoot)
    projectRoot = pwd;
end
addpath(genpath(projectRoot));

fprintf('=================================================================\n');
fprintf('     PROJECT 7: DIGITAL COMMUNICATION SYSTEM DEMONSTRATION       \n');
fprintf('=================================================================\n\n');

%% 1. Configuration & Parameters
config = struct();
config.fsTarget = 8000;         % 8 kHz standard audio rate
config.durationSec = 2.0;       % 2.0 seconds demo (set to 10 for full 10-sec audio)
config.pcmBits = 8;             % 8-bit uniform quantization in mu-law domain
config.mu = 255;                % Standard mu-law parameter
config.snrDB = 6.0;             % Channel SNR for single-run demonstration (dB)
config.snrDefinition = 'EsN0';  % 'EsN0' or 'EbN0'
config.seed = 42;               % Reproducibility seed

% Look for course/user WAV file in data/input/, otherwise default to synthetic
wavFiles = dir(fullfile(projectRoot, 'data', 'input', '*.wav'));
if ~isempty(wavFiles)
    chosenFile = fullfile(wavFiles(1).folder, wavFiles(1).name);
    fprintf('Loading input audio file: %s\n', chosenFile);
    config.source = chosenFile;
else
    fprintf('No WAV files found in data/input/. Using deterministic synthetic speech audio.\n');
    config.source = 'synthetic';
end

%% 2. Run Single End-to-End Transmission Pipeline
fprintf('\n--- Phase 1: End-to-End Pipeline Execution (SNR = %.1f dB) ---\n', config.snrDB);
tPipeline = tic;
results = run_full_system(config);
tPipelineElapsed = toc(tPipeline);

fprintf('Pipeline completed in %.3f seconds.\n', tPipelineElapsed);
fprintf('Input samples:       %d (Fs = %d Hz, Duration = %.2f s)\n', ...
        length(results.audioIn), results.fs, length(results.audioIn) / results.fs);
fprintf('PCM Information bits: %d (%d bits/sample)\n', length(results.pcmBits), config.pcmBits);
fprintf('Quantization SQNR:   %.2f dB\n', results.sqnrQuantOnly);
fprintf('Coded bits:          %d (Rate R = 1/2, (8,4) SECDED block code)\n', length(results.codedBits));
fprintf('QPSK Transmitted:    %d complex symbols (Es = %.2f)\n', ...
        length(results.txSymbols), mean(abs(results.txSymbols).^2));
fprintf('Channel AWGN SNR:    %.1f dB (%s)\n', config.snrDB, config.snrDefinition);
fprintf('Coded-Bit BER:       %.5e (%d / %d bit errors)\n', ...
        results.berCodedBits, results.errCodedBits, results.totalCodedBits);
fprintf('Decoded Info-Bit BER:%.5e (%d / %d bit errors)\n', ...
        results.berInfoBits, results.errInfoBits, results.totalInfoBits);
fprintf('SECDED Corrections:  %d blocks corrected, %d uncorrectable blocks detected\n', ...
        results.decodeStats.singleErrorCorrected, results.decodeStats.doubleErrorDetected);
fprintf('End-to-End SQNR:     %.2f dB\n', results.sqnrEndToEnd);

% Save reconstructed audio to data/output/
outDir = fullfile(projectRoot, 'data', 'output');
if ~exist(outDir, 'dir'), mkdir(outDir); end
outWavPath = fullfile(outDir, 'reconstructed_audio.wav');
try
    audiowrite(outWavPath, results.reconstructedAudio, results.fs);
    fprintf('Saved reconstructed audio to: %s\n', outWavPath);
catch ME
    fprintf('Could not write WAV file (%s)\n', ME.message);
end

%% 3. Monte Carlo BER vs SNR Sweep (0 to 10 dB)
fprintf('\n--- Phase 2: BER vs SNR Sweep Simulation (0:1:10 dB) ---\n');
sweepCfg = struct();
sweepCfg.snrRange = 0:1:10;
sweepCfg.snrDefinition = 'EsN0';
sweepCfg.numBitsPerSNR = 100000; % 100k info bits per SNR point
sweepCfg.seed = 2026;
sweepCfg.verbose = true;

tSweep = tic;
sweepResults = ber_simulation(sweepCfg);
tSweepElapsed = toc(tSweep);
fprintf('BER Sweep finished in %.2f seconds.\n', tSweepElapsed);

%% 4. Export Numeric Results Table to CSV
tableDir = fullfile(projectRoot, 'results', 'tables');
if ~exist(tableDir, 'dir'), mkdir(tableDir); end
csvPath = fullfile(tableDir, 'ber_snr_simulation_results.csv');

fid = fopen(csvPath, 'w');
if fid ~= -1
    fprintf(fid, 'SNR_dB,Coded_Bit_BER,Info_Bit_BER,Uncoded_BER,Theoretical_BER,Corrected_Blocks,Uncorrectable_Blocks\n');
    for k = 1:length(sweepResults.snrRange)
        fprintf(fid, '%.1f,%.6e,%.6e,%.6e,%.6e,%d,%d\n', ...
                sweepResults.snrRange(k), ...
                sweepResults.berCodedBits(k), ...
                sweepResults.berInfoBits(k), ...
                sweepResults.berUncoded(k), ...
                sweepResults.berTheoretical(k), ...
                sweepResults.singleErrorsCorr(k), ...
                sweepResults.doubleErrorsDet(k));
    end
    fclose(fid);
    fprintf('Exported simulation results table to: %s\n', csvPath);
end

%% 5. Generate and Save Publication-Quality Figures
figDir = fullfile(projectRoot, 'results', 'figures');
if ~exist(figDir, 'dir'), mkdir(figDir); end

% Figure 1: Waveforms (Original, Quantized, Reconstructed)
f1 = figure('Name', 'Audio Waveforms', 'Visible', 'off', 'Position', [100 100 900 600]);
tPlot = (0:min(400, length(results.audioIn))-1)' / results.fs * 1000; % ms
plot(tPlot, results.audioIn(1:length(tPlot)), 'b-', 'LineWidth', 1.8, 'DisplayName', 'Original Audio');
hold on;
stairs(tPlot, results.pcmQuantizedAudio(1:length(tPlot)), 'g--', 'LineWidth', 1.2, 'DisplayName', 'PCM Quantized');
plot(tPlot, results.reconstructedAudio(1:length(tPlot)), 'r:', 'LineWidth', 1.5, 'DisplayName', 'Received & Reconstructed');
grid on;
xlabel('Time (ms)', 'FontSize', 12);
ylabel('Normalized Amplitude', 'FontSize', 12);
title(sprintf('Audio Waveforms Comparison (SNR = %.1f dB, SQNR = %.2f dB)', config.snrDB, results.sqnrEndToEnd), ...
      'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 11);
saveas(f1, fullfile(figDir, 'audio_waveforms.png'));
close(f1);

% Figure 2: QPSK Constellation (Clean and Noisy)
f2 = figure('Name', 'QPSK Constellation', 'Visible', 'off', 'Position', [150 150 800 600]);
numPlotSyms = min(2000, length(results.rxSymbols));
scatter(real(results.rxSymbols(1:numPlotSyms)), imag(results.rxSymbols(1:numPlotSyms)), ...
        15, [0.3 0.6 0.9], 'filled', 'MarkerEdgeAlpha', 0.5, 'DisplayName', sprintf('Noisy RX (SNR = %.1f dB)', config.snrDB));
hold on;
constRef = [(1+1j)/sqrt(2), (-1+1j)/sqrt(2), (-1-1j)/sqrt(2), (1-1j)/sqrt(2)];
scatter(real(constRef), imag(constRef), 120, 'r', 'filled', 'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.5, 'DisplayName', 'Ideal Constellation');
xline(0, 'k--', 'Alpha', 0.5);
yline(0, 'k--', 'Alpha', 0.5);
grid on;
axis equal;
xlim([-2 2]); ylim([-2 2]);
xlabel('In-Phase (I)', 'FontSize', 12);
ylabel('Quadrature (Q)', 'FontSize', 12);
title(sprintf('Gray-Mapped QPSK Constellation (Es = 1.0, SNR = %.1f dB)', config.snrDB), ...
      'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 11);
saveas(f2, fullfile(figDir, 'qpsk_constellation.png'));
close(f2);

% Figure 3: BER vs SNR (semilogy)
f3 = figure('Name', 'BER vs SNR Performance', 'Visible', 'off', 'Position', [200 200 900 650]);
% Prepare zero BER upper-bound for log-scale plotting
plotBerCoded = sweepResults.berCodedBits;
plotBerInfo  = sweepResults.berInfoBits;
plotBerUnc   = sweepResults.berUncoded;
plotBerTheo  = sweepResults.berTheoretical;

% Floor zero BER to 1e-6 with marker indication
floorVal = 1e-6;
plotBerCoded(plotBerCoded == 0) = floorVal;
plotBerInfo(plotBerInfo == 0)   = floorVal;
plotBerUnc(plotBerUnc == 0)     = floorVal;

semilogy(sweepResults.snrRange, plotBerCoded, 'b-s', 'LineWidth', 1.8, 'MarkerSize', 8, ...
         'DisplayName', 'Demodulated Coded-Bit BER (before decoding)');
hold on;
semilogy(sweepResults.snrRange, plotBerInfo, 'r-o', 'LineWidth', 2.0, 'MarkerSize', 8, ...
         'DisplayName', 'Decoded Info-Bit BER ((8,4) SECDED Output)');
semilogy(sweepResults.snrRange, plotBerUnc, 'k--^', 'LineWidth', 1.5, 'MarkerSize', 7, ...
         'DisplayName', 'Uncoded QPSK Baseline');
semilogy(sweepResults.snrRange, plotBerTheo, 'm:', 'LineWidth', 2.0, ...
         'DisplayName', 'Theoretical Uncoded QPSK');
grid on;
xlabel('Channel SNR (Es/N0 in dB)', 'FontSize', 12);
ylabel('Bit Error Rate (BER)', 'FontSize', 12);
ylim([5e-7 1.0]);
title('BER vs SNR Performance: (8,4) SECDED Coded vs Uncoded QPSK', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southwest', 'FontSize', 11);
saveas(f3, fullfile(figDir, 'ber_vs_snr.png'));
close(f3);

fprintf('Generated and saved all primary figures in %s\n', figDir);
fprintf('\n=================================================================\n');
fprintf('                DEMONSTRATION COMPLETED SUCCESSFULLY             \n');
fprintf('=================================================================\n');

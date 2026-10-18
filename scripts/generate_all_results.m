%% generate_all_results.m - Automated Generation of Figures and Numerical Tables
% Produces all publication-quality experimental assets required for reports and poster.

clear;
clc;
close all;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if isempty(projectRoot)
    projectRoot = pwd;
end
addpath(genpath(fullfile(projectRoot, 'src')));

figDir = fullfile(projectRoot, 'results', 'figures');
tableDir = fullfile(projectRoot, 'results', 'tables');
if ~exist(figDir, 'dir'), mkdir(figDir); end
if ~exist(tableDir, 'dir'), mkdir(tableDir); end

fprintf('=================================================================\n');
fprintf('       GENERATING EXPERIMENTAL FIGURES & PERFORMANCE TABLES      \n');
fprintf('=================================================================\n\n');

%% 1. SQNR vs Bit Depth Experiment (3, 4, 8 bits)
fprintf('1. Evaluating SQNR vs Bit Depth (3, 4, 8 bits)...\n');
[testAudio, fs, ~] = audio_input('synthetic', 8000, 2.0);

bitDepths = [3, 4, 8];
sqnrValues = zeros(length(bitDepths), 1);
quantMSE = zeros(length(bitDepths), 1);

for i = 1:length(bitDepths)
    nB = bitDepths(i);
    [bits, meta, qSig] = pcm_encoder(testAudio, nB, 255);
    [rec, ~] = pcm_decoder(bits, meta);
    sqnrValues(i) = calculate_sqnr(testAudio, rec);
    quantMSE(i) = mean((testAudio - rec).^2);
    fprintf('   %d-bit PCM: SQNR = %5.2f dB, MSE = %.4e\n', nB, sqnrValues(i), quantMSE(i));
end

% Save SQNR Table
sqnrCsv = fullfile(tableDir, 'sqnr_bitdepth_results.csv');
fid = fopen(sqnrCsv, 'w');
if fid ~= -1
    fprintf(fid, 'Bit_Depth,Levels,Step_Size_Delta,SQNR_dB,Quantization_MSE\n');
    for i = 1:length(bitDepths)
        fprintf(fid, '%d,%d,%.6f,%.2f,%.6e\n', ...
                bitDepths(i), 2^bitDepths(i), 2/(2^bitDepths(i)), sqnrValues(i), quantMSE(i));
    end
    fclose(fid);
    fprintf('   Saved: %s\n', sqnrCsv);
end

% Plot SQNR vs Bit Depth
fSqnr = figure('Name', 'SQNR vs Bit Depth', 'Visible', 'off', 'Position', [100 100 700 500]);
b = bar(categorical({'3-bit (L=8)', '4-bit (L=16)', '8-bit (L=256)'}), sqnrValues, 0.5, 'FaceColor', [0.15 0.45 0.75]);
grid on;
ylabel('Measured SQNR (dB)', 'FontSize', 12);
title('mu-law PCM (mu=255) SQNR vs. Quantization Resolution', 'FontSize', 14, 'FontWeight', 'bold');
ylim([0 48]);
for i = 1:length(sqnrValues)
    text(i, sqnrValues(i) + 1.5, sprintf('%.2f dB', sqnrValues(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
end
saveas(fSqnr, fullfile(figDir, 'sqnr_vs_bitdepth.png'));
close(fSqnr);

%% 2. Delta Modulation (DM) vs Adaptive Delta Modulation (ADM)
fprintf('\n2. Evaluating Linear DM vs Adaptive DM (ADM)...\n');
t = (0:999)' / 8000;
% Multitone signal with steep slopes and flat segments
testSig = 0.7 * sin(2 * pi * 150 * t) + 0.25 * sin(2 * pi * 400 * t);

% Linear DM with fixed step size (demonstrating slope overload)
deltaFixed = 0.02;
[dmBits, dmRec, dmState] = dm_encoder(testSig, deltaFixed, 0);
dmMSE = mean((testSig - dmRec).^2);
dmSQNR = calculate_sqnr(testSig, dmRec);

% ADM with adaptive step size
delta0 = 0.02; deltaMin = 0.005; deltaMax = 0.15;
[admBits, admRec, admState] = adm_encoder(testSig, delta0, deltaMin, deltaMax, 0, 1.6, 0.6);
admMSE = mean((testSig - admRec).^2);
admSQNR = calculate_sqnr(testSig, admRec);

fprintf('   Linear DM (fixed delta=%.3f): MSE = %.4e, SQNR = %5.2f dB\n', deltaFixed, dmMSE, dmSQNR);
fprintf('   Adaptive DM (ADM):            MSE = %.4e, SQNR = %5.2f dB\n', admMSE, admSQNR);

% Save DM/ADM Table
dmCsv = fullfile(tableDir, 'dm_adm_results.csv');
fid = fopen(dmCsv, 'w');
if fid ~= -1
    fprintf(fid, 'Modulation_Type,Step_Min,Step_Max,MSE,SQNR_dB\n');
    fprintf(fid, 'Linear DM,%.4f,%.4f,%.6e,%.2f\n', deltaFixed, deltaFixed, dmMSE, dmSQNR);
    fprintf(fid, 'Adaptive DM (ADM),%.4f,%.4f,%.6e,%.2f\n', deltaMin, deltaMax, admMSE, admSQNR);
    fclose(fid);
    fprintf('   Saved: %s\n', dmCsv);
end

% Plot DM vs ADM Waveforms and Error Signals
fDm = figure('Name', 'DM vs ADM Comparison', 'Visible', 'off', 'Position', [150 150 950 700]);
subplot(2, 1, 1);
tMs = t * 1000;
plot(tMs(1:300), testSig(1:300), 'k-', 'LineWidth', 2.0, 'DisplayName', 'Original Input');
hold on;
plot(tMs(1:300), dmRec(1:300), 'r--', 'LineWidth', 1.3, 'DisplayName', sprintf('Linear DM (SQNR = %.1f dB)', dmSQNR));
plot(tMs(1:300), admRec(1:300), 'b-', 'LineWidth', 1.3, 'DisplayName', sprintf('Adaptive DM (SQNR = %.1f dB)', admSQNR));
grid on;
ylabel('Amplitude', 'FontSize', 11);
title('Waveform Tracking: Linear DM vs Adaptive Delta Modulation (ADM)', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 10);

subplot(2, 1, 2);
errDM = testSig - dmRec;
errADM = testSig - admRec;
plot(tMs(1:300), errDM(1:300), 'r--', 'LineWidth', 1.2, 'DisplayName', 'Linear DM Error (Slope Overload)');
hold on;
plot(tMs(1:300), errADM(1:300), 'b-', 'LineWidth', 1.2, 'DisplayName', 'Adaptive DM Error (Reduced Lag)');
grid on;
xlabel('Time (ms)', 'FontSize', 11);
ylabel('Tracking Error', 'FontSize', 11);
title('Tracking Error Comparison (ADM reduces slope overload lag)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 10);
saveas(fDm, fullfile(figDir, 'dm_adm_comparison.png'));
close(fDm);

fprintf('\nExperimental asset generation finished successfully.\n');

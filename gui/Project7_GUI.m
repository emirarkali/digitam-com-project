function fig = Project7_GUI()
% PROJECT7_GUI Interactive Graphical User Interface for Project 7 Digital Communication System.
%
% Features:
%   - Audio input selection: Synthetic audio, WAV file picker, Microphone recording.
%   - Parameter configuration: PCM bit depth (3, 4, 8 bits), mu=255, SNR (0 to 10 dB).
%   - Simulation actions: Single-run execution, full 0-10 dB BER Monte Carlo sweep.
%   - Visualizations: Audio waveforms, QPSK constellation, BER vs SNR curves, DM/ADM.
%   - Audio playback: Listen to original vs received/reconstructed audio.
%   - Export: Export audio to WAV, simulation results to CSV, figures to PNG.
%
% Syntax:
%   fig = Project7_GUI()
%
% Dependencies:
%   MATLAB base functions only (uifigure, uiaxes, uibutton, etc. No toolboxes).

    % Add paths
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    if isempty(projectRoot)
        projectRoot = pwd;
    end
    addpath(genpath(fullfile(projectRoot, 'src')));

    % Global GUI state container
    guiState = struct();
    guiState.projectRoot = projectRoot;
    guiState.audioSource = 'synthetic';
    guiState.customWavPath = '';
    guiState.fs = 8000;
    guiState.duration = 2.0; % Default 2 seconds for interactive responsiveness
    guiState.pcmBits = 8;
    guiState.mu = 255;
    guiState.snrDB = 6.0;
    guiState.lastResults = [];
    guiState.lastSweepResults = [];
    guiState.playerOrig = [];
    guiState.playerRec = [];

    % Create Main Window
    fig = uifigure('Name', 'Project 7: Digital Communication System (PCM + SECDED + QPSK)', ...
                    'Position', [100 80 1150 720], ...
                    'Color', [0.96 0.97 0.98]);

    % Main 2-column Grid Layout (Left: Controls, Right: Visualizations)
    mainGrid = uigridlayout(fig, [1 2]);
    mainGrid.ColumnWidth = {340, '1x'};
    mainGrid.Padding = [15 15 15 15];
    mainGrid.ColumnSpacing = 15;

    %% ================= LEFT CONTROL PANEL =================
    ctrlPanel = uipanel(mainGrid, 'Title', 'System Controls & Parameters', ...
                        'FontSize', 13, 'FontWeight', 'bold', ...
                        'BackgroundColor', [1 1 1]);
    ctrlGrid = uigridlayout(ctrlPanel, [14 1]);
    ctrlGrid.RowHeight = {30, 32, 28, 30, 28, 30, 36, 36, 32, 32, 32, '1x', 36, 25};
    ctrlGrid.Padding = [10 10 10 10];
    ctrlGrid.RowSpacing = 8;

    % 1. Audio Source Selection
    uilabel(ctrlGrid, 'Text', '1. Audio Input Source:', 'FontWeight', 'bold');
    sourceDropdown = uidropdown(ctrlGrid, ...
        'Items', {'Deterministic Synthetic Speech', 'Select WAV File...', 'Microphone Recording (2s)'}, ...
        'Value', 'Deterministic Synthetic Speech', ...
        'ValueChangedFcn', @onSourceChanged);

    % 2. PCM Quantization Resolution
    uilabel(ctrlGrid, 'Text', '2. PCM Quantization (mu = 255):', 'FontWeight', 'bold');
    pcmDropdown = uidropdown(ctrlGrid, ...
        'Items', {'8-bit Uniform (256 levels)', '4-bit Uniform (16 levels)', '3-bit Uniform (8 levels)'}, ...
        'Value', '8-bit Uniform (256 levels)', ...
        'ValueChangedFcn', @onPcmChanged);

    % 3. Channel SNR Setting
    snrLabel = uilabel(ctrlGrid, 'Text', sprintf('3. Channel SNR: 6.0 dB (Es/N0)'), 'FontWeight', 'bold');
    snrSlider = uislider(ctrlGrid, 'Limits', [0 10], 'Value', 6.0, ...
                         'MajorTicks', 0:1:10, 'MinorTicks', 0:0.5:10, ...
                         'ValueChangedFcn', @onSnrChanged);

    % 4. Simulation Action Buttons
    btnRunSingle = uibutton(ctrlGrid, 'push', 'Text', 'Run Single Simulation', ...
                            'FontWeight', 'bold', 'BackgroundColor', [0.12 0.53 0.90], ...
                            'FontColor', [1 1 1], 'ButtonPushedFcn', @onRunSingle);

    btnRunSweep = uibutton(ctrlGrid, 'push', 'Text', 'Run 0–10 dB BER Sweep', ...
                           'FontWeight', 'bold', 'BackgroundColor', [0.20 0.65 0.35], ...
                           'FontColor', [1 1 1], 'ButtonPushedFcn', @onRunSweep);

    % 5. Audio Playback Buttons
    playGrid = uigridlayout(ctrlGrid, [1 2]);
    playGrid.Padding = [0 0 0 0];
    btnPlayOrig = uibutton(playGrid, 'push', 'Text', 'Play Original', ...
                           'ButtonPushedFcn', @onPlayOrig, 'Enable', 'off');
    btnPlayRec = uibutton(playGrid, 'push', 'Text', 'Play Received', ...
                          'ButtonPushedFcn', @onPlayRec, 'Enable', 'off');

    % 6. Export Options
    exportGrid = uigridlayout(ctrlGrid, [1 2]);
    exportGrid.Padding = [0 0 0 0];
    btnExportAudio = uibutton(exportGrid, 'push', 'Text', 'Export WAV', ...
                             'ButtonPushedFcn', @onExportAudio, 'Enable', 'off');
    btnExportCsv = uibutton(exportGrid, 'push', 'Text', 'Export CSV Data', ...
                           'ButtonPushedFcn', @onExportCsv, 'Enable', 'off');

    % 7. Metrics & Diagnostics Panel
    metricsPanel = uipanel(ctrlGrid, 'Title', 'Real-time Metrics', ...
                           'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.98 0.98 0.99]);
    metricsGrid = uigridlayout(metricsPanel, [6 1]);
    metricsGrid.RowHeight = {18, 18, 18, 18, 18, 18};
    metricsGrid.Padding = [6 6 6 6];
    metricsGrid.RowSpacing = 2;

    lblInput = uilabel(metricsGrid, 'Text', 'Signal: Ready for input');
    lblSQNR = uilabel(metricsGrid, 'Text', 'End-to-End SQNR: -- dB');
    lblCodedBER = uilabel(metricsGrid, 'Text', 'Coded-Bit BER: --');
    lblInfoBER = uilabel(metricsGrid, 'Text', 'Info-Bit BER: --');
    lblCorrected = uilabel(metricsGrid, 'Text', 'SECDED Corrected: -- blocks');
    lblUncorr = uilabel(metricsGrid, 'Text', 'Uncorrectable: -- blocks');

    % 8. Status & Progress Label
    statusLabel = uilabel(ctrlGrid, 'Text', 'Ready.', ...
                          'FontWeight', 'bold', 'FontColor', [0.2 0.2 0.2]);

    %% ================= RIGHT VISUALIZATION PANEL =================
    vizPanel = uitabgroup(mainGrid);

    % Tab 1: Waveforms
    tabWaveforms = uitab(vizPanel, 'Title', 'Audio Waveforms');
    gridWaveforms = uigridlayout(tabWaveforms, [1 1]);
    axWaveforms = uiaxes(gridWaveforms);
    title(axWaveforms, 'Time-Domain Audio Signals (First 50 ms)');
    xlabel(axWaveforms, 'Time (ms)');
    ylabel(axWaveforms, 'Normalized Amplitude');
    grid(axWaveforms, 'on');

    % Tab 2: QPSK Constellation
    tabConst = uitab(vizPanel, 'Title', 'QPSK Constellation');
    gridConst = uigridlayout(tabConst, [1 1]);
    axConst = uiaxes(gridConst);
    title(axConst, 'Gray-Mapped QPSK In-Phase & Quadrature');
    xlabel(axConst, 'In-Phase (I)');
    ylabel(axConst, 'Quadrature (Q)');
    grid(axConst, 'on');
    axis(axConst, 'equal');
    xlim(axConst, [-2 2]); ylim(axConst, [-2 2]);

    % Tab 3: BER vs SNR
    tabBER = uitab(vizPanel, 'Title', 'BER vs SNR Sweep');
    gridBER = uigridlayout(tabBER, [1 1]);
    axBER = uiaxes(gridBER);
    title(axBER, 'Bit Error Rate Performance: Coded vs Uncoded QPSK');
    xlabel(axBER, 'Channel SNR (Es/N0 in dB)');
    ylabel(axBER, 'Bit Error Rate (BER)');
    grid(axBER, 'on');

    % Tab 4: DM vs ADM
    tabDM = uitab(vizPanel, 'Title', 'DM vs ADM Comparison');
    gridDM = uigridlayout(tabDM, [2 1]);
    axDM1 = uiaxes(gridDM);
    title(axDM1, 'Linear DM vs Adaptive DM Waveform Tracking');
    xlabel(axDM1, 'Time (ms)'); ylabel(axDM1, 'Amplitude');
    grid(axDM1, 'on');

    axDM2 = uiaxes(gridDM);
    title(axDM2, 'Tracking Error: Linear DM (Slope Overload) vs ADM');
    xlabel(axDM2, 'Time (ms)'); ylabel(axDM2, 'Error');
    grid(axDM2, 'on');

    % Initialize with a fast synthetic smoke test
    try
        onRunSingle([], []);
    catch
        % Safe fallback if headless
    end

    %% ================= CALLBACK IMPLEMENTATIONS =================

    function onSourceChanged(src, ~)
        val = src.Value;
        if contains(val, 'Synthetic')
            guiState.audioSource = 'synthetic';
            statusLabel.Text = 'Selected: Synthetic multitone audio.';
        elseif contains(val, 'WAV')
            [fileName, pathName] = uigetfile('*.wav', 'Select Input Audio File', ...
                                             fullfile(projectRoot, 'data', 'input'));
            if isequal(fileName, 0)
                src.Value = 'Deterministic Synthetic Speech';
                guiState.audioSource = 'synthetic';
                statusLabel.Text = 'WAV selection cancelled. Kept synthetic.';
            else
                guiState.customWavPath = fullfile(pathName, fileName);
                guiState.audioSource = guiState.customWavPath;
                statusLabel.Text = ['Loaded: ' fileName];
            end
        elseif contains(val, 'Microphone')
            guiState.audioSource = 'mic';
            statusLabel.Text = 'Microphone source configured (records upon simulation).';
        end
    end

    function onPcmChanged(src, ~)
        val = src.Value;
        if contains(val, '8-bit')
            guiState.pcmBits = 8;
        elseif contains(val, '4-bit')
            guiState.pcmBits = 4;
        elseif contains(val, '3-bit')
            guiState.pcmBits = 3;
        end
        statusLabel.Text = sprintf('Configured %d-bit PCM.', guiState.pcmBits);
    end

    function onSnrChanged(src, ~)
        guiState.snrDB = round(src.Value, 1);
        snrLabel.Text = sprintf('3. Channel SNR: %.1f dB (Es/N0)', guiState.snrDB);
    end

    function onRunSingle(~, ~)
        setControlsEnabled(false);
        statusLabel.Text = 'Running single end-to-end simulation...';
        drawnow;

        try
            cfg = struct();
            cfg.source = guiState.audioSource;
            cfg.fsTarget = guiState.fs;
            cfg.durationSec = guiState.duration;
            cfg.pcmBits = guiState.pcmBits;
            cfg.mu = guiState.mu;
            cfg.snrDB = guiState.snrDB;
            cfg.snrDefinition = 'EsN0';
            cfg.seed = 42;

            res = run_full_system(cfg);
            guiState.lastResults = res;

            % Update Metrics
            lblInput.Text = sprintf('Signal: %d samples, Fs=%d Hz', length(res.audioIn), res.fs);
            lblSQNR.Text = sprintf('End-to-End SQNR: %.2f dB', res.sqnrEndToEnd);
            lblCodedBER.Text = sprintf('Coded-Bit BER: %.4e (%d err)', res.berCodedBits, res.errCodedBits);
            lblInfoBER.Text = sprintf('Info-Bit BER: %.4e (%d err)', res.berInfoBits, res.errInfoBits);
            lblCorrected.Text = sprintf('SECDED Corrected: %d blocks', res.decodeStats.singleErrorCorrected);
            lblUncorr.Text = sprintf('Uncorrectable: %d blocks', res.decodeStats.doubleErrorDetected);

            % Update Waveform plot
            cla(axWaveforms);
            nPlot = min(400, length(res.audioIn));
            tMs = (0:nPlot-1)' / res.fs * 1000;
            plot(axWaveforms, tMs, res.audioIn(1:nPlot), 'b-', 'LineWidth', 1.8, 'DisplayName', 'Original Audio');
            hold(axWaveforms, 'on');
            stairs(axWaveforms, tMs, res.pcmQuantizedAudio(1:nPlot), 'g--', 'LineWidth', 1.2, 'DisplayName', 'PCM Quantized');
            plot(axWaveforms, tMs, res.reconstructedAudio(1:nPlot), 'r:', 'LineWidth', 1.5, 'DisplayName', 'Received Reconstructed');
            hold(axWaveforms, 'off');
            legend(axWaveforms, 'Location', 'northeast');
            title(axWaveforms, sprintf('Waveforms: %d-bit PCM, SNR = %.1f dB, SQNR = %.2f dB', ...
                  guiState.pcmBits, guiState.snrDB, res.sqnrEndToEnd));

            % Update Constellation plot
            cla(axConst);
            numConstPlot = min(2000, length(res.rxSymbols));
            scatter(axConst, real(res.rxSymbols(1:numConstPlot)), imag(res.rxSymbols(1:numConstPlot)), ...
                    15, [0.3 0.6 0.9], 'filled', 'DisplayName', sprintf('Noisy RX (%.1f dB)', guiState.snrDB));
            hold(axConst, 'on');
            constIdeal = [(1+1j)/sqrt(2), (-1+1j)/sqrt(2), (-1-1j)/sqrt(2), (1-1j)/sqrt(2)];
            scatter(axConst, real(constIdeal), imag(constIdeal), 100, 'r', 'filled', 'MarkerEdgeColor', 'k', ...
                    'LineWidth', 1.5, 'DisplayName', 'Ideal Points');
            xline(axConst, 0, 'k--', 'Alpha', 0.5);
            yline(axConst, 0, 'k--', 'Alpha', 0.5);
            hold(axConst, 'off');
            legend(axConst, 'Location', 'northeast');
            title(axConst, sprintf('Gray QPSK Constellation (SNR = %.1f dB)', guiState.snrDB));

            % Update DM vs ADM Tab
            updateDmTab(res.audioIn(1:min(1000, length(res.audioIn))));

            % Enable Playback & Export
            btnPlayOrig.Enable = 'on';
            btnPlayRec.Enable = 'on';
            btnExportAudio.Enable = 'on';
            btnExportCsv.Enable = 'on';

            statusLabel.Text = 'Simulation finished successfully.';
        catch ME
            statusLabel.Text = ['Error: ' ME.message];
            uialert(fig, ME.message, 'Simulation Failed');
        end
        setControlsEnabled(true);
    end

    function updateDmTab(subAudio)
        delta = 0.03;
        [~, dmRec, ~] = dm_encoder(subAudio, delta, 0);
        [~, admRec, ~] = adm_encoder(subAudio, delta, 0.005, 0.20, 0, 1.6, 0.6);

        tMs = (0:length(subAudio)-1)' / guiState.fs * 1000;
        nSub = min(300, length(subAudio));

        cla(axDM1);
        plot(axDM1, tMs(1:nSub), subAudio(1:nSub), 'k-', 'LineWidth', 2, 'DisplayName', 'Original');
        hold(axDM1, 'on');
        plot(axDM1, tMs(1:nSub), dmRec(1:nSub), 'r--', 'LineWidth', 1.2, 'DisplayName', 'Linear DM');
        plot(axDM1, tMs(1:nSub), admRec(1:nSub), 'b-', 'LineWidth', 1.2, 'DisplayName', 'Adaptive DM');
        hold(axDM1, 'off');
        legend(axDM1, 'Location', 'northeast');

        cla(axDM2);
        plot(axDM2, tMs(1:nSub), subAudio(1:nSub) - dmRec(1:nSub), 'r--', 'LineWidth', 1.2, 'DisplayName', 'Linear DM Error');
        hold(axDM2, 'on');
        plot(axDM2, tMs(1:nSub), subAudio(1:nSub) - admRec(1:nSub), 'b-', 'LineWidth', 1.2, 'DisplayName', 'ADM Error');
        hold(axDM2, 'off');
        legend(axDM2, 'Location', 'northeast');
    end

    function onRunSweep(~, ~)
        setControlsEnabled(false);
        statusLabel.Text = 'Running 0 to 10 dB Monte Carlo BER sweep...';
        drawnow;

        try
            simCfg = struct();
            simCfg.snrRange = 0:1:10;
            simCfg.snrDefinition = 'EsN0';
            simCfg.numBitsPerSNR = 50000; % 50k bits per point for snappy GUI response
            simCfg.seed = 2026;
            simCfg.verbose = false;

            sweep = ber_simulation(simCfg);
            guiState.lastSweepResults = sweep;

            % Plot BER curves on axBER
            cla(axBER);
            pCoded = sweep.berCodedBits;
            pInfo = sweep.berInfoBits;
            pUnc = sweep.berUncoded;
            pTheo = sweep.berTheoretical;

            floorV = 1e-6;
            pCoded(pCoded == 0) = floorV;
            pInfo(pInfo == 0) = floorV;
            pUnc(pUnc == 0) = floorV;

            semilogy(axBER, sweep.snrRange, pCoded, 'b-s', 'LineWidth', 1.8, 'MarkerSize', 7, ...
                     'DisplayName', 'Coded Bits (before decoding)');
            hold(axBER, 'on');
            semilogy(axBER, sweep.snrRange, pInfo, 'r-o', 'LineWidth', 2.0, 'MarkerSize', 7, ...
                     'DisplayName', 'Info Bits ((8,4) SECDED output)');
            semilogy(axBER, sweep.snrRange, pUnc, 'k--^', 'LineWidth', 1.4, 'MarkerSize', 6, ...
                     'DisplayName', 'Uncoded QPSK');
            semilogy(axBER, sweep.snrRange, pTheo, 'm:', 'LineWidth', 2.0, ...
                     'DisplayName', 'Theoretical Gray QPSK');
            hold(axBER, 'off');
            legend(axBER, 'Location', 'southwest');
            set(axBER, 'YScale', 'log');
            ylim(axBER, [5e-7 1.0]);
            title(axBER, 'Monte Carlo BER vs SNR (0 to 10 dB, Es/N0)');

            btnExportCsv.Enable = 'on';
            statusLabel.Text = 'BER sweep completed!';
        catch ME
            statusLabel.Text = ['Sweep failed: ' ME.message];
            uialert(fig, ME.message, 'BER Sweep Error');
        end
        setControlsEnabled(true);
    end

    function onPlayOrig(~, ~)
        if ~isempty(guiState.lastResults)
            sound(guiState.lastResults.audioIn, guiState.lastResults.fs);
            statusLabel.Text = 'Playing original audio...';
        end
    end

    function onPlayRec(~, ~)
        if ~isempty(guiState.lastResults)
            sound(guiState.lastResults.reconstructedAudio, guiState.lastResults.fs);
            statusLabel.Text = 'Playing received/reconstructed audio...';
        end
    end

    function onExportAudio(~, ~)
        if isempty(guiState.lastResults), return; end
        outFolder = fullfile(projectRoot, 'data', 'output');
        if ~exist(outFolder, 'dir'), mkdir(outFolder); end
        fPath = fullfile(outFolder, sprintf('gui_audio_%dbit_snr%.1fdB.wav', ...
                                           guiState.pcmBits, guiState.snrDB));
        try
            audiowrite(fPath, guiState.lastResults.reconstructedAudio, guiState.lastResults.fs);
            statusLabel.Text = ['Saved audio: ' fPath];
            uialert(fig, ['Reconstructed audio saved to: ' fPath], 'Audio Export Success');
        catch ME
            uialert(fig, ME.message, 'Export Error');
        end
    end

    function onExportCsv(~, ~)
        outFolder = fullfile(projectRoot, 'results', 'tables');
        if ~exist(outFolder, 'dir'), mkdir(outFolder); end
        csvOut = fullfile(outFolder, 'gui_sweep_results.csv');
        if ~isempty(guiState.lastSweepResults)
            s = guiState.lastSweepResults;
            fid = fopen(csvOut, 'w');
            if fid ~= -1
                fprintf(fid, 'SNR_dB,Coded_BER,Info_BER,Uncoded_BER,Theoretical_BER\n');
                for k = 1:length(s.snrRange)
                    fprintf(fid, '%.1f,%.6e,%.6e,%.6e,%.6e\n', ...
                            s.snrRange(k), s.berCodedBits(k), s.berInfoBits(k), s.berUncoded(k), s.berTheoretical(k));
                end
                fclose(fid);
                statusLabel.Text = ['Exported CSV: ' csvOut];
                uialert(fig, ['Sweep results saved to: ' csvOut], 'CSV Export Success');
            end
        else
            statusLabel.Text = 'Run a BER sweep first to export CSV.';
        end
    end

    function setControlsEnabled(enabled)
        str = 'off';
        if enabled, str = 'on'; end
        btnRunSingle.Enable = str;
        btnRunSweep.Enable = str;
        sourceDropdown.Enable = str;
        pcmDropdown.Enable = str;
        snrSlider.Enable = str;
    end
end

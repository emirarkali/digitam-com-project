function results = run_full_system(config)
% RUN_FULL_SYSTEM End-to-end simulation of Project 7 Digital Communication Chain.
%
% Architecture:
%   Audio Source -> mu-law PCM Encoder -> (8,4) SECDED Channel Encoder ->
%   Gray QPSK Modulator -> Complex AWGN Channel -> ML QPSK Demodulator ->
%   Syndrome SECDED Decoder -> mu-law PCM Decoder -> Audio Reconstruction
%
% Syntax:
%   results = run_full_system(config)
%
% Input:
%   config - (optional) struct with configuration fields:
%     .source        - 'synthetic' (default), filepath, 'mic', or numeric vector.
%     .fsTarget      - Sampling rate in Hz (default: 8000).
%     .durationSec   - Audio duration in seconds (default: 10.0).
%     .pcmBits       - Quantization bit depth: 3, 4, or 8 (default: 8).
%     .mu            - mu-law companding parameter (default: 255).
%     .snrDB         - Channel SNR in dB (default: 5.0).
%     .snrDefinition - 'EsN0' (default) or 'EbN0'.
%     .noiseFree     - Boolean flag to bypass noise (default: false).
%     .seed          - Random number generator seed (default: []).
%
% Output:
%   results - Struct containing all intermediate signals, metadata, and performance metrics.
%
% Dependencies:
%   MATLAB base functions only.

    if nargin < 1 || isempty(config)
        config = struct();
    end

    % Set parameter defaults
    if ~isfield(config, 'source') || isempty(config.source),           config.source = 'synthetic'; end
    if ~isfield(config, 'fsTarget') || isempty(config.fsTarget),       config.fsTarget = 8000;      end
    if ~isfield(config, 'durationSec') || isempty(config.durationSec), config.durationSec = 10.0;  end
    if ~isfield(config, 'pcmBits') || isempty(config.pcmBits),         config.pcmBits = 8;          end
    if ~isfield(config, 'mu') || isempty(config.mu),                   config.mu = 255;             end
    if ~isfield(config, 'snrDB') || isempty(config.snrDB),             config.snrDB = 5.0;          end
    if ~isfield(config, 'snrDefinition') || isempty(config.snrDefinition), config.snrDefinition = 'EsN0'; end
    if ~isfield(config, 'noiseFree') || isempty(config.noiseFree),     config.noiseFree = false;    end

    if isfield(config, 'seed') && ~isempty(config.seed)
        rng(config.seed);
    end

    % 1. Audio Source Acquisition
    [audioIn, fs, audioMeta] = audio_input(config.source, config.fsTarget, config.durationSec);

    % 2. mu-law PCM Encoding
    [pcmBits, pcmMeta, pcmQuantizedAudio] = pcm_encoder(audioIn, config.pcmBits, config.mu);
    sqnrQuantOnly = calculate_sqnr(audioIn, pcmQuantizedAudio);

    % 3. Channel Encoding (8,4) SECDED
    [G, H] = generate_matrices();
    [codedBits, padInfo] = channel_encoder(pcmBits, G);

    % 4. QPSK Modulation (Gray mapping, Es = 1.0)
    txSymbols = qpsk_mod(codedBits);

    % 5. AWGN Channel
    if config.noiseFree
        rxSymbols = txSymbols;
        channelMeta = struct();
        channelMeta.snrDB = Inf;
        channelMeta.snrDefinition = config.snrDefinition;
        channelMeta.codeRate = 0.5;
        channelMeta.Es = 1.0;
        channelMeta.N0 = 0.0;
        channelMeta.sigma = 0.0;
        channelMeta.measuredNoisePower = 0.0;
        channelMeta.measuredSNRdB = Inf;
    else
        [rxSymbols, channelMeta] = add_awgn(txSymbols, config.snrDB, config.snrDefinition, 0.5);
    end

    % 6. QPSK Demodulation (ML nearest-neighbor)
    [demodCodedBits, detectedSymbols] = qpsk_demod(rxSymbols);

    % Measure Coded-Bit BER
    [berCodedBits, errCodedBits, totalCodedBits] = calculate_ber(codedBits, demodCodedBits);

    % 7. Channel Decoding (SECDED Syndrome Decoder)
    [decodedInfoBits, decodeStats] = channel_decoder(demodCodedBits, H, padInfo);

    % Measure Decoded Information-Bit BER
    [berInfoBits, errInfoBits, totalInfoBits] = calculate_ber(pcmBits, decodedInfoBits);

    % 8. PCM Decoding & Reconstruction
    [reconstructedAudio, recoveredLevels] = pcm_decoder(decodedInfoBits, pcmMeta);

    % Measure End-to-End SQNR
    sqnrEndToEnd = calculate_sqnr(audioIn, reconstructedAudio);

    % Package full results
    results = struct();
    results.config = config;
    results.fs = fs;
    results.audioIn = audioIn;
    results.audioMeta = audioMeta;
    results.pcmBits = pcmBits;
    results.pcmMeta = pcmMeta;
    results.pcmQuantizedAudio = pcmQuantizedAudio;
    results.sqnrQuantOnly = sqnrQuantOnly;
    results.codedBits = codedBits;
    results.padInfo = padInfo;
    results.txSymbols = txSymbols;
    results.rxSymbols = rxSymbols;
    results.detectedSymbols = detectedSymbols;
    results.channelMeta = channelMeta;
    results.demodCodedBits = demodCodedBits;
    results.berCodedBits = berCodedBits;
    results.errCodedBits = errCodedBits;
    results.totalCodedBits = totalCodedBits;
    results.decodedInfoBits = decodedInfoBits;
    results.decodeStats = decodeStats;
    results.berInfoBits = berInfoBits;
    results.errInfoBits = errInfoBits;
    results.totalInfoBits = totalInfoBits;
    results.reconstructedAudio = reconstructedAudio;
    results.recoveredLevels = recoveredLevels;
    results.sqnrEndToEnd = sqnrEndToEnd;
end

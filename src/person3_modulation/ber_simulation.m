function results = ber_simulation(config)
% BER_SIMULATION Monte Carlo BER simulation over AWGN channel for (8,4) Coded vs Uncoded QPSK.
%
% Syntax:
%   results = ber_simulation(config)
%
% Inputs:
%   config - (optional) struct with simulation parameters:
%     .snrRange        - Vector of SNR values in dB (default: 0:1:10).
%     .snrDefinition   - 'EsN0' (default) or 'EbN0'.
%     .numBitsPerSNR   - Number of info bits per SNR point (default: 100000).
%     .seed            - Random number generator seed (default: 42).
%     .verbose         - Boolean flag to print progress (default: false).
%
% Outputs:
%   results - Struct containing:
%     .snrRange
%     .snrDefinition
%     .berCodedBits       - Coded-bit BER after QPSK demodulation (before decoding)
%     .berInfoBits        - Information-bit BER after channel decoding
%     .berUncoded         - Uncoded QPSK BER baseline
%     .berTheoretical     - Theoretical Gray-QPSK BER curve
%     .errorsCodedBits    - Raw count of coded bit errors
%     .errorsInfoBits     - Raw count of info bit errors
%     .errorsUncoded      - Raw count of uncoded bit errors
%     .totalInfoBits      - Total tested information bits
%     .singleErrorsCorr   - Count of single-bit errors corrected by SECDED
%     .doubleErrorsDet    - Count of double-bit errors detected by SECDED
%     .unrecoveredBlocks  - Blocks with uncorrectable errors
%
% Dependencies:
%   MATLAB base functions only.

    if nargin < 1 || isempty(config)
        config = struct();
    end

    if ~isfield(config, 'snrRange') || isempty(config.snrRange)
        config.snrRange = 0:1:10;
    end
    if ~isfield(config, 'snrDefinition') || isempty(config.snrDefinition)
        config.snrDefinition = 'EsN0';
    end
    if ~isfield(config, 'numBitsPerSNR') || isempty(config.numBitsPerSNR)
        config.numBitsPerSNR = 100000;
    end
    if ~isfield(config, 'seed') || isempty(config.seed)
        config.seed = 42;
    end
    if ~isfield(config, 'verbose') || isempty(config.verbose)
        config.verbose = false;
    end

    rng(config.seed);

    [G, H] = generate_matrices();
    snrVec = config.snrRange(:)';
    numPoints = length(snrVec);

    % Ensure info bit count is divisible by 4 (block length k=4)
    numInfoBits = ceil(config.numBitsPerSNR / 4) * 4;

    % Preallocate result arrays
    berCodedBits = zeros(1, numPoints);
    berInfoBits = zeros(1, numPoints);
    berUncoded = zeros(1, numPoints);
    berTheoretical = zeros(1, numPoints);

    errorsCodedBits = zeros(1, numPoints);
    errorsInfoBits = zeros(1, numPoints);
    errorsUncoded = zeros(1, numPoints);

    singleErrorsCorr = zeros(1, numPoints);
    doubleErrorsDet = zeros(1, numPoints);
    noErrorBlocks = zeros(1, numPoints);

    % Pre-generate deterministic information bits for all SNR points
    infoBits = randi([0 1], numInfoBits, 1);

    % 1. Coded branch: Channel encode (k=4 -> n=8, Rc=0.5)
    [codedBits, padInfo] = channel_encoder(infoBits, G);
    txSymbolsCoded = qpsk_mod(codedBits);

    % 2. Uncoded branch: Direct QPSK transmission (Rc=1.0)
    txSymbolsUncoded = qpsk_mod(infoBits);

    for idx = 1:numPoints
        snrDB = snrVec(idx);

        % --- Coded System Transmission ---
        % Transmit over AWGN
        [rxSymbolsCoded, ~] = add_awgn(txSymbolsCoded, snrDB, config.snrDefinition, 0.5);
        [demodCodedBits, ~] = qpsk_demod(rxSymbolsCoded);

        % Measure coded-bit errors
        [berCoded, errCoded, ~] = calculate_ber(codedBits, demodCodedBits);
        berCodedBits(idx) = berCoded;
        errorsCodedBits(idx) = errCoded;

        % Channel decode with SECDED
        [decodedInfoBits, decodeStats] = channel_decoder(demodCodedBits, H, padInfo);

        % Measure information-bit errors
        [berInfo, errInfo, ~] = calculate_ber(infoBits, decodedInfoBits);
        berInfoBits(idx) = berInfo;
        errorsInfoBits(idx) = errInfo;

        singleErrorsCorr(idx) = decodeStats.singleErrorCorrected;
        doubleErrorsDet(idx) = decodeStats.doubleErrorDetected;
        noErrorBlocks(idx) = decodeStats.noErrorBlocks;

        % --- Uncoded Baseline Transmission ---
        % For fair comparison at same Eb/N0:
        % Uncoded has Rc = 1.0. If snrDefinition is 'EbN0', pass Rc = 1.0.
        % If snrDefinition is 'EsN0', Es = 2*Eb (since 2 bits/symbol).
        [rxSymbolsUncoded, ~] = add_awgn(txSymbolsUncoded, snrDB, config.snrDefinition, 1.0);
        [demodUncodedBits, ~] = qpsk_demod(rxSymbolsUncoded);

        [berUnc, errUnc, ~] = calculate_ber(infoBits, demodUncodedBits);
        berUncoded(idx) = berUnc;
        errorsUncoded(idx) = errUnc;

        % --- Theoretical Uncoded QPSK BER ---
        % Pb = 0.5 * erfc(sqrt(Eb/N0))
        if strcmpi(config.snrDefinition, 'EbN0')
            ebN0Linear = 10^(snrDB / 10);
        else
            % For uncoded QPSK, Es = 2 * Eb -> Eb/N0 = (Es/N0) / 2
            ebN0Linear = 10^(snrDB / 10) / 2;
        end
        berTheoretical(idx) = 0.5 * erfc(sqrt(ebN0Linear));

        if config.verbose
            fprintf('SNR = %4.1f dB | Coded-bit BER: %7.5f | Info-bit BER: %7.5f | Uncoded BER: %7.5f | Corrected: %d\n', ...
                    snrDB, berCoded, berInfo, berUnc, decodeStats.singleErrorCorrected);
        end
    end

    results = struct();
    results.snrRange = snrVec;
    results.snrDefinition = config.snrDefinition;
    results.numInfoBitsPerSNR = numInfoBits;
    results.numCodedBitsPerSNR = length(codedBits);
    results.berCodedBits = berCodedBits;
    results.berInfoBits = berInfoBits;
    results.berUncoded = berUncoded;
    results.berTheoretical = berTheoretical;
    results.errorsCodedBits = errorsCodedBits;
    results.errorsInfoBits = errorsInfoBits;
    results.errorsUncoded = errorsUncoded;
    results.singleErrorsCorr = singleErrorsCorr;
    results.doubleErrorsDet = doubleErrorsDet;
    results.noErrorBlocks = noErrorBlocks;
    results.seed = config.seed;
end

function [decodedBits, decodeStats] = channel_decoder(receivedBits, H, padInfo)
% CHANNEL_DECODER SECDED syndrome decoder for systematic (8,4) block code.
%
% SECDED Syndrome Classification:
%   - Zero syndrome (S == 0): No detected error (status = 0).
%   - Odd weight syndrome: Matches exactly one column of H. Single-bit error
%     at position col is corrected (status = 1).
%   - Even weight non-zero syndrome: Double-bit (or uncorrectable) error detected.
%     Flagged without miscorrection (status = 2).
%
% Syntax:
%   [decodedBits, decodeStats] = channel_decoder(receivedBits, H, padInfo)
%
% Inputs:
%   receivedBits - Column vector of received coded bits (multiple of 8).
%   H            - 4x8 parity check matrix (optional, default: from generate_matrices).
%   padInfo      - Struct from channel_encoder (optional, strips padding if provided).
%
% Outputs:
%   decodedBits  - Reconstructed information bitstream (N_info x 1 double).
%   decodeStats  - Struct containing error correction statistics and block statuses.
%
% Dependencies:
%   MATLAB base functions only.

    if nargin < 2 || isempty(H)
        [~, H] = generate_matrices();
    end
    if nargin < 3
        padInfo = [];
    end

    validateattributes(receivedBits, {'numeric', 'logical'}, {'vector'}, 'channel_decoder', 'receivedBits');
    if size(H, 1) ~= 4 || size(H, 2) ~= 8
        error('channel_decoder:InvalidH', 'Parity check matrix H must have dimensions 4x8.');
    end

    rBits = double(receivedBits(:));
    totalBits = length(rBits);

    if mod(totalBits, 8) ~= 0
        error('channel_decoder:InvalidBitLength', ...
              'Received bitstream length (%d) is not a multiple of block length 8.', totalBits);
    end

    numBlocks = totalBits / 8;
    codeMat = reshape(rBits, 8, numBlocks).'; % numBlocks x 8

    % Fast O(1) Syndrome Lookup Table initialization (16 possible syndromes)
    % Index = S * [8; 4; 2; 1] + 1 (values 1 to 16)
    lutCol = zeros(16, 1);    % 0 means no single-bit flip
    lutStatus = zeros(16, 1); % 0: no err, 1: single err corrected, 2: uncorrectable

    % 1. Zero syndrome
    lutStatus(1) = 0; % S = [0 0 0 0] -> index 1

    % 2. All 8 columns of H (all have odd weight)
    for colIdx = 1:8
        hCol = H(:, colIdx).';
        synVal = hCol * [8; 4; 2; 1] + 1;
        lutCol(synVal) = colIdx;
        lutStatus(synVal) = 1;
    end

    % 3. Any remaining non-zero syndromes have even weight -> uncorrectable (status 2)
    for sIdx = 2:16
        if lutStatus(sIdx) == 0
            lutStatus(sIdx) = 2;
        end
    end

    % Compute syndromes for all blocks: S = mod(codeMat * H', 2)
    syndromes = mod(codeMat * H.', 2); % numBlocks x 4
    synIndices = syndromes * [8; 4; 2; 1] + 1; % numBlocks x 1

    % Lookup correction column and status for every block
    blockStatus = lutStatus(synIndices);
    errorCols = lutCol(synIndices);

    % Correct single-bit errors in-place
    singleErrMask = (blockStatus == 1);
    if any(singleErrMask)
        singleErrBlocks = find(singleErrMask);
        for i = 1:length(singleErrBlocks)
            bIdx = singleErrBlocks(i);
            cIdx = errorCols(bIdx);
            codeMat(bIdx, cIdx) = 1 - codeMat(bIdx, cIdx);
        end
    end

    % Extract systematic information bits (first 4 bits of each block)
    infoMat = codeMat(:, 1:4);
    rawDecoded = reshape(infoMat.', [], 1);

    % Strip padding if padInfo is available
    if ~isempty(padInfo) && isfield(padInfo, 'originalLength') && padInfo.originalLength <= length(rawDecoded)
        decodedBits = rawDecoded(1:padInfo.originalLength);
    else
        decodedBits = rawDecoded;
    end

    % Compile statistics
    decodeStats = struct();
    decodeStats.numBlocks = numBlocks;
    decodeStats.noErrorBlocks = sum(blockStatus == 0);
    decodeStats.singleErrorCorrected = sum(blockStatus == 1);
    decodeStats.doubleErrorDetected = sum(blockStatus == 2);
    decodeStats.blockStatus = blockStatus;
end

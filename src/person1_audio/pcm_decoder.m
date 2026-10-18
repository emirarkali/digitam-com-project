function [reconstructedAudio, recoveredLevels] = pcm_decoder(bits, pcmMeta)
% PCM_DECODER mu-law companded uniform PCM decoder.
%
% Syntax:
%   [reconstructedAudio, recoveredLevels] = pcm_decoder(bits, pcmMeta)
%
% Inputs:
%   bits               - Column vector of binary bits (0/1 doubles).
%   pcmMeta            - Struct with quantizer configuration from pcm_encoder.
%
% Outputs:
%   reconstructedAudio - Reconstructed audio column vector (N x 1 double).
%   recoveredLevels    - Recovered quantization indices (N x 1 double, 0 to L-1).
%
% Dependencies:
%   MATLAB base functions only (no Communications Toolbox).

    validateattributes(bits, {'numeric', 'logical'}, {'vector'}, 'pcm_decoder', 'bits');
    if ~isstruct(pcmMeta) || ~isfield(pcmMeta, 'nBits') || ~isfield(pcmMeta, 'mu')
        error('pcm_decoder:InvalidMetadata', 'pcmMeta must contain nBits and mu.');
    end

    nBits = pcmMeta.nBits;
    mu = pcmMeta.mu;
    L = 2^nBits;
    delta = 2 / L;

    bitsCol = double(bits(:));
    totalBits = length(bitsCol);

    if mod(totalBits, nBits) ~= 0
        error('pcm_decoder:BitLengthMismatch', ...
              'Bitstream length (%d) is not an integer multiple of nBits (%d).', totalBits, nBits);
    end

    numSamples = totalBits / nBits;

    % Reshape into numSamples x nBits matrix
    bitMat = reshape(bitsCol, nBits, numSamples).';

    % Bit unpacking: Convert binary rows to integer index q (0 to L-1)
    weights = 2 .^ (nBits - 1 : -1 : 0);
    q = bitMat * weights.';
    recoveredLevels = q;

    % Reconstruction in compressed domain (midpoint of bin)
    yHat = -1 + (q + 0.5) * delta;

    % Inverse mu-law expansion
    absYHat = abs(yHat);
    xHat = sign(yHat) .* (((1 + mu).^absYHat - 1) / mu);

    % Restore peak scaling if recorded in metadata
    if isfield(pcmMeta, 'peakScale') && pcmMeta.peakScale > 0
        xHat = xHat * pcmMeta.peakScale;
    end

    % If expected original sample count is known, enforce it
    if isfield(pcmMeta, 'numSamples') && pcmMeta.numSamples <= length(xHat)
        reconstructedAudio = xHat(1:pcmMeta.numSamples);
    else
        reconstructedAudio = xHat;
    end
end

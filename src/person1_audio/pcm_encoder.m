function [bits, pcmMeta, quantizedSignal] = pcm_encoder(audio, nBits, mu)
% PCM_ENCODER mu-law companded uniform PCM encoder.
%
% Syntax:
%   [bits, pcmMeta, quantizedSignal] = pcm_encoder(audio, nBits, mu)
%
% Inputs:
%   audio           - Input audio signal vector (N x 1 double), range [-1, 1].
%   nBits           - Quantizer resolution in bits (e.g. 3, 4, 8; default: 8).
%   mu              - Companding parameter (default: 255).
%
% Outputs:
%   bits            - Serialized binary bitstream (column vector of 0/1 doubles).
%   pcmMeta         - Struct with quantizer configuration and signal metadata.
%   quantizedSignal - Quantized audio signal in linear domain (N x 1 double).
%
% Dependencies:
%   MATLAB base functions only (no Communications Toolbox).

    if nargin < 2 || isempty(nBits)
        nBits = 8;
    end
    if nargin < 3 || isempty(mu)
        mu = 255;
    end

    validateattributes(audio, {'numeric'}, {'nonempty', 'vector'}, 'pcm_encoder', 'audio');
    validateattributes(nBits, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', 16}, 'pcm_encoder', 'nBits');
    validateattributes(mu, {'numeric'}, {'scalar', 'positive'}, 'pcm_encoder', 'mu');

    x = double(audio(:));
    N = length(x);

    % Clamp input to [-1, 1]
    xClamped = max(-1.0, min(1.0, x));

    % 1. mu-law compression: y = sign(x) * ln(1 + mu*|x|) / ln(1 + mu)
    absX = abs(xClamped);
    y = sign(xClamped) .* (log(1 + mu * absX) ./ log(1 + mu));

    % 2. Mid-rise uniform quantization in [-1, 1]
    L = 2^nBits;
    delta = 2 / L;

    % Quantization index in range [0, L - 1]
    % bin k covers [-1 + k*delta, -1 + (k+1)*delta)
    q = floor((y + 1) * (L / 2));
    q = max(0, min(L - 1, q));

    % Reconstruction in compressed domain (midpoint of bin)
    yHat = -1 + (q + 0.5) * delta;

    % Inverse mu-law expansion for reference quantized signal
    absYHat = abs(yHat);
    quantizedSignal = sign(yHat) .* (((1 + mu).^absYHat - 1) / mu);

    % 3. Bit packing: Convert index q (0 to L-1) to nBits binary (MSB first)
    % bitMat has dimensions N x nBits
    shiftVec = nBits - 1 : -1 : 0;
    bitMat = zeros(N, nBits);
    for col = 1:nBits
        bitMat(:, col) = bitand(bitshift(q, -shiftVec(col)), 1);
    end

    % Serialize to column vector: [sample1_MSB..LSB, sample2_MSB..LSB, ...]'
    bits = double(reshape(bitMat.', [], 1));

    % Populate metadata
    pcmMeta = struct();
    pcmMeta.nBits = nBits;
    pcmMeta.mu = mu;
    pcmMeta.L = L;
    pcmMeta.delta = delta;
    pcmMeta.numSamples = N;
    pcmMeta.numBits = length(bits);
end

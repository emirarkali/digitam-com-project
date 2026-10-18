function [encodedBits, padInfo] = channel_encoder(infoBits, G)
% CHANNEL_ENCODER Encodes information bits using systematic (8,4) block code.
%
% Syntax:
%   [encodedBits, padInfo] = channel_encoder(infoBits, G)
%
% Inputs:
%   infoBits    - Column vector of binary information bits (0/1 doubles).
%   G           - 4x8 generator matrix (optional, default: from generate_matrices).
%
% Outputs:
%   encodedBits - Serialized encoded codeword bitstream (N_coded x 1 double).
%   padInfo     - Struct containing padding count and original info length.
%
% Dependencies:
%   MATLAB base functions only.

    if nargin < 2 || isempty(G)
        [G, ~] = generate_matrices();
    end

    validateattributes(infoBits, {'numeric', 'logical'}, {'vector'}, 'channel_encoder', 'infoBits');
    if size(G, 1) ~= 4 || size(G, 2) ~= 8
        error('channel_encoder:InvalidG', 'Generator matrix G must have dimensions 4x8.');
    end

    bits = double(infoBits(:));
    origLen = length(bits);

    % Handle zero-padding if length is not divisible by 4
    remBits = mod(origLen, 4);
    if remBits ~= 0
        numPad = 4 - remBits;
        bits = [bits; zeros(numPad, 1)];
    else
        numPad = 0;
    end

    numBlocks = length(bits) / 4;
    msgMatrix = reshape(bits, 4, numBlocks).'; % numBlocks x 4

    % Systematic encoding: c = mod(m * G, 2) -> numBlocks x 8
    codeMatrix = mod(msgMatrix * G, 2);

    % Serialize to column vector: [c1_1..8, c2_1..8, ...]'
    encodedBits = double(reshape(codeMatrix.', [], 1));

    padInfo = struct();
    padInfo.originalLength = origLen;
    padInfo.numPad = numPad;
    padInfo.numBlocks = numBlocks;
    padInfo.k = 4;
    padInfo.n = 8;
    padInfo.codeRate = 4 / 8;
end

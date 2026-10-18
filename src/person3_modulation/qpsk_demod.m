function [rxBits, detectedSymbols] = qpsk_demod(rxSymbols)
% QPSK_DEMOD Maximum Likelihood (ML) Gray-mapped QPSK Demodulator.
%
% Gray constellation decision boundaries:
%   b1 is determined by imag(rxSymbols): Q >= 0 -> b1 = 0, Q < 0 -> b1 = 1
%   b2 is determined by real(rxSymbols): I >= 0 -> b2 = 0, I < 0 -> b2 = 1
%
% Syntax:
%   [rxBits, detectedSymbols] = qpsk_demod(rxSymbols)
%
% Input:
%   rxSymbols       - Received noisy complex baseband symbols (N_sym x 1 complex double).
%
% Outputs:
%   rxBits          - Demodulated binary bitstream (2*N_sym x 1 double).
%   detectedSymbols - Nearest constellation points (N_sym x 1 complex double).
%
% Dependencies:
%   MATLAB base functions only (no Communications Toolbox).

    validateattributes(rxSymbols, {'numeric'}, {'vector'}, 'qpsk_demod', 'rxSymbols');
    r = complex(double(rxSymbols(:)));
    numSymbols = length(r);

    I_rx = real(r);
    Q_rx = imag(r);

    % Decision rule matching Gray mapping:
    % b1 = (Q < 0) -> 0 if Q >= 0, 1 if Q < 0
    % b2 = (I < 0) -> 0 if I >= 0, 1 if I < 0
    b1 = double(Q_rx < 0);
    b2 = double(I_rx < 0);

    % Interleave bits: [b1_1, b2_1, b1_2, b2_2, ...]'
    bitMat = [b1, b2]; % numSymbols x 2
    rxBits = reshape(bitMat.', [], 1);

    % Reconstruct hard-decision constellation symbols
    I_det = (1 - 2 * b2) / sqrt(2);
    Q_det = (1 - 2 * b1) / sqrt(2);
    detectedSymbols = complex(I_det, Q_det);
end

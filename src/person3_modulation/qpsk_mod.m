function txSymbols = qpsk_mod(bits)
% QPSK_MOD Gray-mapped QPSK Modulator with unit average symbol energy (Es = 1).
%
% Gray constellation mapping:
%   b1 b2 -> Symbol (I + j*Q)
%   0  0  -> (+1 + 1j) / sqrt(2)  (Quadrant 1)
%   0  1  -> (-1 + 1j) / sqrt(2)  (Quadrant 2)
%   1  1  -> (-1 - 1j) / sqrt(2)  (Quadrant 3)
%   1  0  -> (+1 - 1j) / sqrt(2)  (Quadrant 4)
%
% Energy:
%   Es = |s|^2 = (1/2 + 1/2) = 1.0 (exact unit energy)
%
% Syntax:
%   txSymbols = qpsk_mod(bits)
%
% Input:
%   bits      - Column vector of binary bits (0/1 doubles).
%
% Output:
%   txSymbols - Complex baseband QPSK symbols (N_sym x 1 complex double).
%
% Dependencies:
%   MATLAB base functions only (no Communications Toolbox).

    validateattributes(bits, {'numeric', 'logical'}, {'vector'}, 'qpsk_mod', 'bits');
    b = double(bits(:));

    % Ensure even number of bits (zero-pad 1 bit if odd)
    if mod(length(b), 2) ~= 0
        b = [b; 0];
    end

    numSymbols = length(b) / 2;
    pairs = reshape(b, 2, numSymbols).'; % numSymbols x 2: [b1, b2]

    b1 = pairs(:, 1);
    b2 = pairs(:, 2);

    % Gray mapping equations:
    % Q = (1 - 2*b1) / sqrt(2)  -> b1=0 => Q=+1/sqrt(2), b1=1 => Q=-1/sqrt(2)
    % I = (1 - 2*b2) / sqrt(2)  -> b2=0 => I=+1/sqrt(2), b2=1 => I=-1/sqrt(2)
    I = (1 - 2 * b2) / sqrt(2);
    Q = (1 - 2 * b1) / sqrt(2);

    txSymbols = complex(I, Q);
end

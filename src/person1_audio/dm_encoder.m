function [bits, reconstructedSignal, state] = dm_encoder(signal, delta, initialVal)
% DM_ENCODER Linear Delta Modulation (DM) encoder.
%
% Syntax:
%   [bits, reconstructedSignal, state] = dm_encoder(signal, delta, initialVal)
%
% Inputs:
%   signal              - Input signal vector (N x 1 double).
%   delta               - Fixed step size (default: 0.05).
%   initialVal          - Initial integrator state (default: 0).
%
% Outputs:
%   bits                - Binary output bitstream (N x 1 double, 0 or 1).
%   reconstructedSignal - Quantized/approximated signal (N x 1 double).
%   state               - Struct containing configuration and final accumulator value.
%
% Dependencies:
%   MATLAB base functions only.

    if nargin < 2 || isempty(delta)
        delta = 0.05;
    end
    if nargin < 3 || isempty(initialVal)
        initialVal = 0.0;
    end

    validateattributes(signal, {'numeric'}, {'vector'}, 'dm_encoder', 'signal');
    validateattributes(delta, {'numeric'}, {'scalar', 'positive'}, 'dm_encoder', 'delta');
    validateattributes(initialVal, {'numeric'}, {'scalar'}, 'dm_encoder', 'initialVal');

    x = double(signal(:));
    N = length(x);

    bits = zeros(N, 1);
    reconstructedSignal = zeros(N, 1);

    accum = initialVal;
    for n = 1:N
        if x(n) >= accum
            bits(n) = 1;
            accum = accum + delta;
        else
            bits(n) = 0;
            accum = accum - delta;
        end
        reconstructedSignal(n) = accum;
    end

    state = struct();
    state.delta = delta;
    state.initialVal = initialVal;
    state.finalAccum = accum;
    state.numSamples = N;
end

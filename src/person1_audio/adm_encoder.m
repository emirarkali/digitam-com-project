function [bits, reconstructedSignal, state] = adm_encoder(signal, delta0, deltaMin, deltaMax, initialVal, alpha, beta)
% ADM_ENCODER Adaptive Delta Modulation (ADM) encoder.
%
% Adaptation policy:
%   If consecutive bits agree (b[n] == b[n-1]), step increases by factor alpha:
%     delta[n] = min(deltaMax, delta[n-1] * alpha)  (mitigates slope overload)
%   If consecutive bits alternate (b[n] ~= b[n-1]), step decreases by factor beta:
%     delta[n] = max(deltaMin, delta[n-1] * beta)   (mitigates granular noise)
%
% Syntax:
%   [bits, reconstructedSignal, state] = adm_encoder(signal, delta0, deltaMin, deltaMax, initialVal, alpha, beta)
%
% Inputs:
%   signal              - Input signal vector (N x 1 double).
%   delta0              - Initial step size (default: 0.02).
%   deltaMin            - Minimum allowed step size (default: 0.005).
%   deltaMax            - Maximum allowed step size (default: 0.25).
%   initialVal          - Initial accumulator level (default: 0).
%   alpha               - Expansion multiplier when b[n]==b[n-1] (default: 1.5).
%   beta                - Contraction multiplier when b[n]~=b[n-1] (default: 0.6).
%
% Outputs:
%   bits                - Binary output bitstream (N x 1 double, 0 or 1).
%   reconstructedSignal - Approximated audio signal (N x 1 double).
%   state               - Struct tracking configuration and final states.
%
% Dependencies:
%   MATLAB base functions only.

    if nargin < 2 || isempty(delta0),   delta0 = 0.02;   end
    if nargin < 3 || isempty(deltaMin), deltaMin = 0.005; end
    if nargin < 4 || isempty(deltaMax), deltaMax = 0.25;  end
    if nargin < 5 || isempty(initialVal), initialVal = 0.0; end
    if nargin < 6 || isempty(alpha),    alpha = 1.5;     end
    if nargin < 7 || isempty(beta),     beta = 0.6;      end

    validateattributes(signal, {'numeric'}, {'vector'}, 'adm_encoder', 'signal');
    validateattributes(delta0, {'numeric'}, {'scalar', 'positive'}, 'adm_encoder', 'delta0');
    validateattributes(deltaMin, {'numeric'}, {'scalar', 'positive'}, 'adm_encoder', 'deltaMin');
    validateattributes(deltaMax, {'numeric'}, {'scalar', 'positive'}, 'adm_encoder', 'deltaMax');

    x = double(signal(:));
    N = length(x);

    bits = zeros(N, 1);
    reconstructedSignal = zeros(N, 1);
    stepSizes = zeros(N, 1);

    accum = initialVal;
    currentDelta = delta0;

    for n = 1:N
        if n == 1
            if x(n) >= accum
                b = 1;
            else
                b = 0;
            end
            currentDelta = delta0;
        else
            % Predict direction
            if x(n) >= accum
                b = 1;
            else
                b = 0;
            end
            % Adapt step size based on previous bit
            if b == bits(n - 1)
                currentDelta = min(deltaMax, currentDelta * alpha);
            else
                currentDelta = max(deltaMin, currentDelta * beta);
            end
        end

        bits(n) = b;
        stepSizes(n) = currentDelta;

        if b == 1
            accum = accum + currentDelta;
        else
            accum = accum - currentDelta;
        end
        reconstructedSignal(n) = accum;
    end

    state = struct();
    state.delta0 = delta0;
    state.deltaMin = deltaMin;
    state.deltaMax = deltaMax;
    state.alpha = alpha;
    state.beta = beta;
    state.initialVal = initialVal;
    state.finalAccum = accum;
    state.finalDelta = currentDelta;
    state.stepSizes = stepSizes;
end

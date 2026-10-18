function reconstructedSignal = adm_decoder(bits, delta0, deltaMin, deltaMax, initialVal, alpha, beta)
% ADM_DECODER Adaptive Delta Modulation (ADM) decoder.
%
% Syntax:
%   reconstructedSignal = adm_decoder(bits, delta0, deltaMin, deltaMax, initialVal, alpha, beta)
%
% Inputs:
%   bits                - Input binary bitstream (N x 1 double, 0 or 1).
%   delta0              - Initial step size (default: 0.02).
%   deltaMin            - Minimum allowed step size (default: 0.005).
%   deltaMax            - Maximum allowed step size (default: 0.25).
%   initialVal          - Initial accumulator level (default: 0).
%   alpha               - Expansion multiplier when b[n]==b[n-1] (default: 1.5).
%   beta                - Contraction multiplier when b[n]~=b[n-1] (default: 0.6).
%
% Output:
%   reconstructedSignal - Reconstructed signal vector (N x 1 double).
%
% Dependencies:
%   MATLAB base functions only.

    if nargin < 2 || isempty(delta0),   delta0 = 0.02;   end
    if nargin < 3 || isempty(deltaMin), deltaMin = 0.005; end
    if nargin < 4 || isempty(deltaMax), deltaMax = 0.25;  end
    if nargin < 5 || isempty(initialVal), initialVal = 0.0; end
    if nargin < 6 || isempty(alpha),    alpha = 1.5;     end
    if nargin < 7 || isempty(beta),     beta = 0.6;      end

    validateattributes(bits, {'numeric', 'logical'}, {'vector'}, 'adm_decoder', 'bits');
    validateattributes(delta0, {'numeric'}, {'scalar', 'positive'}, 'adm_decoder', 'delta0');
    validateattributes(deltaMin, {'numeric'}, {'scalar', 'positive'}, 'adm_decoder', 'deltaMin');
    validateattributes(deltaMax, {'numeric'}, {'scalar', 'positive'}, 'adm_decoder', 'deltaMax');

    b = double(bits(:));
    N = length(b);

    reconstructedSignal = zeros(N, 1);
    accum = initialVal;
    currentDelta = delta0;

    for n = 1:N
        if n == 1
            currentDelta = delta0;
        else
            if b(n) == b(n - 1)
                currentDelta = min(deltaMax, currentDelta * alpha);
            else
                currentDelta = max(deltaMin, currentDelta * beta);
            end
        end

        if b(n) == 1
            accum = accum + currentDelta;
        else
            accum = accum - currentDelta;
        end
        reconstructedSignal(n) = accum;
    end
end

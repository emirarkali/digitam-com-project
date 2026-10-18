function reconstructedSignal = dm_decoder(bits, delta, initialVal)
% DM_DECODER Linear Delta Modulation (DM) decoder.
%
% Syntax:
%   reconstructedSignal = dm_decoder(bits, delta, initialVal)
%
% Inputs:
%   bits                - Input binary bitstream (N x 1 double, 0 or 1).
%   delta               - Fixed step size (default: 0.05).
%   initialVal          - Initial integrator state (default: 0).
%
% Output:
%   reconstructedSignal - Reconstructed signal vector (N x 1 double).
%
% Dependencies:
%   MATLAB base functions only.

    if nargin < 2 || isempty(delta)
        delta = 0.05;
    end
    if nargin < 3 || isempty(initialVal)
        initialVal = 0.0;
    end

    validateattributes(bits, {'numeric', 'logical'}, {'vector'}, 'dm_decoder', 'bits');
    validateattributes(delta, {'numeric'}, {'scalar', 'positive'}, 'dm_decoder', 'delta');
    validateattributes(initialVal, {'numeric'}, {'scalar'}, 'dm_decoder', 'initialVal');

    b = double(bits(:));
    N = length(b);

    reconstructedSignal = zeros(N, 1);
    accum = initialVal;

    for n = 1:N
        if b(n) == 1
            accum = accum + delta;
        else
            accum = accum - delta;
        end
        reconstructedSignal(n) = accum;
    end
end

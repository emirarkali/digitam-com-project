function [rxSymbols, channelMeta] = add_awgn(txSymbols, snrDB, snrDefinition, codeRate)
% ADD_AWGN Adds complex Additive White Gaussian Noise (AWGN) to transmitted symbols.
%
% Mathematical noise formulation:
%   n = sqrt(N0 / 2) * (randn(N, 1) + 1j * randn(N, 1))
%   where E{|n|^2} = N0, and E{Re(n)^2} = E{Im(n)^2} = N0 / 2.
%
% SNR definitions:
%   'EsN0' (default) -> snrDB = 10 * log10(Es / N0)
%                       N0 = Es / 10^(snrDB / 10)
%   'EbN0'           -> snrDB = 10 * log10(Eb_info / N0)
%                       Es = (k_mod * codeRate) * Eb_info  (k_mod = 2 for QPSK)
%                       Es / N0 = (k_mod * codeRate) * 10^(snrDB / 10)
%                       N0 = Es / (Es / N0)
%
% Syntax:
%   [rxSymbols, channelMeta] = add_awgn(txSymbols, snrDB, snrDefinition, codeRate)
%
% Inputs:
%   txSymbols     - Transmitted complex baseband symbols (N_sym x 1 complex double).
%   snrDB         - Desired SNR in decibels (scalar double).
%   snrDefinition - 'EsN0' (default) or 'EbN0'.
%   codeRate      - Code rate Rc (default: 0.5 for (8,4) code; 1.0 for uncoded).
%
% Outputs:
%   rxSymbols     - Received complex baseband symbols: txSymbols + noise.
%   channelMeta   - Struct detailing noise power, N0, sigma, and measurements.
%
% Dependencies:
%   MATLAB base functions only (no Communications Toolbox).

    if nargin < 3 || isempty(snrDefinition)
        snrDefinition = 'EsN0';
    end
    if nargin < 4 || isempty(codeRate)
        codeRate = 0.5;
    end

    validateattributes(txSymbols, {'numeric'}, {'vector'}, 'add_awgn', 'txSymbols');
    validateattributes(snrDB, {'numeric'}, {'scalar'}, 'add_awgn', 'snrDB');
    validateattributes(codeRate, {'numeric'}, {'scalar', 'positive', '<=', 1.0}, 'add_awgn', 'codeRate');

    s = complex(double(txSymbols(:)));
    N = length(s);

    % Measure signal symbol power Es
    Es = mean(abs(s) .^ 2);
    if Es == 0
        Es = 1.0; % Fallback for silent input
    end

    k_mod = 2; % QPSK transmits 2 coded bits per symbol

    if strcmpi(snrDefinition, 'EsN0')
        snrLinear = 10^(snrDB / 10);
        N0 = Es / snrLinear;
        ebN0DB = snrDB - 10 * log10(k_mod * codeRate);
    elseif strcmpi(snrDefinition, 'EbN0')
        ebN0Linear = 10^(snrDB / 10);
        esN0Linear = (k_mod * codeRate) * ebN0Linear;
        N0 = Es / esN0Linear;
        ebN0DB = snrDB;
    else
        error('add_awgn:InvalidDefinition', 'snrDefinition must be ''EsN0'' or ''EbN0''.');
    end

    % Noise standard deviation per dimension (I and Q each have variance N0 / 2)
    sigma = sqrt(N0 / 2);

    % Generate independent I and Q Gaussian noise vectors
    noiseI = sigma * randn(N, 1);
    noiseQ = sigma * randn(N, 1);
    noise = complex(noiseI, noiseQ);

    rxSymbols = s + noise;

    % Metadata
    channelMeta = struct();
    channelMeta.snrDB = snrDB;
    channelMeta.snrDefinition = snrDefinition;
    channelMeta.codeRate = codeRate;
    channelMeta.Es = Es;
    channelMeta.N0 = N0;
    channelMeta.sigma = sigma;
    channelMeta.equivalentEbN0DB = ebN0DB;
    channelMeta.measuredNoisePower = mean(abs(noise) .^ 2);
    channelMeta.measuredSNRdB = 10 * log10(Es / channelMeta.measuredNoisePower);
end

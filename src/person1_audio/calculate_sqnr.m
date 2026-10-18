function sqnrDB = calculate_sqnr(referenceAudio, reconstructedAudio)
% CALCULATE_SQNR Measures Signal-to-Quantization-Noise Ratio in dB.
%
% Syntax:
%   sqnrDB = calculate_sqnr(referenceAudio, reconstructedAudio)
%
% Inputs:
%   referenceAudio     - Original/reference audio vector.
%   reconstructedAudio - Reconstructed audio vector.
%
% Output:
%   sqnrDB             - SQNR in decibels (10*log10(Psig / Perr)).
%
% Edge cases:
%   Perr == 0          -> returns Inf
%   Psig == 0          -> returns -Inf (or 0 if Perr == 0)

    validateattributes(referenceAudio, {'numeric'}, {'vector'}, 'calculate_sqnr', 'referenceAudio');
    validateattributes(reconstructedAudio, {'numeric'}, {'vector'}, 'calculate_sqnr', 'reconstructedAudio');

    s = double(referenceAudio(:));
    sHat = double(reconstructedAudio(:));

    N = min(length(s), length(sHat));
    if N == 0
        error('calculate_sqnr:EmptyVectors', 'Input vectors must not be empty.');
    end

    s = s(1:N);
    sHat = sHat(1:N);

    pSig = mean(s .^ 2);
    err = s - sHat;
    pErr = mean(err .^ 2);

    if pErr == 0
        if pSig == 0
            sqnrDB = 0;
        else
            sqnrDB = Inf;
        end
    elseif pSig == 0
        sqnrDB = -Inf;
    else
        sqnrDB = 10 * log10(pSig / pErr);
    end
end

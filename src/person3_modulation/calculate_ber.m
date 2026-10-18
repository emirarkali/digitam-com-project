function [ber, numErrors, totalBits] = calculate_ber(referenceBits, receivedBits)
% CALCULATE_BER Calculates Bit Error Rate (BER) without Communications Toolbox.
%
% Syntax:
%   [ber, numErrors, totalBits] = calculate_ber(referenceBits, receivedBits)
%
% Inputs:
%   referenceBits - Ground-truth binary bitstream vector.
%   receivedBits  - Received binary bitstream vector.
%
% Outputs:
%   ber           - Bit Error Rate (numErrors / totalBits).
%   numErrors     - Count of mismatched bits.
%   totalBits     - Number of compared bits.
%
% Dependencies:
%   MATLAB base functions only.

    validateattributes(referenceBits, {'numeric', 'logical'}, {'vector'}, 'calculate_ber', 'referenceBits');
    validateattributes(receivedBits, {'numeric', 'logical'}, {'vector'}, 'calculate_ber', 'receivedBits');

    ref = double(referenceBits(:));
    rec = double(receivedBits(:));

    totalBits = min(length(ref), length(rec));
    if totalBits == 0
        ber = 0;
        numErrors = 0;
        return;
    end

    ref = ref(1:totalBits);
    rec = rec(1:totalBits);

    numErrors = sum(ref ~= rec);
    ber = numErrors / totalBits;
end

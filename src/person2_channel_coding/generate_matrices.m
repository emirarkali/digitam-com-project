function [G, H] = generate_matrices()
% GENERATE_MATRICES Generates generator (G) and parity-check (H) matrices for (8,4) SECDED code.
%
% Parity-check matrix H (4x8):
%   H = [1 0 1 1 1 0 0 0;
%        1 1 1 0 0 1 0 0;
%        0 1 1 1 0 0 1 0;
%        1 1 0 1 0 0 0 1];
%
% Submatrices:
%   H = [P' | I4] -> P = H(:, 1:4)'
%   G = [I4 | P]  (4x8 generator matrix)
%
% Orthogonality:
%   mod(G * H', 2) == 0 (zero matrix 4x4)
%
% Syntax:
%   [G, H] = generate_matrices()
%
% Outputs:
%   G - 4x8 generator matrix (double, 0/1)
%   H - 4x8 parity-check matrix (double, 0/1)
%
% Dependencies:
%   MATLAB base functions only.

    H = [1 0 1 1 1 0 0 0;
         1 1 1 0 0 1 0 0;
         0 1 1 1 0 0 1 0;
         1 1 0 1 0 0 0 1];

    P = H(:, 1:4)';
    G = [eye(4), P];

    % Verify orthogonality assert
    orthoCheck = mod(G * H', 2);
    if any(orthoCheck(:) ~= 0)
        error('generate_matrices:OrthogonalityViolation', 'G and H do not satisfy G*H'' = 0 (mod 2).');
    end
end

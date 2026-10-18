%% test_awgn.m - Unit Tests for Complex AWGN Channel
function test_awgn()
    fprintf('Running test_awgn...\n');
    addpath(genpath('src'));

    % 1. Statistical noise variance verification
    % Generate 200,000 zero symbols, add noise at SNR = 3 dB
    N = 200000;
    zeroSyms = zeros(N, 1);
    snrDB = 3;
    Es = 1.0;
    N0_expected = Es / (10^(snrDB / 10));

    rng(100);
    [noisySyms, meta] = add_awgn(zeroSyms, snrDB, 'EsN0', 0.5);

    % Total noise power
    measuredN0 = mean(abs(noisySyms).^2);
    relError = abs(measuredN0 - N0_expected) / N0_expected;
    assert(relError < 0.02, sprintf('Noise power deviation (%.4f) exceeds 2%% threshold', relError));

    % I and Q component variances must each be N0 / 2
    varI = var(real(noisySyms));
    varQ = var(imag(noisySyms));
    expectedVarPerDim = N0_expected / 2;
    assert(abs(varI - expectedVarPerDim) / expectedVarPerDim < 0.02, 'I-channel variance mismatch');
    assert(abs(varQ - expectedVarPerDim) / expectedVarPerDim < 0.02, 'Q-channel variance mismatch');

    % Correlation between I and Q must be near zero (independent)
    corrIQ = corrcoef(real(noisySyms), imag(noisySyms));
    assert(abs(corrIQ(1, 2)) < 0.01, 'I and Q noise components must be uncorrelated');

    % 2. EsN0 vs EbN0 conversion test
    % For QPSK (k_mod=2) and Rate 1/2 (codeRate=0.5):
    % k_mod * codeRate = 1.0 -> Es = Eb_info -> EsN0(dB) == EbN0(dB)
    [~, metaEs] = add_awgn(zeroSyms(1:10), 6.0, 'EsN0', 0.5);
    [~, metaEb] = add_awgn(zeroSyms(1:10), 6.0, 'EbN0', 0.5);
    assert(abs(metaEs.N0 - metaEb.N0) < 1e-12, 'For Rate 1/2 QPSK, Es/N0 and Eb/N0 must yield identical N0');

    % For uncoded QPSK (k_mod=2, codeRate=1.0):
    % Es = 2 * Eb -> Es/N0 is 3.0103 dB higher than Eb/N0
    [~, metaUncodedEb] = add_awgn(zeroSyms(1:10), 6.0, 'EbN0', 1.0);
    assert(metaUncodedEb.N0 < metaEs.N0, 'Uncoded Eb/N0 must yield smaller N0 than coded for same dB value');

    % 3. Reproducibility test with seed
    rng(42);
    [r1, ~] = add_awgn(zeroSyms(1:100), 5.0);
    rng(42);
    [r2, ~] = add_awgn(zeroSyms(1:100), 5.0);
    assert(isequal(r1, r2), 'AWGN must be reproducible when seed is reset');

    fprintf('test_awgn: PASS (200,000 samples, noise power error %.3f%%, I/Q independence verified)\n', ...
            relError * 100);
end

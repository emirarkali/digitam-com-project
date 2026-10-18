%% test_qpsk.m - Unit Tests for Gray QPSK Modulator & Demodulator
function test_qpsk()
    fprintf('Running test_qpsk...\n');
    addpath(genpath('src'));

    % 1. Exact 4 constellation points test
    cPairs = [0 0; 0 1; 1 1; 1 0];
    expectedSyms = [(+1 + 1j)/sqrt(2); ...
                    (-1 + 1j)/sqrt(2); ...
                    (-1 - 1j)/sqrt(2); ...
                    (+1 - 1j)/sqrt(2)];

    for k = 1:4
        bits = cPairs(k, :)';
        s = qpsk_mod(bits);
        assert(abs(s - expectedSyms(k)) < 1e-12, ...
               sprintf('Constellation mapping mismatch for pair [%d %d]', bits(1), bits(2)));

        [rxB, detS] = qpsk_demod(s);
        assert(isequal(rxB, bits), ...
               sprintf('Demodulation bit mismatch for pair [%d %d]', bits(1), bits(2)));
        assert(abs(detS - expectedSyms(k)) < 1e-12, 'Detected symbol mismatch');
    end

    % 2. Unit energy verification
    % Every single constellation symbol must have |s|^2 == 1.0
    energies = abs(expectedSyms) .^ 2;
    assert(all(abs(energies - 1.0) < 1e-12), 'Constellation symbols must have exact unit energy');

    % 3. Large random bitstream noiseless round-trip test (50,000 bits)
    rng(42);
    randBits = randi([0 1], 50000, 1);
    txSyms = qpsk_mod(randBits);
    assert(length(txSyms) == 25000, 'Symbol count must be half the bit count');
    assert(abs(mean(abs(txSyms).^2) - 1.0) < 1e-12, 'Average transmitted power must be 1.0');

    [rxBits, detSyms] = qpsk_demod(txSyms);
    assert(isequal(randBits, rxBits), 'Noiseless QPSK roundtrip failed!');
    assert(max(abs(txSyms - detSyms)) < 1e-12, 'Noiseless detected symbols must match tx symbols');

    % 4. ML Nearest Neighbor Decision Boundary testing
    % Test points slightly perturbed around each quadrant
    perturbations = [0.1 + 0.1j, -0.1 + 0.1j, -0.1 - 0.1j, 0.1 - 0.1j];
    for k = 1:4
        testPoint = expectedSyms(k) + perturbations(k);
        [bDemod, sDet] = qpsk_demod(testPoint);
        assert(isequal(bDemod, cPairs(k, :)'), 'Decision boundary test failed');
        assert(abs(sDet - expectedSyms(k)) < 1e-12, 'Nearest constellation point mismatch');
    end

    fprintf('test_qpsk: PASS (50,000 bits tested, 100%% noiseless roundtrip, unit energy verified)\n');
end

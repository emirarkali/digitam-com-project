%% test_pcm.m - Comprehensive Unit Test for mu-law PCM & Quantization
function test_pcm()
    fprintf('Running test_pcm...\n');
    addpath(genpath('src'));

    % 1. Silence test
    silence = zeros(1000, 1);
    for nBits = [3, 4, 8]
        [bits, meta, qSig] = pcm_encoder(silence, nBits, 255);
        assert(length(bits) == 1000 * nBits, 'Bitstream length mismatch for silence');
        [rec, ~] = pcm_decoder(bits, meta);
        assert(length(rec) == 1000, 'Reconstructed silence length mismatch');
        assert(all(isfinite(rec)), 'Reconstructed silence contains non-finite values');
    end

    % 2. Full-scale test (+1 and -1)
    fullScale = [1.0; -1.0; 0.5; -0.5; 0.0];
    [bits, meta, qSig] = pcm_encoder(fullScale, 8, 255);
    [rec, ~] = pcm_decoder(bits, meta);
    assert(max(abs(rec - qSig)) < 1e-10, 'Reconstruction must match quantizer output');

    % 3. Clipping test (values beyond [-1, 1])
    overshoot = [1.5; -2.0; 0.2];
    [bits, meta, qSig] = pcm_encoder(overshoot, 8, 255);
    [rec, ~] = pcm_decoder(bits, meta);
    assert(all(abs(rec) <= 1.0 + 1e-6), 'Quantizer must clip values beyond [-1, 1]');

    % 4. Multi-bit resolution & SQNR monotonicity test
    rng(123);
    t = (0:7999)' / 8000;
    testAudio = 0.7 * sin(2 * pi * 300 * t) + 0.2 * cos(2 * pi * 700 * t);
    sqnrList = zeros(1, 3);
    bitDepths = [3, 4, 8];

    for i = 1:length(bitDepths)
        nB = bitDepths(i);
        [bits, meta, qSig] = pcm_encoder(testAudio, nB, 255);
        assert(length(bits) == length(testAudio) * nB, 'Bit count must be N * nBits');
        [rec, ~] = pcm_decoder(bits, meta);
        sqnr = calculate_sqnr(testAudio, rec);
        sqnrList(i) = sqnr;
        assert(isfinite(sqnr), 'SQNR must be finite');
        assert(max(abs(rec - qSig)) < 1e-10, 'Quantizer output identity check');
    end

    % Check that SQNR strictly increases with bit depth
    assert(sqnrList(1) < sqnrList(2), '3-bit SQNR must be lower than 4-bit SQNR');
    assert(sqnrList(2) < sqnrList(3), '4-bit SQNR must be lower than 8-bit SQNR');
    assert(sqnrList(3) > 30, '8-bit mu-law SQNR must exceed 30 dB for audio');

    % 5. Dimension robustness (row vs column input)
    rowSig = testAudio(1:100)';
    [bitsRow, metaRow, ~] = pcm_encoder(rowSig, 8, 255);
    assert(size(bitsRow, 2) == 1, 'Output bits must always be a column vector');

    % 6. Bit unpacking round-trip test
    for qVal = [0, 1, 7, 15, 127, 255]
        shiftVec = 7:-1:0;
        b = bitand(bitshift(qVal, -shiftVec), 1);
        qRecovered = sum(b .* (2 .^ (7:-1:0)));
        assert(qVal == qRecovered, 'Binary bit packing round-trip failure');
    end

    fprintf('test_pcm: PASS (All assertions passed, SQNR 3/4/8 bits: %.2f / %.2f / %.2f dB)\n', ...
            sqnrList(1), sqnrList(2), sqnrList(3));
end

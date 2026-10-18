%% test_channel_coding.m - Unit Tests for (8,4) SECDED Channel Code
function test_channel_coding()
    fprintf('Running test_channel_coding...\n');
    addpath(genpath('src'));

    % 1. Matrices and Orthogonality
    [G, H] = generate_matrices();
    assert(size(G, 1) == 4 && size(G, 2) == 8, 'G must be 4x8');
    assert(size(H, 1) == 4 && size(H, 2) == 8, 'H must be 4x8');
    assert(all(mod(G * H', 2) == 0, 'all'), 'G * H^T must be zero matrix mod 2');

    % 2. All 16 valid 4-bit messages test
    allMsgs = dec2bin(0:15) - '0'; % 16 x 4 matrix
    for i = 1:16
        m = allMsgs(i, :)';
        [c, padInfo] = channel_encoder(m, G);
        assert(length(c) == 8, 'Encoded length must be 8');
        assert(padInfo.numPad == 0, 'No padding expected for 4-bit message');

        % Parity check: syndrome must be zero
        syn = mod(c' * H', 2);
        assert(all(syn == 0), 'Syndrome of valid codeword must be zero');

        % Decode without noise
        [mDec, stats] = channel_decoder(c, H, padInfo);
        assert(isequal(mDec, m), 'Zero-noise decode must equal original message');
        assert(stats.noErrorBlocks == 1, 'Status must report noErrorBlocks = 1');
        assert(stats.blockStatus == 0, 'Block status must be 0');
    end

    % 3. Exhaustive Single-bit error correction test (16 messages x 8 bit positions = 128 tests)
    singleErrorCount = 0;
    for i = 1:16
        m = allMsgs(i, :)';
        c = mod(m' * G, 2)';
        for bitPos = 1:8
            cNoisy = c;
            cNoisy(bitPos) = 1 - cNoisy(bitPos); % Inject single-bit error
            
            padInfo = struct('originalLength', 4, 'numPad', 0, 'numBlocks', 1);
            [mDec, stats] = channel_decoder(cNoisy, H, padInfo);

            assert(isequal(mDec, m), ...
                   sprintf('Failed to correct single bit at pos %d for msg %d', bitPos, i));
            assert(stats.singleErrorCorrected == 1, 'Stats must count single error');
            assert(stats.blockStatus == 1, 'Status must be 1 for single-bit correction');
            singleErrorCount = singleErrorCount + 1;
        end
    end
    assert(singleErrorCount == 128, 'Must test exactly 128 single-bit error cases');

    % 4. Exhaustive Double-bit error detection test (16 messages x 28 pairs = 448 tests)
    doubleErrorCount = 0;
    pairs = nchoosek(1:8, 2); % 28 pairs
    for i = 1:16
        m = allMsgs(i, :)';
        c = mod(m' * G, 2)';
        for p = 1:size(pairs, 1)
            cNoisy = c;
            cNoisy(pairs(p, 1)) = 1 - cNoisy(pairs(p, 1));
            cNoisy(pairs(p, 2)) = 1 - cNoisy(pairs(p, 2));

            padInfo = struct('originalLength', 4, 'numPad', 0, 'numBlocks', 1);
            [~, stats] = channel_decoder(cNoisy, H, padInfo);

            % In SECDED, double errors MUST be detected as uncorrectable (status 2)
            assert(stats.doubleErrorDetected == 1, 'Double error must be detected');
            assert(stats.blockStatus == 2, 'Status must be 2 (uncorrectable)');
            doubleErrorCount = doubleErrorCount + 1;
        end
    end
    assert(doubleErrorCount == 448, 'Must test exactly 448 double-bit error cases');

    % 5. Arbitrary padding test
    for arbitraryLen = [1, 2, 3, 5, 7, 11, 23, 97]
        arbitraryBits = randi([0 1], arbitraryLen, 1);
        [enc, padInfo] = channel_encoder(arbitraryBits, G);
        assert(mod(length(enc), 8) == 0, 'Encoded length must be multiple of 8');
        
        [dec, ~] = channel_decoder(enc, H, padInfo);
        assert(length(dec) == arbitraryLen, 'Decoded length must match original after padding removal');
        assert(isequal(dec, arbitraryBits), 'Padding round-trip decode failed');
    end

    fprintf('test_channel_coding: PASS (All 128 single-bit errors corrected, all 448 double-bit errors detected)\n');
end

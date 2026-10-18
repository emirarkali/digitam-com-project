%% test_full_system.m - System-level Integration Tests
function test_full_system()
    fprintf('Running test_full_system...\n');
    addpath(genpath('src'));

    % 1. Noise-free end-to-end tests across PCM bit depths (3, 4, 8 bits)
    for pcmBits = [3, 4, 8]
        cfg = struct();
        cfg.source = 'synthetic';
        cfg.fsTarget = 8000;
        cfg.durationSec = 0.5; % 4000 samples
        cfg.pcmBits = pcmBits;
        cfg.mu = 255;
        cfg.noiseFree = true;

        res = run_full_system(cfg);

        % Asserts
        assert(res.berCodedBits == 0, sprintf('Noise-free coded BER must be 0 for %d bits', pcmBits));
        assert(res.berInfoBits == 0, sprintf('Noise-free info BER must be 0 for %d bits', pcmBits));
        assert(res.decodeStats.noErrorBlocks == res.padInfo.numBlocks, 'All blocks must have zero syndrome');
        assert(max(abs(res.reconstructedAudio - res.pcmQuantizedAudio)) < 1e-10, ...
               'Reconstructed audio must equal quantization-only audio under zero channel noise');
        assert(abs(res.sqnrEndToEnd - res.sqnrQuantOnly) < 1e-8, ...
               'End-to-end SQNR must equal quantization SQNR under zero noise');
    end

    % 2. Noisy transmission test (finite metrics check)
    cfgNoisy = struct();
    cfgNoisy.source = 'synthetic';
    cfgNoisy.fsTarget = 8000;
    cfgNoisy.durationSec = 0.5;
    cfgNoisy.pcmBits = 8;
    cfgNoisy.snrDB = 4.0;
    cfgNoisy.noiseFree = false;
    cfgNoisy.seed = 99;

    resNoisy = run_full_system(cfgNoisy);
    assert(isfinite(resNoisy.berCodedBits), 'Coded BER must be finite');
    assert(isfinite(resNoisy.berInfoBits), 'Info BER must be finite');
    assert(isfinite(resNoisy.sqnrEndToEnd), 'End-to-end SQNR must be finite');
    assert(resNoisy.decodeStats.numBlocks > 0, 'Must have decoded blocks');

    % 3. BER Simulation sweep (0:1:10 dB sweep returns 11 points)
    simCfg = struct();
    simCfg.snrRange = 0:1:10;
    simCfg.numBitsPerSNR = 20000;
    simCfg.seed = 42;
    simCfg.verbose = false;

    simRes = ber_simulation(simCfg);
    assert(length(simRes.snrRange) == 11, 'Sweep must contain 11 SNR points');
    assert(length(simRes.berCodedBits) == 11, 'Coded BER must have 11 points');
    assert(length(simRes.berInfoBits) == 11, 'Info BER must have 11 points');
    assert(length(simRes.berUncoded) == 11, 'Uncoded BER must have 11 points');
    assert(all(simRes.berCodedBits >= 0 & simRes.berCodedBits <= 1.0), 'BER must be in [0, 1]');
    assert(simRes.berCodedBits(1) > simRes.berCodedBits(end), ...
           'BER at 0 dB must be strictly greater than BER at 10 dB');

    % 4. Full 10-second (80,000 samples) full-scale stress test
    fprintf('Running 10-second stress test (80,000 samples x 8-bit PCM = 640k info bits)...\n');
    stressCfg = struct();
    stressCfg.source = 'synthetic';
    stressCfg.fsTarget = 8000;
    stressCfg.durationSec = 10.0; % Full 10 seconds = 80,000 samples
    stressCfg.pcmBits = 8;
    stressCfg.mu = 255;
    stressCfg.snrDB = 7.0;
    stressCfg.noiseFree = false;
    stressCfg.seed = 123;

    tic;
    stressRes = run_full_system(stressCfg);
    elapsedTime = toc;

    assert(length(stressRes.audioIn) == 80000, 'Audio sample count must be 80,000');
    assert(length(stressRes.pcmBits) == 640000, 'PCM bits must be 640,000');
    assert(length(stressRes.codedBits) == 1280000, 'Coded bits must be 1,280,000');
    assert(length(stressRes.txSymbols) == 640000, 'QPSK symbols must be 640,000');
    assert(length(stressRes.reconstructedAudio) == 80000, 'Reconstructed audio must be 80,000 samples');

    fprintf('10-second stress test completed in %.2f seconds!\n', elapsedTime);
    fprintf('test_full_system: PASS (All integration & stress assertions passed)\n');
end

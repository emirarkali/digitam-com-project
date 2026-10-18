%% test_dm_adm.m - Unit Tests for Linear DM and Adaptive DM (ADM)
function test_dm_adm()
    fprintf('Running test_dm_adm...\n');
    addpath(genpath('src'));

    % 1. Constant signal test (hunting/granular noise in DM)
    constSig = 0.5 * ones(200, 1);
    [dmBits, dmSig, ~] = dm_encoder(constSig, 0.05, 0);
    dmRec = dm_decoder(dmBits, 0.05, 0);
    assert(max(abs(dmSig - dmRec)) < 1e-12, 'DM constant signal roundtrip mismatch');
    % Alternating bits around constant value
    assert(any(dmBits == 0) && any(dmBits == 1), 'DM on constant level must hunt (alternate bits)');

    % 2. Sinusoid test and DM synchronization
    fs = 8000;
    t = (0:1999)' / fs;
    sineSig = 0.8 * sin(2 * pi * 100 * t);
    delta = 0.02;
    [dmBitsSine, dmSigSine, dmState] = dm_encoder(sineSig, delta, 0);
    dmRecSine = dm_decoder(dmBitsSine, delta, 0);
    assert(max(abs(dmSigSine - dmRecSine)) < 1e-12, 'DM sinusoidal roundtrip mismatch');
    assert(dmState.numSamples == 2000, 'Sample count mismatch');

    % 3. ADM encoder/decoder exact synchronization
    delta0 = 0.02;
    deltaMin = 0.005;
    deltaMax = 0.25;
    [admBits, admSig, admState] = adm_encoder(sineSig, delta0, deltaMin, deltaMax, 0);
    admRec = adm_decoder(admBits, delta0, deltaMin, deltaMax, 0);
    assert(max(abs(admSig - admRec)) < 1e-12, 'ADM exact synchronization failure');

    % 4. ADM Step-size boundary clamping assertions
    assert(all(admState.stepSizes >= deltaMin - 1e-12), 'ADM step fell below deltaMin');
    assert(all(admState.stepSizes <= deltaMax + 1e-12), 'ADM step exceeded deltaMax');

    % 5. Rapid ramp test: verify ADM adapts faster than fixed DM (mitigates slope overload)
    rampSig = min(1.0, (0:499)' * 0.01); % Fast rising edge
    [~, dmRamp, ~] = dm_encoder(rampSig, 0.005, 0); % Deliberately small fixed step
    [~, admRamp, ~] = adm_encoder(rampSig, 0.005, 0.002, 0.1, 0, 1.8, 0.6);
    
    % ADM MSE during ramp should be significantly lower due to step expansion
    errDM = mean((rampSig - dmRamp).^2);
    errADM = mean((rampSig - admRamp).^2);
    assert(errADM < errDM, 'ADM should have lower MSE than small-step DM during steep slopes');

    fprintf('test_dm_adm: PASS (All assertions passed, Ramp MSE DM: %.4e, ADM: %.4e)\n', errDM, errADM);
end

%% run_all_tests.m - Master Test Suite Runner for Project 7
% Runs all unit and integration tests and prints a comprehensive status summary.

function allPassed = run_all_tests()
    clc;
    fprintf('=================================================================\n');
    fprintf('   PROJECT 7 DIGITAL COMMUNICATION SYSTEM - MASTER TEST SUITE    \n');
    fprintf('=================================================================\n');

    % Add paths
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    if isempty(projectRoot)
        projectRoot = pwd;
    end
    addpath(genpath(fullfile(projectRoot, 'src')));
    addpath(genpath(fullfile(projectRoot, 'tests')));

    testList = {
        'test_pcm',            @test_pcm;
        'test_dm_adm',         @test_dm_adm;
        'test_channel_coding', @test_channel_coding;
        'test_qpsk',           @test_qpsk;
        'test_awgn',           @test_awgn;
        'test_full_system',    @test_full_system
    };

    numTests = size(testList, 1);
    testResults = cell(numTests, 3); % Name, Status, ElapsedTime

    totalTimer = tic;
    allPassed = true;

    for i = 1:numTests
        testName = testList{i, 1};
        testFunc = testList{i, 2};
        
        fprintf('\n[%d/%d] Executing %s...\n', i, numTests, testName);
        tStep = tic;
        try
            testFunc();
            elapsed = toc(tStep);
            testResults{i, 1} = testName;
            testResults{i, 2} = 'PASS';
            testResults{i, 3} = elapsed;
            fprintf('>>> %s PASSED (%.3f s)\n', testName, elapsed);
        catch ME
            elapsed = toc(tStep);
            testResults{i, 1} = testName;
            testResults{i, 2} = 'FAIL';
            testResults{i, 3} = elapsed;
            allPassed = false;
            fprintf('>>> %s FAILED (%.3f s): %s\n', testName, elapsed, ME.message);
            disp(getReport(ME));
        end
    end

    totalElapsed = toc(totalTimer);

    fprintf('\n=================================================================\n');
    fprintf('                        TEST SUITE SUMMARY                       \n');
    fprintf('=================================================================\n');
    fprintf('%-25s | %-10s | %-10s\n', 'Test Module', 'Outcome', 'Time (s)');
    fprintf('-----------------------------------------------------------------\n');
    for i = 1:numTests
        fprintf('%-25s | %-10s | %8.3f s\n', ...
                testResults{i, 1}, testResults{i, 2}, testResults{i, 3});
    end
    fprintf('-----------------------------------------------------------------\n');
    if allPassed
        fprintf('OVERALL OUTCOME: ALL TESTS PASSED SUCCESSFULLY! (Total: %.2f s)\n', totalElapsed);
    else
        fprintf('OVERALL OUTCOME: SOME TESTS FAILED! (Total: %.2f s)\n', totalElapsed);
    end
    fprintf('=================================================================\n');
end

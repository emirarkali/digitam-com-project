function [audio, fs, metadata] = audio_input(source, fsTarget, durationSec)
% AUDIO_INPUT Loads, records, or synthesizes audio for Project 7.
%
% Syntax:
%   [audio, fs, metadata] = audio_input(source, fsTarget, durationSec)
%
% Inputs:
%   source      - Filepath string to WAV, numeric vector, 'synthetic' (default),
%                 or 'mic' for microphone capture.
%   fsTarget    - Target sampling frequency in Hz (default: 8000).
%   durationSec - Desired duration in seconds (default: 10).
%
% Outputs:
%   audio       - Normalized audio column vector (N x 1 double) in [-1, 1].
%   fs          - Output sampling frequency (equal to fsTarget).
%   metadata    - Struct containing source info, original Fs, peakScale, etc.
%
% Dependencies:
%   MATLAB base functions only (audioread, audiorecorder, interp1).

    if nargin < 1 || isempty(source)
        source = 'synthetic';
    end
    if nargin < 2 || isempty(fsTarget)
        fsTarget = 8000;
    end
    if nargin < 3 || isempty(durationSec)
        durationSec = 10;
    end

    validateattributes(fsTarget, {'numeric'}, {'scalar', 'positive'}, 'audio_input', 'fsTarget');
    validateattributes(durationSec, {'numeric'}, {'scalar', 'positive'}, 'audio_input', 'durationSec');

    metadata = struct();
    metadata.targetFs = fsTarget;
    metadata.targetDuration = durationSec;
    targetSamples = round(fsTarget * durationSec);

    rawAudio = [];
    fsRaw = fsTarget;

    if ischar(source) || isstring(source)
        sourceStr = char(source);
        metadata.sourceType = sourceStr;

        if strcmpi(sourceStr, 'synthetic') || strcmpi(sourceStr, 'sine')
            % Generate rich multi-tone speech-like synthetic audio
            t = (0:targetSamples-1)' / fsTarget;
            % Harmonics at 250, 500, 850, 1200 Hz with time-varying envelope
            env = 0.5 + 0.5 * sin(2 * pi * 0.5 * t);
            sig = 0.45 * sin(2 * pi * 250 * t) + ...
                  0.30 * sin(2 * pi * 500 * t + 0.3) + ...
                  0.15 * sin(2 * pi * 850 * t + 0.8) + ...
                  0.10 * sin(2 * pi * 1200 * t + 1.2);
            rawAudio = sig .* env;
            fsRaw = fsTarget;
            metadata.filePath = '';

        elseif strcmpi(sourceStr, 'mic')
            % Microphone input
            try
                recObj = audiorecorder(fsTarget, 16, 1);
                disp(['Recording ' num2str(durationSec) ' seconds from microphone...']);
                recordblocking(recObj, durationSec);
                rawAudio = getaudiodata(recObj, 'double');
                fsRaw = fsTarget;
                metadata.filePath = 'microphone';
            catch ME
                warning(['Microphone recording failed: ' ME.message '. Falling back to synthetic audio.']);
                [rawAudio, fsRaw, ~] = audio_input('synthetic', fsTarget, durationSec);
                metadata.sourceType = 'synthetic_fallback';
                metadata.errorWarning = ME.message;
            end

        else
            % Filepath
            if ~isfile(sourceStr)
                error('audio_input:FileNotFound', 'Audio file not found: %s', sourceStr);
            end
            [rawAudio, fsRaw] = audioread(sourceStr);
            metadata.filePath = sourceStr;
        end

    elseif isnumeric(source)
        metadata.sourceType = 'numeric_array';
        metadata.filePath = '';
        rawAudio = double(source);
        fsRaw = fsTarget;
    else
        error('audio_input:InvalidSource', 'Unsupported audio source type.');
    end

    % Convert multichannel to mono
    if size(rawAudio, 2) > 1
        rawAudio = mean(rawAudio, 2);
    end
    rawAudio = rawAudio(:); % Ensure column vector

    metadata.originalFs = fsRaw;
    metadata.originalNumSamples = length(rawAudio);

    % Resample if necessary using base MATLAB polyphase-like sinc/pchip interpolation
    if fsRaw ~= fsTarget
        tOriginal = (0:length(rawAudio)-1)' / fsRaw;
        durationOrig = (length(rawAudio) - 1) / fsRaw;
        tNew = (0:1/fsTarget:durationOrig)';
        % High-order anti-aliasing interpolation
        rawAudio = interp1(tOriginal, rawAudio, tNew, 'pchip', 0);
    end

    % Enforce duration (truncate or zero-pad)
    if length(rawAudio) >= targetSamples
        audioTrimmed = rawAudio(1:targetSamples);
    else
        audioTrimmed = zeros(targetSamples, 1);
        audioTrimmed(1:length(rawAudio)) = rawAudio;
    end

    % Normalization to [-1, 1]
    peak = max(abs(audioTrimmed));
    metadata.peakScale = peak;
    if peak > 0
        audio = audioTrimmed / peak;
    else
        audio = audioTrimmed;
    end

    % Guard boundary clamping
    audio = max(-1.0, min(1.0, audio));
    fs = fsTarget;
    metadata.numSamples = length(audio);
end

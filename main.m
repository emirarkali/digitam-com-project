%% PROJECT 7 - DIGITAL COMMUNICATION SYSTEM
% Source -> PCM -> Channel Encoder -> QPSK -> AWGN
% -> QPSK Demodulator -> Channel Decoder -> PCM Decoder

clear;
clc;
close all;

addpath(genpath('src'));

%% Parameters
fs = 8000;
duration = 10;
mu = 255;
pcmBits = 8;
snrDB = 5;

%% TODO: Load audio

%% TODO: PCM encoding

%% TODO: Channel encoding

%% TODO: QPSK modulation

%% TODO: AWGN channel

%% TODO: QPSK demodulation

%% TODO: Channel decoding

%% TODO: PCM decoding

%% TODO: BER / SQNR analysis

disp('Project 7 skeleton initialized.');

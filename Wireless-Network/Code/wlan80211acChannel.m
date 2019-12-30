function [rxSig, noiseVar] = wlan80211acChannel(txSig, params, SNR)

%% Propagation Channel and Noise
% TGac channel object
TGacChan = wlanTGacChannel( ...
    'SampleRate',              params.Rs, ...
    'DelayProfile',            params.chMdl, ...
    'ChannelBandwidth',        params.chanBW, ...
    'NumTransmitAntennas',     params.numTx, ...
    'NumReceiveAntennas',      params.numRx, ...
    'NormalizeChannelOutputs', false, ... % SNR is per receive antenna
    'LargeScaleFadingEffect',  'None');   % No path loss or shadowing
% Pass through TGac fading channel
chanOut = step(TGacChan, txSig);
% reset(TGacChan); % Independent channels from one packet to next

% AWGN channel object
AWGN = comm.AWGNChannel( ...
    'NoiseMethod', 'Signal to noise ratio (SNR)');
AWGN.SNR = SNR;
noiseVar = 10^(-SNR/10);

% Add AWGN
rxSig = step(AWGN, chanOut);

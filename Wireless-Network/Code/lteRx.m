function [rxBits]= lteRx(rxWaveform, enb, PDSCH)


%% Receiver
rxSubframe = lteOFDMDemodulate(enb,rxWaveform);

% Channel Estimator Configuration
cec = struct;                        % Channel estimation config structure
cec.PilotAverage = 'UserDefined';    % Type of pilot symbol averaging
cec.PilotAverage = 'UserDefined';    % Type of pilot symbol averaging
cec.FreqWindow = 9;                  % Frequency window size
cec.TimeWindow = 9;                  % Time window size
cec.InterpType = 'Cubic';            % 2D interpolation type
cec.InterpWindow = 'Centered';       % Interpolation window type
cec.InterpWinSize = 1;               % Interpolation window size

% Equalization and channel estimation
[estChannelGrid,noiseEst] = lteDLChannelEstimate(enb,cec, rxSubframe);
% Perform deprecoding, layer demapping, demodulation and
% descrambling on the received data using the estimate of the channel
PDSCH.CSI = 'On'; % Use soft decision scaling
[rxEncodedBits, rxCW] = ltePDSCHDecode(enb,PDSCH,rxSubframe,estChannelGrid,noiseEst);

% Decode DownLink Shared Channel (DL-SCH)
PDSCH.NTurboDecIts = 5;
if iscell(rxEncodedBits) && ~iscell(PDSCH.Modulation)
   [decbits,crc] = lteDLSCHDecode(enb,PDSCH,PDSCH.TrBlkSize,rxEncodedBits{1});
else
   [decbits,crc] = lteDLSCHDecode(enb,PDSCH,PDSCH.TrBlkSize,rxEncodedBits);
end
rxBits = decbits;

function [rxBits] = wlan80211acReceiver(rxSig, params, noiseVar)
%%
% Create dummy VHT configuration for that bandwidth
cfgVHT = wlanVHTConfig('ChannelBandwidth',params.chanBW);
cfgVHT.APEPLength = 0;  % Number of data bytes is still unknown
% Obtain starting and ending indices for each field
fieldIdx = wlanFieldIndices(cfgVHT);

%% Packet detection
pktStartIdx = double(packetDetect1(rxSig, params.chanBW));

% M = max(abs(real(rxSig(:,1)))) * 1.1;

%% Coarse frequency offset estimation using L-STF
myIndex0 = fieldIdx.LSTF(1):fieldIdx.LSTF(2);
myIndex1 = pktStartIdx(1)+double(myIndex0);
LSTF = rxSig(myIndex1, :);
coarseFreqOffset = wlanCoarseCFOEstimate(LSTF, params.chanBW);

% Phase offset compensation object
myIndex=pktStartIdx(1)+1;
rxSig(myIndex:end,:) = helperFrequencyOffset(...
    rxSig(myIndex:end,:), params.Rs, -coarseFreqOffset);

% PFO = comm.PhaseFrequencyOffset( ...
%     'FrequencyOffsetSource', 'Input port', ...
%     'SampleRate',            params.Rs);
% % Coarse frequency offset compensation
% rxSig(myIndex:end,:) = step(PFO, rxSig(myIndex:end,:), -coarseFreqOffset);
% release(PFO);
%% Symbol timing synchronization based on L-LTF
myIndex0=pktStartIdx(1) + double(fieldIdx.LSTF(2))/2;
myIndex1= myIndex0 + (0:double(fieldIdx.LLTF(2))-1);
LLTFSearchBuffer = rxSig(myIndex1, :); % 4 OFDM symbols to search for L-LTF
LLTFStartIdx = symbolTiming(LLTFSearchBuffer, params.chanBW);

% Adjust packet starting index based on symbol timing
pktStartIdx = pktStartIdx + LLTFStartIdx - 1 - double(fieldIdx.LSTF(2))/2;
% M = max(abs(real(rxSig(:,1)))) * 1.1;

% Align with packet starting index
rxSig = rxSig(pktStartIdx(1):end, :);

%% Fine frequency offset estimation using L-LTF
LLTF = rxSig(fieldIdx.LLTF(1):fieldIdx.LLTF(2), :);
freqOffset = wlanFineCFOEstimate(LLTF, params.chanBW);
% 
% % Frequency offset compensation
% rxSig = step(PFO, rxSig, -freqOffset);
rxSig = helperFrequencyOffset(rxSig, params.Rs, -freqOffset);

%% Channel estimation using L-LTF
LLTF = rxSig(fieldIdx.LLTF(1):fieldIdx.LLTF(2), :);
demodLLTF = wlanLLTFDemodulate(LLTF, params.chanBW);
chanEstLLTF = wlanLLTFChannelEstimate(demodLLTF, params.chanBW);

%% Recover L-SIG and VHT-SIG-A fields
% Recover L-SIG field bits
[recLSIGBits, failCheck] = wlanLSIGRecover( ...
    rxSig(fieldIdx.LSIG(1):fieldIdx.LSIG(2), :), ...
    chanEstLLTF, noiseVar, params.chanBW);

% Recover VHT-SIG-A field bits
[recVHTSIGABits, failCRC] = wlanVHTSIGARecover( ...
    rxSig(fieldIdx.VHTSIGA(1):fieldIdx.VHTSIGA(2), :), ...
    chanEstLLTF, noiseVar, params.chanBW);

% Retrieve packet parameters based on decoded L-SIG and VHT-SIG-A
cfgVHTRx = vhtConfigRecover1(recLSIGBits, recVHTSIGABits);
% Retrieve length of all fields and data, now that we've read L-SIG and VHT-SIG-A
fieldIdxRx = wlanFieldIndices(cfgVHTRx);

%% Estimate MIMO channel using VHT-LTF and retrieved packet parameters
demodVHTLTF = wlanVHTLTFDemodulate( ...
    rxSig(fieldIdxRx.VHTLTF(1):fieldIdxRx.VHTLTF(2), :), cfgVHTRx);
chanEstVHTLTF = wlanVHTLTFChannelEstimate(demodVHTLTF, cfgVHTRx);

%% Recover PSDU bits using retrieved packet parameters and
% channel estimates from VHT-LTF
[rxBits] = wlanVHTDataRecover1( ...
    rxSig(fieldIdxRx.VHTData(1):fieldIdxRx.VHTData(2), :), ...
    chanEstVHTLTF, noiseVar, cfgVHTRx);
numBits=8*params.APEPLen;
rxBits = double(rxBits(1:numBits));
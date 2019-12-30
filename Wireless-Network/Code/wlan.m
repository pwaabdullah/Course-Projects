function [ber, per, dataRate] = wlan(SNR)
%% Set parameters
params.chanBW= 'CBW20';
params.Rs= 20000000;
params.chMdl= 'Model-D';
params.numTx= 2;
params.numRx= 2;
params.STBC= true;
params.MCS= 5;
params.APEPLen= 2048;
%% Initialize measurement objects
% clear wlanReportRateError;
[Hber]=wlanVisualize_init(params);
%% Generate input bits
numBits=8*params.APEPLen;
txBits = randi([0,1], numBits, 1);
%% Run Transceiver (Transmiter-Channel-Receiver)
[txSig, rxBits]= wlan80211acTxChRx(txBits, params, SNR);
%% Update metrics (BER, PER, Bit-rate)
[ber, per, dataRate]=wlanReportRateError(Hber, txBits, rxBits, txSig, params);

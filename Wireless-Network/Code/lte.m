function [ber, per, dataRate] = lte(SNR)
%% Set parameters
params.profile='EPA';
params.doppler= 5;
params.corrProfile= 'Low';
params.Rs= 20000000;
params.APEPLen= 2048;
%% Initialize measurement objects
clear lteReportRateError lteBitRate;
[enb, PDSCH, MCS1]=lteSetParams(5);
info=lteOFDMInfo(enb);
Rs=info.SamplingRate;
[Hber]=lteVisualize_init(enb, PDSCH);
channel=lteSetChannel(enb, PDSCH, params);
%% Generate input bits
txBits =lteGenerateBits(PDSCH);
%% Run Transceiver (Transmiter-Channel-Receiver)
[txWaveform, rxBits] = lteTxChRx(txBits, enb, PDSCH, MCS1, channel, SNR);
%% Update metrics (BER, PER, Bit-rate)
[ber, per, dataRate]=lteReportRateError(Hber, txBits, rxBits, txWaveform,params, Rs);
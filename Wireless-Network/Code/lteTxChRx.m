function [txWaveform, rxBits]=...
    lteTxChRx(txBits, enb, PDSCH, MCS1, channel, SNRdB)
%% Apply transmitter operations
[txWaveform]= lteTx(enb, PDSCH, MCS1, txBits);
%% Apply Channel modeling
rxWaveform= lteCh(txWaveform,enb,channel,SNRdB);
%% Apply receiver operations
[rxBits]= lteRx(rxWaveform, enb, PDSCH);
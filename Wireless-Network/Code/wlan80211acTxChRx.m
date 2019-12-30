function [txSig, rxBits]  = wlan80211acTxChRx(txBits, params, SNR)
%% Apply transmitter operations (waveform generation)
[txSig] = wlan80211acTransmitter(params, txBits);
%% Apply Channel modeling
[rxSig, noiseVar] = wlan80211acChannel(txSig, params, SNR);
%% Apply receiver operations
[rxBits]  = wlan80211acReceiver(rxSig, params, noiseVar);
end

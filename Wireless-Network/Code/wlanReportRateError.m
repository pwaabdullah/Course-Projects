function [ber, per, dataRate]= wlanReportRateError(Hber, txBits, rxBits, txSig, params)
%% Initialization 
persistent perCount totalCount
if isempty(perCount), perCount=0;totalCount=0;end;
%% Packet error computation
totalCount=totalCount+1;
if (~any(rxBits ~= txBits))
    ACK=1;
else
    ACK=0;
    perCount=perCount+1;
end
per=perCount/totalCount;
%% Bit error computation
berV=step(Hber,logical(txBits), logical(rxBits));
ber=berV(1);
%% Data rate computation
numBits = 8* params.APEPLen*(1-ber);
numSecs = size(txSig,1)/params.Rs;
dataRate = numBits/numSecs*1e-1;
end
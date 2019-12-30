function txBitsAll=padInputData(txBitsTotal, numBits,Npackets)
dataLength= numel(txBitsTotal);
paddedLength=Npackets*numBits;
numPadding=paddedLength-dataLength;
txBitsAll=[txBitsTotal;txBitsTotal(1:numPadding)];
if numel(txBitsAll)~= paddedLength, disp('Fix size error');end;
txBitsAll=reshape(txBitsAll,numBits,Npackets);
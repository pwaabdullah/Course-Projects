function txBits =lteGenerateBits(PDSCH)
if ~iscell(PDSCH.Modulation)
    TrBlkLen = PDSCH.TrBlkSize;
    txBits = randi([0, 1], TrBlkLen, 1);
else
    TrBlkLen1 = PDSCH.TrBlkSize(1);
    TrBlkLen2 = PDSCH.TrBlkSize(2);
    Bits1=randi([0, 1], TrBlkLen1, 1);
    Bits2=randi([0, 1], TrBlkLen2, 1);
    txBits = {Bits1, Bits2};
end
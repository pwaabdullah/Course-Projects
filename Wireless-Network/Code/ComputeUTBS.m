function [PDSCH,MCS] = ComputeUTBS(PDSCH,NrLayersCW,CW)
% Compute uncoded transport block size
NumberofPRBs = numel(PDSCH.PRBSet);
% Use the number of layers to compute the TBS
AllValues = double(lteTBS(NumberofPRBs,0:26,NrLayersCW));
% Determine current modulation scheme
if iscell(PDSCH.Modulation)
    Modulation = PDSCH.Modulation{CW};
else
    Modulation = PDSCH.Modulation;
end
switch Modulation
    case 'QPSK'
        PossibleTBS = AllValues(1:10);
        MCSOffset = 0;  % offset used to compute MCS value
    case '16QAM'
        PossibleTBS = AllValues(10:16);
        MCSOffset = 10;  % offset used to compute MCS value
    otherwise
        PossibleTBS = AllValues(16:27);
        MCSOffset = 17;  % offset used to compute MCS value
end

% Compute the possible TBS sizes after block segmentation & CRC
PossibleTBSAfterSegmentation = zeros(size(PossibleTBS));
for nrTBS = 1:numel(PossibleTBS)
    info = lteDLSCHInfo(PossibleTBS(nrTBS));
    PossibleTBSAfterSegmentation(nrTBS) = info.Bout;
end
% Then we select the TBS that minimizes the error to the
% desired code rate

CodedTrBlkSize = PDSCH.CodedTrBlkSize(CW);

[~,ind] = min(abs(PossibleTBSAfterSegmentation/double(CodedTrBlkSize) - PDSCH.TargetCodeRate));

% Compute and report corresponding MCS value
MCS = ind -1 + MCSOffset;

% Assign the computed TBS
if CW == 1
    PDSCH.TrBlkSize = PossibleTBS(ind);
else
    PDSCH.TrBlkSize = [PDSCH.TrBlkSize PossibleTBS(ind)];
end
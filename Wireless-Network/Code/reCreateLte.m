function txWaveform= reCreateLte(enb, PDSCH, MCS1, txSymb)


%% Generate OFDM grid
subframe = lteDLResourceGrid(enb);

%% Add PDCCH
% DCI format
% Can be 'Format0' ,'Format1', 'Format1A', 'Format1B', 'Format1C',
% 'Format1D', 'Format2', 'Format2A', 'Format2B', 'Format2C',
% 'Format3', 'Format3A', or 'Format4'
dciConfig.DCIFormat = 'Format1';

% Build the DCI structure with relevant information
% Bitmap for resource allocation as per TS36.213 section 7.1.6.1
% for resource allocation type 0
dciConfig.Allocation.Bitmap = '1111111111111';
% Modulation and coding scheme & redundancy version
dciConfig.ModCoding = MCS1; 
dciConfig.RV = PDSCH.RV; 

% DCI message
[dciMessage, dciMessageBits] = lteDCI(enb, dciConfig);
% 16-bit value number
pdcchConfig.RNTI = PDSCH.RNTI;
% PDCCH format: 0,1,2 or 3
% Defines the aggregation level in CCEs (Control Channel Elements)
% The level is 2^PDCCHFormat, respectively 1,2,4 and 8
pdcchConfig.PDCCHFormat = 0;

% Performing DCI message bits coding to form coded DCI bits
codedDciBits = lteDCIEncode(pdcchConfig, dciMessageBits);
% Get the total resources for PDCCH
pdcchInfo = ltePDCCHInfo(enb);
% Initialized with -1
pdcchBits = -1*ones(pdcchInfo.MTot, 1);
% Compute all candidates for placement
candidates = ltePDCCHSpace(enb, pdcchConfig, {'bits','1based'});
% Pick the first candidate in the list
pdcchBits( candidates(1, 1) : candidates(1, 2) ) = codedDciBits;
% Modulate the PDCCH and compute the indices for it
pdcchSymbols = ltePDCCH(enb, pdcchBits);
pdcchIndices = ltePDCCHIndices(enb, {'1based'});
% Map PDCCH to the grid
subframe(pdcchIndices) = pdcchSymbols;

%% Add Cell-Specific Reference Signals
cellRSIndices = lteCellRSIndices(enb);
cellRSSymbols = lteCellRS(enb);
subframe(cellRSIndices) = cellRSSymbols;

%% Add BCH
if mod(enb.NSubframe,10) == 0
    mib = lteMIB(enb);
    pbchIndices = ltePBCHIndices(enb);
    QuarterLength = numel(pbchIndices)/enb.CellRefP; % 240 for Normal prefix, 216 for Extended
    bchcoded = lteBCH(enb,mib);
    pbchSymbols = ltePBCH(enb,bchcoded);
    startBCH = mod(enb.NFrame,4)*QuarterLength;
    pbchSymbolsThisFrame = pbchSymbols(startBCH+(1:QuarterLength),:);
    subframe(pbchIndices) = pbchSymbolsThisFrame;
end

%% Add the synchronization signals
% Generate synchronization signals
pssSym = ltePSS(enb);
sssSym = lteSSS(enb);
pssInd = ltePSSIndices(enb);
sssInd = lteSSSIndices(enb);
% Map synchronization signals to the grid
subframe(pssInd) = pssSym;
subframe(sssInd) = sssSym;

%% Add the CFI
cfiBits = lteCFI(enb);
pcfichSymbols = ltePCFICH(enb, cfiBits);
pcfichIndices = ltePCFICHIndices(enb);
% Map CFI to the grid
subframe(pcfichIndices) = pcfichSymbols;

%% Add the PHICH
HIValue = [0 0 1]; % Map an ACK to the first sequence of the first group
phichSymbols = ltePHICH(enb,HIValue);
phichIndices = ltePHICHIndices(enb);
subframe(phichIndices) = phichSymbols;

%% Add the PDSCH
% Modulate the transport block
pdschSymbols = txSymb;
% Subframe resource allocation
pdschIndices = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);
subframe(pdschIndices) = pdschSymbols;
txWaveform = lteOFDMModulate(enb, subframe);

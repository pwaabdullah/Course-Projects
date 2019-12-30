function outFile = makeCode(P)

P.Codegen.IncludeReceiver=true;

% Determine name of file to generate
% outFile = 'CodeToRun.m';
outFile = GetFileName;
% "indent" is the number of leading white spaces used in myfprintf
indent = 0;

fid = fopen(outFile,'w');
myfprintf(fid,'function [txWaveform, rxWaveform, txBits, rxBits, eqGrid, nonEqGrid ]= %s\n\n', ...
    outFile(1:end-2));

%% Parameters that control the simulation
myfprintf(fid,'\n%%%% Simulation length\n');
myfprintf(fid,'totalNrSubframes = 1;\n');

%% Cell-wide parameters
myfprintf(fid,'\n%%%% Define cell-wide parameters\n');

listFields = fieldnames(P.eNodeB);
for fieldNr = 1:numel(listFields)
    field = listFields{fieldNr};
    
    % Add '%' at beginning of every new line
    description = regexprep(P.eNodeB.(field).description,'\n','\n% ');
    myfprintf(fid,'%% %s\n', description);
    % Comment it out if unused
    if ~P.eNodeB.(field).Active
        myfprintf(fid,'%% Parameter is unused in this configuration\n%% ');
    end
    switch P.eNodeB.(field).Type
        case 'string'
            myfprintf(fid,'enb.%s = ''%s'';\n\n', field, P.eNodeB.(field).value);
        case 'vector'
            myfprintf(fid,'enb.%s = %s;\n\n', field, P.eNodeB.(field).value);
        case 'scalar'
            myfprintf(fid,'enb.%s = %d;\n\n', field, P.eNodeB.(field).value);
    end
end
%     % Add ZeroPowerCSIRSPeriod field if CSIRSPeriod is active
%     if P.eNodeB.CSIRSPeriod.Active
%         myfprintf(fid,'enb.ZeroPowerCSIRSPeriod = ''off'';\n');
%     end


%% Main processing loop
myfprintf(fid,'\n%%%% Main processing loop\n');
NSubframe = P.eNodeB.NSubframe.value;
myfprintf(fid,'for subframeNr = %d+(0:totalNrSubframes-1)\n\n',NSubframe);
indent = indent + 3;

%% PDSCH parameters
myfprintf(fid,'\n%%%% Define the PDSCH parameters\n');

myfprintf(fid,'%% Some of these values could change every subframe\n');
myfprintf(fid,'%% Defining them inside the subframe loop\n');

myfprintf(fid,'%% Subframe number between 0 and 9\n');
myfprintf(fid,'enb.NSubframe = mod(subframeNr,10);\n' );
myfprintf(fid,'enb.NFrame = floor(subframeNr/10);\n\n');

listFields = fieldnames(P.PDSCH);
for fieldNr = 1:numel(listFields)
    field = listFields{fieldNr};
    if ~ismember(field,{'CodedTrBlkSize2','TrBlkSize2','NCodeWords'})
        % Add '%' at beginning of every new line
        description = regexprep(P.PDSCH.(field).description,'\n','\n% ');
        myfprintf(fid,'%% %s\n', description);
        
        % Comment it out if unused. This line adds a %% on the next line
        if ~P.PDSCH.(field).Active
            myfprintf(fid,'%% Parameter is unused in this configuration\n%% ');
        end
    end
    % Print out every field except for CodedTrBlkSize for which we show the
    % computation just after this loop
    if ~ismember(field,{'CodedTrBlkSize','CodedTrBlkSize2','TrBlkSize','TrBlkSize2','NCodeWords'})
        switch P.PDSCH.(field).Type
            case 'string'
                myfprintf(fid,'PDSCH.%s = ''%s'';\n\n', field, P.PDSCH.(field).value);
            case 'vector'
                myfprintf(fid,'PDSCH.%s = %s;\n\n', field, P.PDSCH.(field).value);
            case 'scalar'
                myfprintf(fid,'PDSCH.%s = %d;\n\n', field, P.PDSCH.(field).value);
            case 'cell'  % Modulation
                myfprintf(fid,'PDSCH.%s = repmat({''%s''},1,2);\n\n', field, P.PDSCH.(field).value{1});
        end
    end
    
    if strcmp(field,'RV') && iscell(P.PDSCH.Modulation.value)
        myfprintf(fid,'%% Modify for 2 codewords\n');
        myfprintf(fid,'PDSCH.RV = repmat(PDSCH.RV,1,2);\n\n');
    end
    
    % Coded transport block size
    if strcmp(field,'CodedTrBlkSize')
        % Determine transport block size and indices for PDSCH
        myfprintf(fid,'[pdschIndices,info] = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);\n');
        myfprintf(fid,'%% CodedTrBlkSize is added to the PDSCH structure for convenience\n' );
        myfprintf(fid,'%% It is actually never read by any LTE System Toolbox function\n' );
        myfprintf(fid,'PDSCH.CodedTrBlkSize = info.G;\n' );
        if P.PDSCH.CodedTrBlkSize2.Active
            myfprintf(fid,'%% Here: PDSCH.CodedTrBlkSize = [%d %d]\n\n', ...
                P.PDSCH.CodedTrBlkSize.value, P.PDSCH.CodedTrBlkSize2.value);
        else
            myfprintf(fid,'%% Here: PDSCH.CodedTrBlkSize = %d\n\n', P.PDSCH.CodedTrBlkSize.value);
        end
    end
    
    % For the uncoded transport block size, also show how the list of
    % possible values can be computed from NDLRB and the modulation scheme
    if strcmp(field,'TrBlkSize')
        
        myfprintf(fid,'%% Determine possible uncoded transport block sizes based on the number of\n');
        myfprintf(fid,'%% resource blocks allocated to the PDSCH and the modulation scheme\n');
        myfprintf(fid,'\n');
        % For TxDiversity, do not use actual NLayers to compute TBSs.
        % For other TxScheme below, we know NLayers is always 1 anyway
        if ~ismember(P.PDSCH.TxScheme.value,{'Port7-8','Port7-14','SpatialMux','MU-MIMO','CDD'})
            myfprintf(fid,'NrLayersCW1 = 1;\n');
        else
            myfprintf(fid,'%% The number of layers that CW1 is mapped to is:\n');
            myfprintf(fid,'if iscell(PDSCH.Modulation)\n');
            myfprintf(fid,'   NCodeWords = numel(PDSCH.Modulation);\n');
            myfprintf(fid,'else\n');
            myfprintf(fid,'   NCodeWords = 1;\n');
            myfprintf(fid,'end\n');
            myfprintf(fid,'NrLayersCW1 = floor(PDSCH.NLayers/NCodeWords);\n');
        end
        myfprintf(fid,'%% Use the number of layers to compute the TBS\n');
        myfprintf(fid,'[PDSCH,MCS1] = ComputeUTBS(PDSCH,NrLayersCW1,1);\n');
        myfprintf(fid,'\n');
        % Add the code for the second codeword only for TxScheme that allow
        % two codewords
        if ismember(P.PDSCH.TxScheme.value,{'Port7-8','Port7-14','SpatialMux','MU-MIMO','CDD'})
            myfprintf(fid,'if NCodeWords == 2\n');
            myfprintf(fid,'   %% The number of layers that CW2 is mapped to is:\n');
            myfprintf(fid,'   NrLayersCW2 = ceil(PDSCH.NLayers/NCodeWords);\n');
            myfprintf(fid,'   %% Use the number of layers to compute the TBS\n');
            myfprintf(fid,'   [PDSCH,MCS2] = ComputeUTBS(PDSCH,NrLayersCW2,2);\n');
            myfprintf(fid,'end\n');
        end
        
    end
    
end


%% Cell-wide parameters
myfprintf(fid,'\n%%%% Generate OFDM grid\n');

% Generate empty grid
% The size of the grid depends on whether the NTxAnts field is enabled or
% not
if P.PDSCH.NTxAnts.Active % && (P.PDSCH.NTxAnts.value >
    myfprintf(fid,'GridSize = max(PDSCH.NTxAnts,enb.CellRefP);\n');
    SecondArg = ',GridSize';
else
    SecondArg = '';
end
myfprintf(fid,'subframe = lteDLResourceGrid(enb%s);\n', SecondArg);

if P.Codegen.VisualizeGrid
    myfprintf(fid,'%% Visualization\n');
    myfprintf(fid,'colors = ones(lteDLResourceGridSize(enb%s));\n', SecondArg);
end

%% Add PDCCH
if P.Signals.PDCCH
    myfprintf(fid,'\n%%%% Add PDCCH\n');
    description = regexprep(P.PDCCH.DCIFormat.description,'\n','\n% ');
    myfprintf(fid,'%% %s\n', description);
    myfprintf(fid,'dciConfig.DCIFormat = ''%s'';\n', P.PDCCH.DCIFormat.value);
    % Start building the DCI information
    myfprintf(fid,'\n%% Build the DCI structure with relevant information\n');
    % Add RIV field if there is one
    if P.PDCCH.AllocationRIV.Active
        description = regexprep(P.PDCCH.AllocationRIV.description,'\n','\n% ');
        myfprintf(fid,'%% %s\n', description);
        if P.Codegen.IncludeBitmapRIV
            myfprintf(fid,'dciConfig.Allocation.RIV = ComputeRIV(enb.NDLRB, numel(PDSCH.PRBSet), min(PDSCH.PRBSet));\n');
        else
            myfprintf(fid,'dciConfig.Allocation.RIV = %d;\n', P.PDCCH.AllocationRIV.value);
        end
    end
    % Add bitmap field if there is one
    if P.PDCCH.AllocationBitmap.Active
        description = regexprep(P.PDCCH.AllocationBitmap.description,'\n','\n% ');
        myfprintf(fid,'%% %s\n', description);
        if P.Codegen.IncludeBitmapRIV
            myfprintf(fid,'dciConfig.Allocation.Bitmap = ComputeBitmap(enb.NDLRB, PDSCH.PRBSet);\n');
        else
            myfprintf(fid,'dciConfig.Allocation.Bitmap = ''%s'';\n', P.PDCCH.AllocationBitmap.value);
        end
    end
    myfprintf(fid,'%% Modulation and coding scheme & redundancy version\n');
    if ismember(P.PDSCH.TxScheme.value,{'CDD','MultiUser','Port7-8','Port8','Port7-14'})
        myfprintf(fid,'dciConfig.ModCoding1 = MCS1; \n');
        myfprintf(fid,'dciConfig.RV1 = PDSCH.RV(1); \n');
        if (P.PDSCH.NCodeWords.value == 2)
            myfprintf(fid,'dciConfig.ModCoding2 = MCS2; \n');
            myfprintf(fid,'dciConfig.RV2 = PDSCH.RV(2); \n');
        end
    else
        myfprintf(fid,'dciConfig.ModCoding = MCS1; \n');
        myfprintf(fid,'dciConfig.RV = PDSCH.RV; \n');
    end
    
    myfprintf(fid,'\n%% DCI message\n');
    myfprintf(fid,'[dciMessage, dciMessageBits] = lteDCI(enb, dciConfig);\n');
    
    %     myfprintf(fid,'%% Number of DL-RB in total BW\n');
    %     myfprintf(fid,'pdcchConfig.NDLRB = enb.NDLRB;\n');
    myfprintf(fid,'%% 16-bit value number\n');
    myfprintf(fid,'pdcchConfig.RNTI = PDSCH.RNTI;\n');
    description = regexprep(P.PDCCH.PDCCHFormat.description,'\n','\n% ');
    myfprintf(fid,'%% %s\n', description);
    myfprintf(fid,'pdcchConfig.PDCCHFormat = %s;\n',P.PDCCH.PDCCHFormat.value);
    
    myfprintf(fid,'\n%% Performing DCI message bits coding to form coded DCI bits\n');
    myfprintf(fid,'codedDciBits = lteDCIEncode(pdcchConfig, dciMessageBits);\n');
    
    myfprintf(fid,'%% Get the total resources for PDCCH\n');
    myfprintf(fid,'pdcchInfo = ltePDCCHInfo(enb);\n');
    myfprintf(fid,'%% Initialized with -1\n');
    myfprintf(fid,'pdcchBits = -1*ones(pdcchInfo.MTot, 1);\n');
    
    myfprintf(fid,'%% Compute all candidates for placement\n');
    myfprintf(fid,'candidates = ltePDCCHSpace(enb, pdcchConfig, {''bits'',''1based''});\n');
    
    myfprintf(fid,'%% Pick the first candidate in the list\n');
    myfprintf(fid,'pdcchBits( candidates(1, 1) : candidates(1, 2) ) = codedDciBits;\n');
    
    myfprintf(fid,'%% Modulate the PDCCH and compute the indices for it\n');
    myfprintf(fid,'pdcchSymbols = ltePDCCH(enb, pdcchBits);\n');
    myfprintf(fid,'pdcchIndices = ltePDCCHIndices(enb, {''1based''});\n');
    
    myfprintf(fid,'%% Map PDCCH to the grid\n');
    myfprintf(fid,'subframe(pdcchIndices) = pdcchSymbols;\n');
    if P.Codegen.VisualizeGrid
        myfprintf(fid,'%% Visualization\n');
        myfprintf(fid,'colors(pdcchIndices) = 6;\n');
    end
    
end


%% Cell-Specific Reference Signals
if P.Signals.ReferenceSignals
    myfprintf(fid,'\n%%%% Add Cell-Specific Reference Signals\n');
    myfprintf(fid,'cellRSIndices = lteCellRSIndices(enb);\n');
    myfprintf(fid,'cellRSSymbols = lteCellRS(enb);\n');
    myfprintf(fid,'subframe(cellRSIndices) = cellRSSymbols;\n');
    if P.Codegen.VisualizeGrid
        myfprintf(fid,'%% Visualization\n');
        myfprintf(fid,'colors(cellRSIndices) = 2;\n');
    end
end

% BCH
if P.Signals.BCH
    myfprintf(fid,'\n%%%% Add BCH\n');
    myfprintf(fid,'if mod(enb.NSubframe,10) == 0\n');
    myfprintf(fid,'    mib = lteMIB(enb);\n');
    myfprintf(fid,'    pbchIndices = ltePBCHIndices(enb);\n');
    myfprintf(fid,'    QuarterLength = numel(pbchIndices)/enb.CellRefP; %% 240 for Normal prefix, 216 for Extended\n');
    myfprintf(fid,'    bchcoded = lteBCH(enb,mib);\n');
    myfprintf(fid,'    pbchSymbols = ltePBCH(enb,bchcoded);\n');
    myfprintf(fid,'    startBCH = mod(enb.NFrame,4)*QuarterLength;\n');
    myfprintf(fid,'    pbchSymbolsThisFrame = pbchSymbols(startBCH+(1:QuarterLength),:);\n');
    myfprintf(fid,'    subframe(pbchIndices) = pbchSymbolsThisFrame;\n');
    if P.Codegen.VisualizeGrid
        myfprintf(fid,'    %% Visualization\n');
        myfprintf(fid,'    colors(pbchIndices) = 3;\n');
    end
    myfprintf(fid,'end\n');
    
end

%% PSS and SSS
if P.Signals.PSS
    myfprintf(fid,'\n%%%% Add the synchronization signals\n');
    myfprintf(fid,'%% Generate synchronization signals\n');
    myfprintf(fid,'pssSym = ltePSS(enb);\n');
    myfprintf(fid,'sssSym = lteSSS(enb);\n');
    myfprintf(fid,'pssInd = ltePSSIndices(enb);\n');
    myfprintf(fid,'sssInd = lteSSSIndices(enb);\n');
    
    myfprintf(fid,'%% Map synchronization signals to the grid\n');
    myfprintf(fid,'subframe(pssInd) = pssSym;\n');
    myfprintf(fid,'subframe(sssInd) = sssSym;\n');
    if P.Codegen.VisualizeGrid
        myfprintf(fid,'%% Visualization\n');
        myfprintf(fid,'colors(pssInd) = 4;\n');
        myfprintf(fid,'colors(sssInd) = 4;\n');
    end
end

%% CFI
if P.Signals.CFI
    
    % Add CFI
    myfprintf(fid,'\n%%%% Add the CFI\n');
    myfprintf(fid,'cfiBits = lteCFI(enb);\n');
    myfprintf(fid,'pcfichSymbols = ltePCFICH(enb, cfiBits);\n');
    myfprintf(fid,'pcfichIndices = ltePCFICHIndices(enb);\n');
    myfprintf(fid,'%% Map CFI to the grid\n');
    myfprintf(fid,'subframe(pcfichIndices) = pcfichSymbols;\n');
    if P.Codegen.VisualizeGrid
        myfprintf(fid,'%% Visualization\n');
        myfprintf(fid,'colors(pcfichIndices) = 7;\n');
    end
    
    
    
    
end

%% PHICH
if P.Signals.PHICH
    
    % Add PHICH
    myfprintf(fid,'\n%%%% Add the PHICH\n');
    myfprintf(fid,'HIValue = [0 0 1]; %% Map an ACK to the first sequence of the first group\n');
    myfprintf(fid,'phichSymbols = ltePHICH(enb,HIValue);\n');
    myfprintf(fid,'phichIndices = ltePHICHIndices(enb);\n');
    myfprintf(fid,'subframe(phichIndices) = phichSymbols;\n');
    if P.Codegen.VisualizeGrid
        myfprintf(fid,'%% Visualization\n');
        myfprintf(fid,'colors(phichIndices) = 8;\n');
    end
end

%% PDSCH
if P.Signals.PDSCH
    myfprintf(fid,'\n%%%% Add the PDSCH\n');
    
    myfprintf(fid,'%% Generate the transport block(s)\n');
    % Single codeword
    if strcmp(P.PDSCH.NCodeWords.value,'1')
        myfprintf(fid,'dlschTransportBlk = randi([0 1], PDSCH.TrBlkSize, 1);\n');
    else
        myfprintf(fid,'dlschTransportBlk = { randi([0 1], PDSCH.TrBlkSize(1), 1) randi([0 1], PDSCH.TrBlkSize(2), 1)};\n');
    end
    myfprintf(fid,'txBits = dlschTransportBlk;\n');
    
    myfprintf(fid,'%% Encode the transport block\n');
    myfprintf(fid,'codedTrBlock = lteDLSCH(enb, PDSCH, PDSCH.CodedTrBlkSize, dlschTransportBlk);\n');
    myfprintf(fid,'%% Modulate the transport block\n');
    myfprintf(fid,'pdschSymbols = ltePDSCH(enb, PDSCH, codedTrBlock);\n');
    myfprintf(fid,'%% Subframe resource allocation\n');
    myfprintf(fid,'%%    Note: pdschIndices was computed previously\n');
    myfprintf(fid,'subframe(pdschIndices) = pdschSymbols;\n');
    if P.Codegen.VisualizeGrid
        myfprintf(fid,'%% Visualization\n');
        myfprintf(fid,'colors(pdschIndices) = 5;\n');
    end
end

%% DMRS
if P.Signals.DMRS
    myfprintf(fid,'\n%%%% Add the DMRS\n');
    myfprintf(fid,'%% Generate UE-specific reference signal (UE-RS / DMRS) indices and\n');
    myfprintf(fid,'%% symbols. Note that the symbols are already precoded and the indices\n');
    myfprintf(fid,'%% refer to the transmission antennas\n');
    if ismember(P.PDSCH.TxScheme.value,{'Port7-8','Port8','Port7-14'})
        myfprintf(fid,'PDSCH.NSCID = 0; %% Scrambling code identity - 0 or 1\n');
    end
    myfprintf(fid,'dmrsIndices = lteDMRSIndices(enb,PDSCH);\n');
    myfprintf(fid,'dmrsSymbols = lteDMRS(enb,PDSCH);\n');
    
    myfprintf(fid,'\n%% Map UE-specific reference signal into transmit grid\n');
    myfprintf(fid,'subframe(dmrsIndices) = dmrsSymbols;\n');
    if P.Codegen.VisualizeGrid
        myfprintf(fid,'%% Visualization\n');
        myfprintf(fid,'colors(dmrsIndices) = 9;\n');
    end
end

if P.Codegen.VisualizeGrid
    % Display
    myfprintf(fid,'\n\n%%%% Display\n');
    myfprintf(fid,'hGridDisplay(colors);\n');
    %     myfprintf(fid,'figure;\nhelperPlotResourceGrid(colors(:,:,AntennaPort));\n');
end

myfprintf(fid,'[txWaveform,ofdmInfo] = lteOFDMModulate(enb, subframe);\n');

%% Add the receiver
if P.Codegen.IncludeReceiver
%     myfprintf(fid,'\n%%%% Channel Model\n');
%     myfprintf(fid,'\n%Pass data through the fading channel model\n');
%     myfprintf(fid,'rxWaveform = lteFadingChannel(channel,txWaveform);\n');    
        
    myfprintf(fid,'\n%%%% Additive WGN\n');
    myfprintf(fid,'SNRdB=30;\n');
    myfprintf(fid,'%% Convert dB to linear\n');
    myfprintf(fid,'SNR = 10^(SNRdB/20);\n\n');
    myfprintf(fid,'%% Normalize noise power to take account of sampling rate, which is\n');
    myfprintf(fid,'%% a function of the IFFT size used in OFDM modulation, and the \n');
    myfprintf(fid,'%% number of antennas\n');
    myfprintf(fid,'N0 = 1/(sqrt(2.0*enb.CellRefP*double(ofdmInfo.Nfft))*SNR);\n\n');
    myfprintf(fid,'%% Create additive white Gaussian noise\n');
    myfprintf(fid,'noise = N0*complex(randn(size(txWaveform)), ...\n');
    myfprintf(fid,'                    randn(size(txWaveform)));\n\n');
    myfprintf(fid,'%% Add AWGN to the received time domain waveform\n');
    myfprintf(fid,'rxWaveform = txWaveform + noise;\n');
    
    myfprintf(fid,'\n%%%% Receiver\n');
    myfprintf(fid,'rxSubframe = lteOFDMDemodulate(enb,rxWaveform);\n');
    myfprintf(fid,'\n');
    myfprintf(fid,'%% Channel Estimator Configuration\n');
    myfprintf(fid,'cec = struct;                        %% Channel estimation config structure\n');
    myfprintf(fid,'cec.PilotAverage = ''UserDefined'';    %% Type of pilot symbol averaging\n');
    if ismember(P.PDSCH.TxScheme.value,{'Port5','Port7-8','Port8','Port7-14'})
        myfprintf(fid,'cec.Reference = ''DMRS'';              %% Demodulate using DMRS;\n');
    end
    myfprintf(fid,'cec.PilotAverage = ''UserDefined'';    %% Type of pilot symbol averaging\n');
    if ismember(P.PDSCH.TxScheme.value,{'Port7-8','Port7-14'})
        myfprintf(fid,'cec.FreqWindow = 1;                 %% Frequency window size\n');
        if P.PDSCH.NLayers.value < 5
            myfprintf(fid,'cec.TimeWindow = 2;                 %% Time window size\n');
        else
            myfprintf(fid,'cec.TimeWindow = 4;                 %% Time window size\n');
        end
    else
        myfprintf(fid,'cec.FreqWindow = 9;                  %% Frequency window size\n');
        myfprintf(fid,'cec.TimeWindow = 9;                  %% Time window size\n');
    end
    myfprintf(fid,'cec.InterpType = ''Cubic'';            %% 2D interpolation type\n');
    myfprintf(fid,'cec.InterpWindow = ''Centered'';       %% Interpolation window type\n');
    myfprintf(fid,'cec.InterpWinSize = 1;               %% Interpolation window size\n');
    myfprintf(fid,'\n');
    myfprintf(fid,'%% Equalization and channel estimation\n');
    if ismember(P.PDSCH.TxScheme.value,{'Port5','Port7-8','Port8','Port7-14'})
        myfprintf(fid,'[estChannelGrid,noiseEst] = lteDLChannelEstimate(enb,PDSCH,cec, rxSubframe);\n');
    else
        myfprintf(fid,'[estChannelGrid,noiseEst] = lteDLChannelEstimate(enb,cec, rxSubframe);\n');
    end
    myfprintf(fid,'eqGrid = lteEqualizeMMSE(rxSubframe, estChannelGrid,noiseEst);\n');
    myfprintf(fid,'nonEqGrid = rxSubframe;\n');
    myfprintf(fid,'\n');
    myfprintf(fid,'%% Perform deprecoding, layer demapping, demodulation and\n');
    myfprintf(fid,'%% descrambling on the received data using the estimate of the channel\n');
    myfprintf(fid,'PDSCH.CSI = ''On''; %% Use soft decision scaling\n');
    myfprintf(fid,'rxEncodedBits = ltePDSCHDecode(enb,PDSCH,rxSubframe,estChannelGrid,noiseEst);\n');
    myfprintf(fid,'\n');
    myfprintf(fid,'%% Decode DownLink Shared Channel (DL-SCH)\n');
    myfprintf(fid,'PDSCH.NTurboDecIts = 5;\n');
    myfprintf(fid,'if iscell(rxEncodedBits) && ~iscell(PDSCH.Modulation)\n');
    myfprintf(fid,'   [decbits,crc] = lteDLSCHDecode(enb,PDSCH,PDSCH.TrBlkSize,rxEncodedBits{1});\n');
    myfprintf(fid,'else\n');
    myfprintf(fid,'   [decbits,crc] = lteDLSCHDecode(enb,PDSCH,PDSCH.TrBlkSize,rxEncodedBits);\n');
    myfprintf(fid,'end\n');
    myfprintf(fid,'rxBits = decbits;\n');
    myfprintf(fid,'\n');
    myfprintf(fid,'if crc == 0\n');
    myfprintf(fid,'   fprintf(1,''crc successful\\\\n'');\n');
    myfprintf(fid,'else\n');
    myfprintf(fid,'   fprintf(1,''crc has errors\\\\n'');\n');
    myfprintf(fid,'end\n');
    
end


indent = indent - 3;
myfprintf(fid,'\nend  %%End subframe loop\n\n');

% Add the computation of bitmap and RIV for DCI
fclose(fid);


% This function prints with "indent" leading spaces
    function myfprintf(varargin)
        ToPrint = sprintf(varargin{2:end});
        % Single comment will be replaced with this
        indentComment = [repmat(' ',1,indent) '%%' ];
        % double comment will be replaced with this
        indentDoubleComment = [repmat(' ',1,indent) '%%%%' ];
        % Change double comment to something we can recognize
        ToPrint = regexprep(ToPrint,'%%','SaveDoubleComment');
        % See if string to print starts with a %.
        % If it does, do not use leading space that would be used for any
        % line because comment will be replaced with comment with leading
        % space already. Remember that some lines with comments are
        % multiple line entries
        ind = findstr(strtrim(ToPrint),'%');
        if isempty(ind) || ind(1) ~= 1
            % Doesn't start with single comment
            fprintf(fid,'%s',repmat(' ',1,indent));
        end
        ToPrint = regexprep(ToPrint,'%',indentComment);
        % Cannot just count on the default indent for %% because those are
        % always called as \n%%%%. So, the indent would be before the new
        % line, not the %%. Hence, indent %% separately
        ToPrint = regexprep(ToPrint,'SaveDoubleComment',indentDoubleComment);
        fprintf(fid,ToPrint);
    end
%%
end

function OutFile = GetFileName
% basename = 'CodeToRun';
% index = 1;
% Filename = sprintf('%s_%d.m', basename, index);
% while exist(Filename,'file')
%     index = index + 1;
%     Filename = sprintf('%s_%d.m', basename, index);
% end
basename = 'lteTransmitter';
Filename = sprintf('%s.m', basename);
OutFile = Filename;
end


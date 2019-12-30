function outFile = makeCodeTx(P)


% Determine name of file to generate
% outFile = 'CodeToRun.m';
outFile = GetFileName;
% "indent" is the number of leading white spaces used in myfprintf
indent = 0;

fid = fopen(outFile,'w');
myfprintf(fid,'function [txWaveform, txBits, txCW]= %s(enb, PDSCH, MCS1, txBits)\n\n', ...
    outFile(1:end-2));


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
    
end


%% Cell-Specific Reference Signals
if P.Signals.ReferenceSignals
    myfprintf(fid,'\n%%%% Add Cell-Specific Reference Signals\n');
    myfprintf(fid,'cellRSIndices = lteCellRSIndices(enb);\n');
    myfprintf(fid,'cellRSSymbols = lteCellRS(enb);\n');
    myfprintf(fid,'subframe(cellRSIndices) = cellRSSymbols;\n');
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
   
end

%% PHICH
if P.Signals.PHICH
    
    % Add PHICH
    myfprintf(fid,'\n%%%% Add the PHICH\n');
    myfprintf(fid,'HIValue = [0 0 1]; %% Map an ACK to the first sequence of the first group\n');
    myfprintf(fid,'phichSymbols = ltePHICH(enb,HIValue);\n');
    myfprintf(fid,'phichIndices = ltePHICHIndices(enb);\n');
    myfprintf(fid,'subframe(phichIndices) = phichSymbols;\n');
end

%% PDSCH
if P.Signals.PDSCH
    myfprintf(fid,'\n%%%% Add the PDSCH\n');
    
%     myfprintf(fid,'%% Generate the transport block(s)\n');
%     % Single codeword
%     if strcmp(P.PDSCH.NCodeWords.value,'1')
%         myfprintf(fid,'dlschTransportBlk = randi([0 1], PDSCH.TrBlkSize, 1);\n');
%     else
%         myfprintf(fid,'dlschTransportBlk = { randi([0 1], PDSCH.TrBlkSize(1), 1) randi([0 1], PDSCH.TrBlkSize(2), 1)};\n');
%     end
%     myfprintf(fid,'txBits = dlschTransportBlk;\n');
    
    myfprintf(fid,'%% Encode the transport block\n');
    myfprintf(fid,'codedTrBlock = lteDLSCH(enb, PDSCH, PDSCH.CodedTrBlkSize, txBits);\n');
    myfprintf(fid,'%% Modulate the transport block\n');
    myfprintf(fid,'pdschSymbols = ltePDSCH(enb, PDSCH, codedTrBlock);\n');
    myfprintf(fid,'txCW=pdschSymbols;\n');
    myfprintf(fid,'%% Subframe resource allocation\n');
    myfprintf(fid,'pdschIndices = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);\n');
    myfprintf(fid,'subframe(pdschIndices) = pdschSymbols;\n');

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

end

myfprintf(fid,'txWaveform = lteOFDMModulate(enb, subframe);\n');


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
basename = 'lteTx';
Filename = sprintf('%s.m', basename);
OutFile = Filename;
end


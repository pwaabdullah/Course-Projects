function outFile = makeCodeHz(P)

% "indent" is the number of leading white spaces used in myfprintf
indent = 0;
outFile='lteSetParams.m';
fid = fopen(outFile,'w');
myfprintf(fid,'function [enb, PDSCH, MCS1]=%s(subframeNr)\n\n', outFile(1:end-2));

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
        myfprintf(fid,'[~,info] = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);\n');
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

end


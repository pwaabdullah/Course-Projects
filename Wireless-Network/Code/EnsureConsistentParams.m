function handles = EnsureConsistentParams(handles, flag)
%% Ensures that parameters are consistent
% This function runs a number of consistency checks to ensure that
% parameters are consistent.
% This function changes the reference arrays (handles.PDSCH,
% handles.eNodeB, handles.PDCCH), not the one displayed (handles.Table)
if nargin == 1
    flag = '';
end

message = sprintf('\n');

% Reset message in PDSCH & PDSCH panel
PDSCH_PDCCHInfo = sprintf('\n');

% Store initial list of Active fields in order to compare it to the one at
% the end an be able to report and difference: added or removed fields
handles.ActiveInitial.PDSCH = handles.PDSCH.Active;
handles.ActiveInitial.PDCCH = handles.PDCCH.Active;
handles.ActiveInitial.eNodeB = handles.eNodeB.Active;

% Retrieve current parameters to check for consistency
eNodeB = handles.eNodeB.Data;
PDSCH = handles.PDSCH.Data;
PDCCH = handles.PDCCH.Data;

% PMISet is unnecessary unless set otherwise in switch statement
handles.PDSCH.Active.PMISet = 0;

% W, NTxAnts not needed and no DMRS codegen unless set otherwise below
handles.PDSCH.Active.W = 0;
handles.PDSCH.Active.NTxAnts = 0;
% Disable code generation for DMRS
handles.ChannelsRequested.DMRS = 0;
set(handles.Widgets.hDMRS,'Value',0);

% Disable CSIRefP,CSIRSConfig, and CSIRSPeriod unless set below('Port7-14')
handles.eNodeB.Active.CSIRefP = 0;
handles.eNodeB.Active.CSIRSConfig = 0;
handles.eNodeB.Active.CSIRSPeriod = 0;
handles.eNodeB.Active.ZeroPowerCSIRSPeriod = 0;


% Process the choice of DCI Format for the PDCCH
switch PDSCH.TxScheme
    case 'Port0'
        PDCCH.DCIFormat = 'Format1';
    case 'TxDiversity'
        PDCCH.DCIFormat = 'Format1';
    case 'CDD'
        PDCCH.DCIFormat = 'Format2A';
    case 'SpatialMux'
        % If Nlayers = 1, could be proper spatial mux (TM4), which means 2
        % or TM6 (spatial mux w/ single layer), which means 1B. Here we pick 2 arbitrarily 
        % If more than 1 layer, it is for sure TM4 (format 2)
        % In summary, we always pick format 2 here, meaning we don't
        % support TM6 = spatial mux w/ single layer
        PDCCH.DCIFormat = 'Format2';
    case 'MultiUser'
        PDCCH.DCIFormat = 'Format1D';
    case 'Port5'
        PDCCH.DCIFormat = 'Format1';
    case 'Port7-8'
        PDCCH.DCIFormat = 'Format2B';
    case 'Port8'
        PDCCH.DCIFormat = 'Format2B';
    case 'Port7-14'
        PDCCH.DCIFormat = 'Format2C';
    otherwise   % should never happen
        PDCCH.DCIFormat = 'Format2A';
end

% Select which fields for DCI are active depending on format
if ismember(PDCCH.DCIFormat, {'Format1A', 'Format1B', 'Format1D'})
    % Resource allocation type 2
    handles.PDCCH.Active.AllocationBitmap = 0;
    handles.PDCCH.Active.AllocationRIV = 1;
    AllocationType = 2;
else
    % Resource allocation type 0
    handles.PDCCH.Active.AllocationBitmap = 1;
    handles.PDCCH.Active.AllocationRIV = 0;
    AllocationType = 0;
end
% Display resource allocation
PDSCH_PDCCHInfo = sprintf('%sDCI Resource Allocation Type %d\n', ...
                 PDSCH_PDCCHInfo, AllocationType);

% Double-check the RB assignment
% If resource allocation type 2, can only encode contiguous assignment
PRBSet = str2num(PDSCH.PRBSet);
if handles.PDCCH.Active.AllocationRIV
    % Assignment must be contiguous
    if (max(PRBSet)-min(PRBSet)+1 ~= numel(PRBSet))
        message = sprintf('%sWarning: PRBSet is not contiguous\nDCI message content won''t match PRBSet\n', ...
            message);
    end  
    % Compute RIV
    PDCCH.AllocationRIV = ComputeRIV(eNodeB.NDLRB, numel(PRBSet), min(PRBSet));
else
    % If resource allocation type 0, can only encode by chunks of 1,2 or 4
    % Resource Block Group Size
    % Compute bitmap and detect possible problem with PRBSet
    [Bitmap, Problem] = ComputeBitmap(eNodeB.NDLRB, PRBSet);
    PDCCH.AllocationBitmap = Bitmap;

    if Problem
        message = sprintf('%sWarning: PRBSet does not assign full RBGs\n', ...
            message);
        message = sprintf('%sDCI message content won''t match PRBSet\n', ... 
            message);
    end  
end

% Different decisions depending on the transmission scheme
switch PDSCH.TxScheme
    case 'Port0'
        % Enforce NCodeWords = 1
        [PDSCH,message] = EnforceNCodeWords(PDSCH,message);
        % Enforce Nlayers = 1
        [PDSCH,message] = EnforceNLayers1(PDSCH,message);  
        % Check that CellRefP is 1 if transmission scheme is 'Port0'
        if ~strcmp(eNodeB.CellRefP, '1')
            eNodeB.CellRefP = '1';
            message = sprintf('%sCellRefP must be 1 for ''Port0'' transmission\nChanging it to 1\n', ...
                message);
        end
        
    case 'Port5'
        % Enforce NCodeWords = 1
        [PDSCH,message] = EnforceNCodeWords(PDSCH,message);
        % Enforce Nlayers = 1
        [PDSCH,message] = EnforceNLayers1(PDSCH,message); 
        % Activate W, NTxAnts, DMRS
        handles = ActivateWNTxAntsDRMS(handles);
        
    case 'Port7-8'
        % Enforce Nlayers = 1 or 2
        if (PDSCH.NLayers > 2)
            PDSCH.NLayers = 1;
            message = sprintf('%sNLayers must be 1 or 2 for ''Port7-8'' transmission\nChanging it to 1\n', ...
                message);
        end
        % Activate W, NTxAnts, DMRS
        handles = ActivateWNTxAntsDRMS(handles);
        
    case 'Port8'
        % Enforce NCodeWords = 1
        [PDSCH,message] = EnforceNCodeWords(PDSCH,message);
        % Enforce Nlayers = 1
        [PDSCH,message] = EnforceNLayers1(PDSCH,message); 
        % Activate W, NTxAnts, DMRS
        handles = ActivateWNTxAntsDRMS(handles);
        
    case 'Port7-14'
        % Activate W, NTxAnts, DMRS
        handles = ActivateWNTxAntsDRMS(handles);
        % Activate CSIRefP,CSIRSConfig, and CSIRSPeriod
        handles.eNodeB.Active.CSIRefP = 1;
        handles.eNodeB.Active.CSIRSConfig = 1;
        handles.eNodeB.Active.CSIRSPeriod = 1;
        % NCodeWords must be > 1 if NLayers > 4
        if strcmp(PDSCH.NCodeWords,'1') && (PDSCH.NLayers > 4)
            message = sprintf('%sNCodeWords must be 2 for ''Port7-14'' with more than 4 layers\nChanging it to 2\n', ...
                message);
            PDSCH.NCodeWords = '2';
        end
        % ZeroPowerCSIRSPeriod is active if CSIRSPeriod is anything other
        % than 'off'
        if ~strcmp(eNodeB.CSIRSPeriod,'off')
            handles.eNodeB.Active.ZeroPowerCSIRSPeriod = 1;
        end


    case 'TxDiversity'
        % Enforce NCodeWords = 1
        [PDSCH,message] = EnforceNCodeWords(PDSCH,message);
        % Enforce CellRefP = 2 or 4
        [eNodeB,message] = EnforceDiversity(PDSCH,eNodeB,message);
        % Enforce NLayers <= CellRefP
        [PDSCH,message] = EnforceNLayersCellRefP(PDSCH,eNodeB,message);
       
    case 'SpatialMux'
        % Enforce CellRefP = 2 or 4
        [eNodeB,message] = EnforceDiversity(PDSCH,eNodeB,message);
        % Enforce NLayers <= CellRefP
        [PDSCH,message] = EnforceNLayersCellRefP(PDSCH,eNodeB,message);
        % PMISet is necessary
        handles.PDSCH.Active.PMISet = 1;

    case 'MultiUser'
        % Enforce NLayers <= CellRefP
        [PDSCH,message] = EnforceNLayersCellRefP(PDSCH,eNodeB,message);
        % PMISet is necessary
        handles.PDSCH.Active.PMISet = 1;

    case 'CDD'
        % Enforce NLayers <= CellRefP
        [PDSCH,message] = EnforceNLayersCellRefP(PDSCH,eNodeB,message);
end

% Enforce NCodeWords = 1 if NLayers = 1
if strcmp(PDSCH.NCodeWords,'2') && (PDSCH.NLayers == 1)
    message = sprintf('%sNCodeWords must be 1 when NLayers=1\nChanging it to 1\n', ...
        message);
    PDSCH.NCodeWords = '1';
end

% For MultiUser, NCodeWords = 1 and NLayers <= 2
if strcmp(PDSCH.TxScheme,'MultiUser')
    if ~strcmp(PDSCH.NCodeWords,'1')
        PDSCH.NCodeWords = '1';
        % Display message
        message = sprintf('%sFor MultiUser, NCodewords must be 1\nChanging NCodeWords to 1\n', ...
            message);
    end
    if (PDSCH.NLayers > 2)
        PDSCH.NLayers = 2;
        % Display message
        message = sprintf('%sFor MultiUser, NLayers must be <=2\nChanging it to 2\n', ...
            message);
    end
end

% If TxScheme is 'SpatialMux', 'CDD', Can map 1 codeword to 2
% layers only if CellRefP = 4
% What we want to enforce: 
% If NCodeWords = 1, NLayers can be 1 or 2. It can be 2 only when CellRefP
% is 4
% If NCodeWords = 2, NLayers can be 2,3, or 4
if ismember(PDSCH.TxScheme,{'SpatialMux','CDD'})
    if strcmp(PDSCH.NCodeWords,'1')
        
        if (PDSCH.NLayers == 2)
            if ~strcmp(eNodeB.CellRefP, '4')
                PDSCH.NCodeWords = '2';
                % Display message
                message = sprintf('%sFor SpatialMux, CDD and MultiUser, single codeword to 2 layers requires CellRefP=4\nChanging NCodeWords to 2\n', ...
                    message);
            end
        elseif (PDSCH.NLayers > 2)
            PDSCH.NCodeWords = '2';
            % Display message
            message = sprintf('%sFor SpatialMux, CDD and MultiUser, NLayers > 2 requires two codewords\nChanging NCodeWords to 2\n', ...
                message);
        end
    else % NCodeWords is '2'
        % We know that we have NLayers > 1 (otherwise NCodeWords would not
        % be 1 as per earlier test
        % Besides, we have already enforced NLayers <= CellRefP. So, we
        % should be good
    end
end

% If there are (may be new or not) 2 codewords, make sure we have
% two Modulation and compute two TrBlkSize
if strcmp(PDSCH.NCodeWords,'2')
        handles.PDSCH.Active.TrBlkSize2 = 1;
        handles.PDSCH.Active.CodedTrBlkSize2 = 1;
else
        handles.PDSCH.Active.TrBlkSize2 = 0;
        handles.PDSCH.Active.CodedTrBlkSize2 = 0;
        PDSCH.CodedTrBlkSize2 = 0;
end

% Check that the control region can accomodate the number of REGs
% implied by PDCCHFormat
% Get information about how many REGs are available
% Build enb structure to be able to call ltePDCCHInfo
PDCCHFormatD = str2double(PDCCH.PDCCHFormat);
enb = struct('CellRefP',str2double(eNodeB.CellRefP),'NDLRB',eNodeB.NDLRB, ...
             'CyclicPrefix',eNodeB.CyclicPrefix, 'DuplexMode',eNodeB.DuplexMode, ...
             'CFI',str2double(eNodeB.CFI),'Ng',eNodeB.Ng,'PDCCHFormat',PDCCHFormatD);
resInfo = ltePDCCHInfo(enb);
NREGAvailable = double(resInfo.NREG);
% PDCCHFormat can be 0,1,2,3 corresponding to 9, 18, 36, 72 REGs
% See 36.211 table 6.8.1-1     ie 9*(2^PDCCHFormat);
% Determine max possible value for format
MaxFormat = floor(log2(NREGAvailable/9));
% If set value is too high, replace it with max
if PDCCHFormatD > MaxFormat
    message = sprintf('%sThere are only %d available REGs for PDCCH\n', ...
        message, NREGAvailable);
    message = sprintf('%sThe maximum value for PDCCHFormat is %d (%d REGs).\n Changing it to %d\n', ...
        message, MaxFormat, 9*(2^MaxFormat), MaxFormat);
    PDCCH.PDCCHFormat = num2str(MaxFormat);
end
    


% NTxAnts (if active) must be at least as much as NLayers
if handles.PDSCH.Active.NTxAnts && (PDSCH.NTxAnts < PDSCH.NLayers) 
    message = sprintf('%sNTxAnts must be >= NLayers\nChanging it to %d\n', ...
        message, PDSCH.NLayers);
    PDSCH.NTxAnts = PDSCH.NLayers;
%     handles.PDSCH.Data{indexNTxAnts,2} = NTxAnts; 
end

% Set CFI to 3 if PHCIH is 'Extended'
if strcmp(eNodeB.PHICHDuration,'Extended') && (str2num(eNodeB.CFI) ~= 3)
    % Set CFI to 3
    eNodeB.CFI = '3';
    % Display message
    message = sprintf('%sChanging CFI to 3 to match ''Extended'' PHICH setting\n', ...
        message);
end

% W must be of size NLayers-by-NTxAnts 
% if NTxAnts is active
if handles.PDSCH.Active.W
    WValue = eval(PDSCH.W);
    if (size(WValue,1) ~= PDSCH.NLayers) || (size(WValue,2) ~= PDSCH.NTxAnts)
    message = sprintf('%sBeamforming matrix W must be NLayers(%d)-by-NTxAnts(%d) %d to %d\n', ...
        message,PDSCH.NLayers, PDSCH.NTxAnts);
    message = sprintf('%sChanging it to a random matrix of the correct size\n',message);
    % Set W to random matrix
    PDSCH.W = sprintf('eye(%d,%d)', PDSCH.NLayers, PDSCH.NTxAnts);
    end
end

% Copy changes back to handles
handles.eNodeB.Data = eNodeB;
handles.PDSCH.Data = PDSCH;
handles.PDCCH.Data = PDCCH;
% Compute transport size
TBS = ComputeTBS(handles);
% Detect if it has changed
if ~isequal(PDSCH.CodedTrBlkSize, TBS(1))
    message = sprintf('%sChanging the coded transport block size from %d to %d\n', ...
        message,PDSCH.CodedTrBlkSize, TBS(1));
    % Set transport size in the PDSCH table
    PDSCH.CodedTrBlkSize = TBS(1);
end
if length(TBS) == 2
    if ~isequal(PDSCH.CodedTrBlkSize2, TBS(2))
        message = sprintf('%sChanging the coded transport block size for cw2 from %d to %d\n', ...
            message,PDSCH.CodedTrBlkSize2, TBS(2));
        % Set transport size in the PDSCH table
        PDSCH.CodedTrBlkSize2 = TBS(2);
    end
end

% Determine possible uncoded transport block sizes based on the number of
% resource blocks allocated to the PDSCH and the modulation scheme

% The number of layers that CW1 is mapped to is:
NrLayersCW1 = floor(PDSCH.NLayers/str2double(PDSCH.NCodeWords));
% But if TxDiversity, set it to 1 as there is no parallel stream
if strcmp(PDSCH.TxScheme,'TxDiversity')
    NrLayersCW1 = 1;
end
% Use the number of layers to compute the TBS
[handles,PDSCH,CodeRate,MCSValue] = ComputeUTBS(handles,PDSCH,NrLayersCW1,1);

if strcmp(PDSCH.NCodeWords,'2')
    % The number of layers that CW2 is mapped to is:
    NrLayersCW2 = ceil(PDSCH.NLayers/str2double(PDSCH.NCodeWords));
    % Use the number of layers to compute the TBS
    [handles,PDSCH,CodeRate2,MCSValue2] = ComputeUTBS(handles,PDSCH,NrLayersCW2,2);

    % Display MCS value
    PDSCH_PDCCHInfo = sprintf('%s\nMCS values = [%d %d]\n', ...
        PDSCH_PDCCHInfo, MCSValue, MCSValue2);
    
    % Display actual code rate
    PDSCH_PDCCHInfo = sprintf('%sActual code rates = [%.3f %.3f]\n', ...
        PDSCH_PDCCHInfo, CodeRate, CodeRate2);
    
else
    % Display MCS value
    PDSCH_PDCCHInfo = sprintf('%sMCS value = %d\n', ...
                     PDSCH_PDCCHInfo, MCSValue);

    % Display actual code rate
    PDSCH_PDCCHInfo = sprintf('%sActual code rate = %.3f\n', ...
                     PDSCH_PDCCHInfo, CodeRate);

end


% Store initial list of Active fields in order to compare it to the one at
% the end an be able to report and difference: added or removed fields
handles.ActiveFinal.PDSCH = handles.PDSCH.Active;
handles.ActiveFinal.PDCCH = handles.PDCCH.Active;
handles.ActiveFinal.eNodeB = handles.eNodeB.Active;

message = DetectActiveChange(message,handles);

if isempty(flag)
    handles.Widgets.hMessage.Value = 1;  % Place selection on 1st line
    DisplayMessage(message);
end

% Copy changes back to handles
handles.eNodeB.Data = eNodeB;
handles.PDSCH.Data = PDSCH;
handles.PDCCH.Data = PDCCH;
handles.Widgets.hPDSCH_PDCCHInfo.String = PDSCH_PDCCHInfo;


function [PDSCH,message] = EnforceNCodeWords(PDSCH,message)
    % Enforce NCodeWords = 1
    if strcmp(PDSCH.NCodeWords,'2')
        message = sprintf('%sNCodeWords must be 1 for ''%s''\nChanging it to 1\n', ...
            message, PDSCH.TxScheme);
        PDSCH.NCodeWords = '1';
    end

 function [PDSCH,message] = EnforceNLayers1(PDSCH,message)
     % Enforce NLayers = 1
     if (PDSCH.NLayers ~= 1)
         message = sprintf('%sNLayers must be 1 for ''%s'' transmission\nChanging it to 1\n', ...
             message, PDSCH.TxScheme);
         PDSCH.NLayers = 1;
     end

 function [PDSCH,message] = EnforceNLayersCellRefP(PDSCH,eNodeB,message)
     % Enforce NLayers <= CellRefP
     if (PDSCH.NLayers > str2num(eNodeB.CellRefP))
         message = sprintf('%sNLayers cannot be > CellRefP\nChanging it from %d to %d\n', ...
             message,PDSCH.NLayers,str2num(eNodeB.CellRefP));
         % Set NLayers to CellRefP
         PDSCH.NLayers = str2num(eNodeB.CellRefP);
     end

function [eNodeB,message] = EnforceDiversity(PDSCH,eNodeB,message)
    % Check that number of antenna ports is 2 or 4 for Tx diversity and
    % SpatialMux
    if ~strcmp(eNodeB.CellRefP, '2') &&  ~strcmp(eNodeB.CellRefP, '4')
        % Set CellRefP to 2
        eNodeB.CellRefP = '2';
        % Display message
        message = sprintf('%sCellRefP must be 2 or 4 for ''%s'' transmission\nChanging it to 2\n', ...
            message, PDSCH.TxScheme);
    end

    
function handles = ActivateWNTxAntsDRMS(handles)
    % W and NTxAnts are only needed (active) if TxScheme is 'Port5', 'Port7-8', 'Port8', or 'Port7-14'
    handles.PDSCH.Active.W = 1;
    handles.PDSCH.Active.NTxAnts = 1;
    % Enable code generation for DMRS
    handles.ChannelsRequested.DMRS = 1;
    set(handles.Widgets.hDMRS,'Value',1);

function TBS = ComputeTBS(handles)
% Compute coded transport size
% Pack all info into a structure
P = SummarizeInfo(handles,true);

[~,info] = ltePDSCHIndices(P.eNodeB, P.PDSCH, P.PDSCH.PRBSet);
TBS = info.G;

function P = SummarizeInfo(handles,flat)
P = struct;
% Create all the fields for all tables

% Set frame number to 0 - always. Actual frame will be derived from
% NSubframe
P.eNodeB.NFrame = 0;

% Get list of tables
ListTables = {'eNodeB' 'PDSCH' 'PDCCH'};

% How to determine the type of the field:
% If the field is a scalar, str2double returns NaN, or isnumeric works
% To differentiate between a real string and a string such as '1:4', one
% can use str2num: it returns empty for a character string and an array of
% values for a MATLAB array

for tableNr = 1:numel(ListTables)
    Data = handles.(ListTables{tableNr}).Data;
    Description = handles.(ListTables{tableNr}).Description;
    Active = handles.(ListTables{tableNr}).Active;
    
    ListFields = fieldnames(Data);
    for ii=1:numel(ListFields)
        field = ListFields{ii};
        Value = Data.(field);
        if flat  % when called from ComputeTBS
            % Convert string representing numeric value to actual numeric
            % values: ~isnumeric means it's not already a numeric, so it's
            % a string. ~isempty(str2num(..)) means it represents a number
            % and not a string such as 'QPSK'
            if ~isnumeric(Value) && ~isempty(str2num(Value))
                P.(ListTables{tableNr}).(field) = str2num(Value);
            else
                % If it is a true string value or a numeric already, pass
                % it untouched
                P.(ListTables{tableNr}).(field) = Value;
            end
        else
            if isnumeric(Value)
                Type = 'scalar';
            elseif isempty(str2num(Value))
                Type = 'string';
            else
                Type = 'vector';
            end
            P.(ListTables{tableNr}).(field).value = Value;
            P.(ListTables{tableNr}).(field).description = Description.(field);
            P.(ListTables{tableNr}).(field).Type = Type;
            P.(ListTables{tableNr}).(field).Active = Active.(field);
        end
    end
end

% If there are two codewords, adjust the Modulation field
if strcmp(handles.PDSCH.Data.NCodeWords,'2')
    if flat
        P.PDSCH.Modulation = repmat({P.PDSCH.Modulation},1,2);
    else
        P.PDSCH.Modulation.value = repmat({P.PDSCH.Modulation.value},1,2);
        P.PDSCH.Modulation.Type = 'cell';
    end
end

function message = DetectActiveChange(message,handles)
% This function detects any change in the active fields of any structure
% and generates a message for it
message = AddChangesToMessage(message,handles,'PDSCH');
message = AddChangesToMessage(message,handles,'eNodeB');
message = AddChangesToMessage(message,handles,'PDCCH');

function message = AddChangesToMessage(message,handles,tableName)
ListFields = fieldnames(handles.ActiveInitial.(tableName));
ListRemoved = '';
ListAdded = '';
for ii=1:numel(ListFields)
    field = ListFields{ii};
    if handles.ActiveInitial.(tableName).(field) == 1 && ...
            handles.ActiveFinal.(tableName).(field) == 0
        ListRemoved = sprintf('%s%s,', ListRemoved, field);
    end
    if handles.ActiveInitial.(tableName).(field) == 0 && ...
            handles.ActiveFinal.(tableName).(field) == 1
        ListAdded = sprintf('%s%s,', ListAdded, field);
    end
end
if ~isempty(ListRemoved),
    ListRemoved = ListRemoved(1:end-1);
    message = sprintf('%s%s fields removed: %s\n',message,tableName,ListRemoved);
end
if ~isempty(ListAdded),
    ListAdded = ListAdded(1:end-1);
    message = sprintf('%s%s fields added: %s\n',message,tableName,ListAdded);
end

function DisplayMessage(message,Type)
if nargin == 1
    Type = 'dontcare';
end
handles = guidata(gcbo);
if isempty(message)
%     % Make message invisible
%     set(handles.Widgets.hMessagePanel,'Visible','Off');
    set(handles.Widgets.hMessage, 'BackgroundColor',[1 1 1 ])
    set(handles.Widgets.hMessagePanel, 'BackgroundColor',[1 1 1 ])
else
    % Make sure message window is active - or activate it
    handles.Widgets.hMessagePanel.Visible='on';
    handles.Widgets.hDescription.Visible='off';
    if strcmp(Type,'Info')
        set(handles.Widgets.hMessage, 'BackgroundColor',[0.6 1 0.6 ])
        set(handles.Widgets.hMessagePanel, 'BackgroundColor',[0.6 1 0.6 ])
    else
        set(handles.Widgets.hMessage, 'BackgroundColor',[0.8 0.9 0.5 ])
        set(handles.Widgets.hMessagePanel, 'BackgroundColor',[0.8 0.9 0.5 ])
    end
    set(handles.Widgets.hMessage,'String',message);
end
guidata(gcbo, handles);


function RIV = ComputeRIV(NDLRB, PRBLength, StartingRB)
% This function computes the correct RIV to encode a Format1A,1B,1D contiguous
% assignment given:
% NDLRB = total number of DL resource blocks (RB)
% PRBLength = number of RBs assigned to PDSCH
% StartingRB = index of the starting RB for PDSCH assignment
if PRBLength-1 <= floor(NDLRB/2)
    RIV = NDLRB*(PRBLength-1) + StartingRB;
else
    RIV = NDLRB*(NDLRB-PRBLength+1) + (NDLRB-1-StartingRB);
end

function [Bitmap, Problem] = ComputeBitmap(NDLRB, PRBSet)
% If resource allocation type 0, can only encode by chunks of 1,2 or 4
% Resource Block Group Size
if (NDLRB <= 10)
    RBGSize = 1;
elseif (NDLRB <= 26)
    RBGSize = 2;
elseif (NDLRB <= 63)
    RBGSize = 3;
else
    RBGSize = 4;
end
% Compute bitmap
% Number of RBGs
NrRBG = ceil(NDLRB/RBGSize);
Bitmap = char(repmat('0',1,NrRBG));
AllRBs = zeros(1,NDLRB);
% Assigned RBs are marked with a 1
AllRBs(PRBSet+1) = 1;
% Go through all RB groups and check that either all or none are
% allocated. Otherwise, can't be encoded with Type 0. Warn about
% mismatch.
% Encoding: if all are allocated, set bit in Bitmap to 1
Problem = false;
for ii=1:NrRBG-1
    index = (ii-1)*RBGSize+(1:RBGSize);
    if all(AllRBs(index))
        Bitmap(ii) = '1';
    elseif any(AllRBs(index))
        Problem = true;
    end
end
% Last resource block group may be shorter
index = (NrRBG-1)*RBGSize+1:NDLRB;
if all(AllRBs(index))
    Bitmap(end) = '1';
elseif any(AllRBs(index))
    Problem = true;
end
       
function [handles,PDSCH,CodeRate,MCSValue] = ComputeUTBS(handles,PDSCH,NrLayersCW,CW)
% Compute uncoded transport block size
NumberofPRBs = numel(str2num(PDSCH.PRBSet));
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
% Convert to cell array
% PossibleTBSCell = mat2cell(PossibleTBS,ones(1,size(PossibleTBS,1)),1);
% PossibleTBSCell = cell(1,size(PossibleTBS,1));
% for ii=1:size(PossibleTBS,1), PossibleTBSCell{ii} = PossibleTBS(ii); end
command = 'PossibleTBSCell = {';
for ii=1:size(PossibleTBS,1)-1
    command = sprintf('%s''%d'',',command, PossibleTBS(ii));
end
command = sprintf('%s''%d''};', command, PossibleTBS(end));
eval(command);
% Set uncoded transport size options to this value
if CW == 1
    handles.PDSCH.MultipleChoices.TrBlkSize = PossibleTBSCell;
else
    handles.PDSCH.MultipleChoices.TrBlkSize2 = PossibleTBSCell;
end

% Compute the possible TBS sizes after block segmentation & CRC
PossibleTBSAfterSegmentation = zeros(size(PossibleTBS));
for nrTBS = 1:numel(PossibleTBS)
    info = lteDLSCHInfo(PossibleTBS(nrTBS));
    PossibleTBSAfterSegmentation(nrTBS) = info.Bout;
end
% Then we select the TBS that minimizes the error to the
% desired code rate
if CW == 1
    CodedTrBlkSize = PDSCH.CodedTrBlkSize;
else
    CodedTrBlkSize = PDSCH.CodedTrBlkSize2;
end

[~,ind] = min(abs(PossibleTBSAfterSegmentation/double(CodedTrBlkSize) - PDSCH.TargetCodeRate));

% Compute and report corresponding MCS value
MCSValue = ind-1 + MCSOffset;

% Assign the computed TBS
if CW == 1
    PDSCH.TrBlkSize = num2str(PossibleTBS(ind));
else
    PDSCH.TrBlkSize2 = num2str(PossibleTBS(ind));
end
% Actual code rate
CodeRate = PossibleTBSAfterSegmentation(ind)/double(CodedTrBlkSize);

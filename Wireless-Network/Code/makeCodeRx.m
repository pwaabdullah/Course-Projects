function outFile = makeCodeRx(P)

% Determine name of file to generate
% outFile = 'CodeToRun.m';
outFile = GetFileName;
% "indent" is the number of leading white spaces used in myfprintf
indent = 0;

fid = fopen(outFile,'w');
myfprintf(fid,'function [rxBits, rxCW ]= %s(rxWaveform, enb, PDSCH)\n\n', ...
    outFile(1:end-2));

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
myfprintf(fid,'%% Perform deprecoding, layer demapping, demodulation and\n');
myfprintf(fid,'%% descrambling on the received data using the estimate of the channel\n');
myfprintf(fid,'PDSCH.CSI = ''On''; %% Use soft decision scaling\n');
myfprintf(fid,'[rxEncodedBits, rxCW] = ltePDSCHDecode(enb,PDSCH,rxSubframe,estChannelGrid,noiseEst);\n');
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
basename = 'lteRx';
Filename = sprintf('%s.m', basename);
OutFile = Filename;
end


function outFile = makeCodeCh

% Determine name of file to generate
% outFile = 'CodeToRun.m';
outFile = GetFileName;
% "indent" is the number of leading white spaces used in myfprintf
indent = 0;

fid = fopen(outFile,'w');
myfprintf(fid,'function rxWaveform= %s(txWaveform,enb,channel,SNRdB)  \n\n', ...
    outFile(1:end-2));
    myfprintf(fid,'%%%% Channel Model\n');
    myfprintf(fid,'info=lteOFDMInfo(enb);\n\n'); 
    myfprintf(fid,'\n%Pass data through the fading channel model\n');
    myfprintf(fid,'rxWaveform = lteFadingChannel(channel,txWaveform);\n'); 
%     myfprintf(fid,'rxWaveform = txWaveform;\n');
        
    myfprintf(fid,'\n%%%% Additive WGN\n');
    myfprintf(fid,'%% Convert dB to linear\n');
    myfprintf(fid,'SNR = 10^(SNRdB/20);\n\n');
    myfprintf(fid,'%% Normalize noise power to take account of sampling rate, which is\n');
    myfprintf(fid,'%% a function of the IFFT size used in OFDM modulation, and the \n');
    myfprintf(fid,'%% number of antennas\n');
    myfprintf(fid,'N0 = 1/(sqrt(2.0*enb.CellRefP*double(info.Nfft))*SNR);\n\n');
    myfprintf(fid,'%% Create additive white Gaussian noise\n');
    myfprintf(fid,'noise = N0*complex(randn(size(txWaveform)), ...\n');
    myfprintf(fid,'                    randn(size(txWaveform)));\n\n');
    myfprintf(fid,'%% Add AWGN to the received time domain waveform\n');
    myfprintf(fid,'rxWaveform = rxWaveform + noise;\n');

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
basename = 'lteCh';
Filename = sprintf('%s.m', basename);
OutFile = Filename;
end


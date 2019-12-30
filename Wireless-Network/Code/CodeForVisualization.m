function [txWaveform, rxWaveform, txBits, rxBits, eqGrid, nonEqGrid ]= lteTransmitter


%% Simulation length
totalNrSubframes = 1;

%% Define cell-wide parameters
% Number of downlink resource blocks
% The standard defines 6 possible choices: 6,15,25,50,75,100
enb.NDLRB = 50;

% Number of Cell-Specific Reference Signal Antenna Ports
% Can be 1, 2 or 4
enb.CellRefP = 4;

% Physical Cell ID
% A number between 0 and 503
enb.NCellID = 0;

% Cyclic prefix type
% 'Normal' or 'Extended'
enb.CyclicPrefix = 'Normal';

% Channel Format Indicator value: 1, 2, or 3
% Specifies the number of OFDM symbols occupied by the control channel
% If NDLRB<=10, the number is CFI+1
enb.CFI = 3;

% Value used in the computation of the number of PHICH groups
% 'Sixth','Half','One', or 'Two'
enb.Ng = 'Sixth';

% Duration of the PHICH
% 'Normal' or 'Extended'
enb.PHICHDuration = 'Normal';

% Subframe number between 0 and 9
% Parameter is unused in this configuration
% enb.NSubframe = 0;

% Duplex mode: 'FDD' or 'TDD'
% Not tested with TDD
enb.DuplexMode = 'FDD';

% Number of CSI-RS antenna ports, specified as either 1, 2, 4, or 8.
% Only used when TxScheme is set to Port7-14
% Parameter is unused in this configuration
% enb.CSIRefP = 1;

% CSI-RS configuration index, specified as an integer between 0 and 19 (FDD).
% See table 6.10.5.2-1 of TS 36.211
% Only used when TxScheme is set to Port7-14
% Parameter is unused in this configuration
% enb.CSIRSConfig = 0;

% I_CSI-RS subframe configuration, specified as an integer between 0 and 154.
% See table 6.10.5.3-1 of TS 36.211
% Can also be set to 'on' or 'off'
% Only used when TxScheme is set to Port7-14
% Parameter is unused in this configuration
% enb.CSIRSPeriod = 0;

% Zero-power CSI configuration, specified as an integer between 0 and 154.
% Can also be set to 'off' or 'on'
% Only used when TxScheme is set to Port7-14
% Parameter is unused in this configuration
% enb.ZeroPowerCSIRSPeriod = 'off';


%% Main processing loop
for subframeNr = 0+(0:totalNrSubframes-1)

   
   %% Define the PDSCH parameters
   % Some of these values could change every subframe
   % Defining them inside the subframe loop
   % Subframe number between 0 and 9
   enb.NSubframe = mod(subframeNr,10);
   enb.NFrame = floor(subframeNr/10);

   % Transmission scheme. Possible values are:
   % 'Port0', 'TxDiversity', 'CDD', 'SpatialMux', 'MultiUser',
   % 'Port5', 'Port7-8', 'Port8', and 'Port7-14'
   PDSCH.TxScheme = 'SpatialMux';

   % Modulation scheme for the PDSCH
   % Can be 'QPSK','16QAM', or '64QAM'
   PDSCH.Modulation = repmat({'16QAM'},1,2);

   % Number of layers
   % It can only be 1,2,3 or 4 and must be less than CellRefP except
   % for Port7-14, when it can take any value from 1 to 8
   PDSCH.NLayers = 4;

   % Radio Network Temporary Indentifier.
   % A 16-bit value that identifies the mobile in this cell
   PDSCH.RNTI = 1;

   % Redundancy Version Sequence
   % Defines the sequence of redundancy versions to use for retransmissions
   % Example: [0] for no reTx, [0 1 2] for 3 reTx w/ HARQ, [0 0] for chase
   PDSCH.RVSeq = [0 1 2 3];

   % Redundancy version
   % A scalar value that must be one of the values in RVSeq
   PDSCH.RV = 0;

   % Modify for 2 codewords
   PDSCH.RV = repmat(PDSCH.RV,1,2);

   % Physical Resource Block Set
   % The set of physical resource blocks allocated to the PDSCH
   % Must be a subset of 0:NDLRB-1
   PDSCH.PRBSet = (0:49)';

   % Precoder Matrix Indication. Scalar between 0 and 15
   % Only used when TxScheme is set to SpatialMux or MultiUser
   PDSCH.PMISet = 0;

   % Number of transmit antennas. Must be 1 or more. 
   % Only used when TxScheme is set to Port5, Port7-8, Port8, or Port7-14
   % Parameter is unused in this configuration
   %    PDSCH.NTxAnts = 1;

   % Weight for beamforming of dimension NLayers-by-NTxAnts. 
   % Only used when TxScheme is set to Port5, Port7-8, Port8, or Port7-14
   % Parameter is unused in this configuration
   %    PDSCH.W = 1;

   % Target code rate for the PDSCH. Value between 0 and 1
   % The generated program selects the transport block size that yields
   % an effective code rate closest the requested value
   PDSCH.TargetCodeRate = 5.000000e-01;

   % Coded transport block size in bits
   % This value is computed from other parameters
   % It is the number of bits that fit in the allocated resource blocks
   [pdschIndices,info] = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);
   % CodedTrBlkSize is added to the PDSCH structure for convenience
   % It is actually never read by any LTE System Toolbox function
   PDSCH.CodedTrBlkSize = info.G;
   % Here: PDSCH.CodedTrBlkSize = [43328 43328]

   % (Uncoded) Transport block size in bits
   % A number of values are possible depending on the modulation scheme
   % and the number of resource blocks used for the PDSCH. The value
   % that yields a code rate closest to the target code rate is selected
   % Determine possible uncoded transport block sizes based on the number of
   % resource blocks allocated to the PDSCH and the modulation scheme
   
   % The number of layers that CW1 is mapped to is:
   if iscell(PDSCH.Modulation)
      NCodeWords = numel(PDSCH.Modulation);
   else
      NCodeWords = 1;
   end
   NrLayersCW1 = floor(PDSCH.NLayers/NCodeWords);
   % Use the number of layers to compute the TBS
   [PDSCH,MCS1] = ComputeUTBS(PDSCH,NrLayersCW1,1);
   
   if NCodeWords == 2
      % The number of layers that CW2 is mapped to is:
      NrLayersCW2 = ceil(PDSCH.NLayers/NCodeWords);
      % Use the number of layers to compute the TBS
      [PDSCH,MCS2] = ComputeUTBS(PDSCH,NrLayersCW2,2);
   end
   
   %% Generate OFDM grid
   subframe = lteDLResourceGrid(enb);
   % Visualization
   colors = ones(lteDLResourceGridSize(enb));
   
   %% Add PDCCH
   % DCI format
   % Can be 'Format0' ,'Format1', 'Format1A', 'Format1B', 'Format1C',
   % 'Format1D', 'Format2', 'Format2A', 'Format2B', 'Format2C',
   % 'Format3', 'Format3A', or 'Format4'
   dciConfig.DCIFormat = 'Format2';

   % Build the DCI structure with relevant information
   % Bitmap for resource allocation as per TS36.213 section 7.1.6.1
   % for resource allocation type 0
   dciConfig.Allocation.Bitmap = '11111111111111111';
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
   % Visualization
   colors(pdcchIndices) = 6;
   
   %% Add Cell-Specific Reference Signals
   cellRSIndices = lteCellRSIndices(enb);
   cellRSSymbols = lteCellRS(enb);
   subframe(cellRSIndices) = cellRSSymbols;
   % Visualization
   colors(cellRSIndices) = 2;
   
   %% Add BCH
   if mod(enb.NSubframe,10) == 0
       mib = lteMIB(enb);
       pbchIndices = ltePBCHIndices(enb);
       QuarterLength = numel(pbchIndices)/enb.CellRefP;    % 240 for Normal prefix, 216 for Extended
       bchcoded = lteBCH(enb,mib);
       pbchSymbols = ltePBCH(enb,bchcoded);
       startBCH = mod(enb.NFrame,4)*QuarterLength;
       pbchSymbolsThisFrame = pbchSymbols(startBCH+(1:QuarterLength),:);
       subframe(pbchIndices) = pbchSymbolsThisFrame;
       % Visualization
       colors(pbchIndices) = 3;
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
   % Visualization
   colors(pssInd) = 4;
   colors(sssInd) = 4;
   
   %% Add the CFI
   cfiBits = lteCFI(enb);
   pcfichSymbols = ltePCFICH(enb, cfiBits);
   pcfichIndices = ltePCFICHIndices(enb);
   % Map CFI to the grid
   subframe(pcfichIndices) = pcfichSymbols;
   % Visualization
   colors(pcfichIndices) = 7;
   
   %% Add the PHICH
   HIValue = [0 0 1];    % Map an ACK to the first sequence of the first group
   phichSymbols = ltePHICH(enb,HIValue);
   phichIndices = ltePHICHIndices(enb);
   subframe(phichIndices) = phichSymbols;
   % Visualization
   colors(phichIndices) = 8;
   
   %% Add the PDSCH
   % Generate the transport block(s)
   dlschTransportBlk = { randi([0 1], PDSCH.TrBlkSize(1), 1) randi([0 1], PDSCH.TrBlkSize(2), 1)};
   txBits = dlschTransportBlk;
   % Encode the transport block
   codedTrBlock = lteDLSCH(enb, PDSCH, PDSCH.CodedTrBlkSize, dlschTransportBlk);
   % Modulate the transport block
   pdschSymbols = ltePDSCH(enb, PDSCH, codedTrBlock);
   % Subframe resource allocation
   %    Note: pdschIndices was computed previously
   subframe(pdschIndices) = pdschSymbols;
   % Visualization
   colors(pdschIndices) = 5;
   

   %% Display
   hGridDisplay(colors);
   [txWaveform,ofdmInfo] = lteOFDMModulate(enb, subframe);
   
   %% Additive WGN
   SNRdB=30;
   % Convert dB to linear
   SNR = 10^(SNRdB/20);

   % Normalize noise power to take account of sampling rate, which is
   % a function of the IFFT size used in OFDM modulation, and the 
   % number of antennas
   N0 = 1/(sqrt(2.0*enb.CellRefP*double(ofdmInfo.Nfft))*SNR);

   % Create additive white Gaussian noise
   noise = N0*complex(randn(size(txWaveform)), ...
                       randn(size(txWaveform)));

   % Add AWGN to the received time domain waveform
   rxWaveform = txWaveform + noise;
   
   %% Receiver
   rxSubframe = lteOFDMDemodulate(enb,rxWaveform);
   
   % Channel Estimator Configuration
   cec = struct;                           % Channel estimation config structure
   cec.PilotAverage = 'UserDefined';       % Type of pilot symbol averaging
   cec.PilotAverage = 'UserDefined';       % Type of pilot symbol averaging
   cec.FreqWindow = 9;                     % Frequency window size
   cec.TimeWindow = 9;                     % Time window size
   cec.InterpType = 'Cubic';               % 2D interpolation type
   cec.InterpWindow = 'Centered';          % Interpolation window type
   cec.InterpWinSize = 1;                  % Interpolation window size
   
   % Equalization and channel estimation
   [estChannelGrid,noiseEst] = lteDLChannelEstimate(enb,cec, rxSubframe);
   eqGrid = lteEqualizeMMSE(rxSubframe, estChannelGrid,noiseEst);
   nonEqGrid = rxSubframe;
   
   % Perform deprecoding, layer demapping, demodulation and
   % descrambling on the received data using the estimate of the channel
   PDSCH.CSI = 'On';    % Use soft decision scaling
   rxEncodedBits = ltePDSCHDecode(enb,PDSCH,rxSubframe,estChannelGrid,noiseEst);
   
   % Decode DownLink Shared Channel (DL-SCH)
   PDSCH.NTurboDecIts = 5;
   if iscell(rxEncodedBits) && ~iscell(PDSCH.Modulation)
      [decbits,crc] = lteDLSCHDecode(enb,PDSCH,PDSCH.TrBlkSize,rxEncodedBits{1});
   else
      [decbits,crc] = lteDLSCHDecode(enb,PDSCH,PDSCH.TrBlkSize,rxEncodedBits);
   end
   rxBits = decbits;
   
   if crc == 0
      fprintf(1,'crc successful\n');
   else
      fprintf(1,'crc has errors\n');
   end

end  %End subframe loop


%% Retrieve parameters
numFFT =params.numFFT;                           % FFT Length
K = params.K;                                    % Filter length
numGuards = params.numGuards;                    % for both sides
bitsPerSubCarrier = params.bitsPerSubCarrier;    % 2: QAM, 4: 16QAM, 6: 64QAM, 8: 256QAM
numSymbols = params.numSymbols;                  % Simulation length
L = numFFT-2*numGuards;  % Number of complex symbols per OFDM symbol
%% Configure FBMC signals
totalLen=numel(txWaveform);
fbmcAll=reshape(txWaveform, totalLen/numSymbols, numSymbols);
sumFBMCSpec = zeros(numFFT*K*2, 1);
for symbolNr = 1:numSymbols
  txSig=  fbmcAll(:,symbolNr);
  [specFBMC, fFBMC] = periodogram(txSig,rectwin(length(txSig)),numFFT*K*2,1);
  sumFBMCSpec = sumFBMCSpec + specFBMC;
end
%% Display FBMC Spectrums
sumFBMCSpec = sumFBMCSpec / mean(sumFBMCSpec(1+K+2*numGuards*K:end-2*numGuards*K-K));
plot(fFBMC,10*log10(sumFBMCSpec)); hold on; grid on
axis([0 1 -130 10]);
xlabel('Normalized frequency'); ylabel('PSD (dBW/Hz)')
title(['FBMC with ' num2str(K) ' overlapping symbols'])
set(gcf, 'Position', [100 100 560 420]);

%% Configure OFDM signals
totalLen2=numel(txWaveform2);
ofdmAll=reshape(txWaveform2, totalLen2/numSymbols, numSymbols);
sumOFDMSpec = zeros(numFFT*2, 1);
for symbolNr = 1:numSymbols
  ifftOut=  ofdmAll(:,symbolNr);
    [specOFDM,fOFDM] = periodogram(ifftOut,rectwin(length(ifftOut)),numFFT*2,1); 
    sumOFDMSpec = sumOFDMSpec + specOFDM;
end
%% Display OFDM Spectrums
sumOFDMSpec = sumOFDMSpec / mean(sumOFDMSpec(1+2*numGuards:end-2*numGuards));
figure; plot(fOFDM,10*log10(sumOFDMSpec)); grid on
axis([0 1 -100 10]);
xlabel('Normalized frequency'); ylabel('PSD (dBW/Hz)')
title(['OFDM, nFFT = ' num2str(numFFT)])
set(gcf, 'Position', [700 100 560 420]);
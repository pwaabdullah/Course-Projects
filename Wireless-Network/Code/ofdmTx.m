function txWaveform2= ofdmTx(params)
%% Retrieve parameters
numFFT =params.numFFT;                           % FFT Length
numGuards = params.numGuards;                    % for both sides
bitsPerSubCarrier = params.bitsPerSubCarrier;    % 2: QAM, 4: 16QAM, 6: 64QAM, 8: 256QAM
numSymbols = params.numSymbols;                  % Simulation length
L = numFFT-2*numGuards;  % Number of complex symbols per OFDM symbol
%% Symbol mapping
% QAM Symbol mapper
qamMapper = comm.RectangularQAMModulator('ModulationOrder', 2^bitsPerSubCarrier, ...
    'BitInput', true, 'NormalizationMethod', 'Average power');
%% Transmitter loop 
txWaveform2 =[];
for symbolNr = 1:numSymbols
    
    inpData2 = randi([0 1], bitsPerSubCarrier*L, 1);
    modData = step(qamMapper, inpData2);
        
    symOFDM = [zeros(numGuards,1); modData; zeros(numGuards,1)];
    ifftOut = numFFT/sqrt(L).*fftshift(ifft(symOFDM));
    txWaveform2 =[txWaveform2; ifftOut];
end

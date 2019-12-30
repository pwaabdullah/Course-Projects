%% Ask for number of pkts to be transmit
prompt = 'How many times you want send:';
pktNum =input(prompt);
%% Initial parameters
SNR= 8:20;
countLTE=0;
countWLAN=0;
SNRval=[];
lteBER=[];
lteDataRate=[];
wlanBER=[];
wlanDataRate=[];
RATDataRate=0;
x=1:pktNum;
%% Process area
for n= 1:pktNum
    %Calling the functions
    randSNR = datasample(SNR,1);
    [berLTE, perLTE, dataRateLTE] = lte(randSNR);
    [berWLAN, perWLAN, dataRateWLAN] = wlan(randSNR);
    
    % Select thhe best Technology
    if berLTE<berWLAN
        countLTE=countLTE+1;
        RATDataRate=RATDataRate+dataRateLTE;
        fprintf(1,'LTE is select, SNR=%g\n', ...
        randSNR);
    end
    if berLTE>=berWLAN
        countWLAN=countWLAN+1;
        RATDataRate=RATDataRate+dataRateWLAN;
        fprintf(1,'IEEE 802.11ac is select, SNR=%g\n', ...
        randSNR);
    end
    SNRval=[SNRval, randSNR];
    lteBER=[lteBER, berLTE];
    wlanBER=[wlanBER, berWLAN];
    lteDataRate=[lteDataRate, dataRateLTE];
    wlanDataRate=[wlanDataRate, dataRateWLAN];
end
%% PLot area
% figure(1);
% subplot(3,1,1); plot(x, SNRval);
% title('LTE: SNR (dB) vs No. of Sending Data');
% subplot(3,1,2); plot(x, lteBER);
% title('LTE: BER (dB) vs No. of Sending Data');
% subplot(3,1,3); plot(x, lteDataRate);
% title('LTE: Throughput (Mbps) vs No. of Sending Data');
% 
% figure(2);
% subplot(3,1,1); plot(x, SNRval);
% title('IEEE 802.11ac: SNR (dB) vs No. of Sending Data');
% subplot(3,1,2); plot(x, wlanBER);
% title('IEEE 802.11ac: BER (dB) vs No. of Sending Data');
% subplot(3,1,3); plot(x, wlanDataRate);
% title('IEEE 802.11ac: Throughput (Mbps) vs No. of Sending Data');
% 
% figure(3);
% Technology = categorical({'IEEE 802.11ac','lte'});
% selectionNUM = [countWLAN countLTE];
% bar(Technology,selectionNUM);
% title('Number of Selection for each Technology');
% 
% figure(4);
% wlanThroughput= sum(wlanDataRate)/pktNum;
% lteThroughput= sum(lteDataRate)/pktNum;
% RATDataRate= RATDataRate/pktNum;
% TechnoThrough = categorical({'IEEE 802.11ac Throughput','lte Throughput','Multi-RAT Throughput'});
% selThrough = [wlanThroughput lteThroughput RATDataRate];
% bar(TechnoThrough,selThrough);
% title('Troughput with\without Multi-RAT (Mbps)');

% figure (5)
% subplot(2,1,1); semilogy(sort(SNRval), sort(lteBER,'descend'));
% title('LTE: BER (dB) vs SNR (dB)');
% subplot(2,1,2); semilogy(sort(SNRval), sort(wlanBER,'descend'));
% title('IEEE 802.11ac: BER (dB) vs SNR (dB)');
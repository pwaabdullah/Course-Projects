function refSym=lteMapRefSym(PDSCH)
if iscell(PDSCH.Modulation)
    Modulation = PDSCH.Modulation{1};
else
    Modulation = PDSCH.Modulation;
end
switch Modulation
    case 'BPSK'  
        numBits=1;
    case 'QPSK'
        numBits=2;
    case '16QAM' 
        numBits=4;
    case '64QAM' 
        numBits=6;
    case '256QAM'
        numBits=8;
end
x=(0:2^numBits-1)';
H=comm.IntegerToBit('BitsPerInteger',numBits);
y=step(H,x);
refSym=lteSymbolModulate(y,Modulation);
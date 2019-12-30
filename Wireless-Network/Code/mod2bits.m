function numBits=mod2bits(Modulation)
if iscell(Modulation)
    Modulation = Modulation{1};
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
    otherwise
        error('Wrong choice of modulation scheme given!');
end
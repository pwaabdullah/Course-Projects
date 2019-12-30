function Modulation=bits2mod(numBits)
switch numBits
    case 1
        Modulation='BPSK';
    case 2
        Modulation='QPSK';
    case 4
        Modulation='16QAM';
    case 6
        Modulation='64QAM';
    case 8
        Modulation='256QAM';
    otherwise
        error('Wrong choice of modulation scheme given!');
end
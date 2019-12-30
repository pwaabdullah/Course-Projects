function bw=lteDLRBtoBW(DLRB)
switch DLRB
    case 6
        bw='1.4';
    case 15
        bw='3';
    case 25
        bw='5';
    case 50
        bw='10';
    case 75
        bw='15';
    case 100
        bw='20';
    otherwise
        error('Wrong choice of Resource block size given!');
end
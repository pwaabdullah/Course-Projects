function prm=wlanMCSmapping(choice)
switch choice
    case 0,
        prm.Mod= 'BPSK';  
        prm.Cod= '1/2';
    case 1
        prm.Mod= 'QPSK';  
        prm.Cod= '1/2';
    case 2
        prm.Mod= 'QPSK';  
        prm.Cod= '3/4';
    case 3,
        prm.Mod= '16QAM';  
        prm.Cod= '1/2';
    case 4
        prm.Mod= '16QAM';  
        prm.Cod= '3/4';
    case 5
        prm.Mod= '64QAM';  
        prm.Cod= '2/3';
    case 6,
        prm.Mod= '64QAM';  
        prm.Cod= '3/4';
    case 7
        prm.Mod= '64QAM';  
        prm.Cod= '5/6';
    case 8
        prm.Mod= '256QAM';  
        prm.Cod= '3/4';
    case 9
        prm.Mod= '256QAM';  
        prm.Cod= '5/6';
    otherwise
        error('Only support 0 to 9 different MCSs.');
end
% 0	BPSK	1/2
% 1	QPSK	1/2
% 2	QPSK	3/4
% 3	16QAM	1/2
% 4	16QAM	3/4
% 5	64QAM	2/3
% 6	64QAM	3/4
% 7	64QAM	5/6
% 8	256QAM	3/4
% 9	256QAM	5/6
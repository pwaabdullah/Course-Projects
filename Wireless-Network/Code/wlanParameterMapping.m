function [params, SNR, stopSimulation]=wlanParameterMapping(objValues)
bw=objValues.Bandwidth;
params.chanBW = ['CBW',bw];
chMdl=objValues.chanMdl;
params.chMdl = ['Model-',chMdl];
params.Rs     = str2double(bw)*1e6;
params.numTx  = str2double(objValues.NumAntenna);
params.numRx  = params.numTx;
if strcmp(objValues.MIMO, 'STBC')
    params.STBC =true;
else
    params.STBC =false;
end
if params.numTx==1
    params.STBC =false;
end
params.MCS    = str2double(objValues.MCS);
params.APEPLen = fix(objValues.NumBytes);
SNR     = objValues.SNR;
if objValues.stopSim == 0
    stopSimulation=false;
else
    stopSimulation=true;
end

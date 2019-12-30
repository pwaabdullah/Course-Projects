function [params, SNR, stopSimulation]=lteParameterMapping(objValues)
params.profile=objValues.profile;
params.doppler=objValues.doppler;
params.corrProfile=objValues.corrProfile;
SNR     = objValues.SNR;
if objValues.stopSim == 0
    stopSimulation=false;
else
    stopSimulation=true;
end

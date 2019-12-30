function channel=lteSetChannel(enb, PDSCH, params)
info=lteOFDMInfo(enb);
params.Rs=info.SamplingRate;
params.numAntenna=PDSCH.NLayers ;
%%
channel.DelayProfile = params.profile;
channel.NRxAnts = params.numAntenna;
channel.DopplerFreq = params.doppler;
channel.MIMOCorrelation = params.corrProfile;
channel.SamplingRate = params.Rs;
channel.Seed = 1;
channel.InitPhase = 'Random';
channel.ModelType = 'GMEDS';
channel.NTerms = 16;
channel.NormalizeTxAnts = 'On';
channel.NormalizePathGains = 'On';
channel.InitTime = 0;
function channel=defaultLteSetChannel(enb, PDSCH)
params.numAntenna=PDSCH.NLayers ;
info=lteOFDMInfo(enb);
params.Rs=info.SamplingRate;
%%
channel.DelayProfile = 'EVA';
channel.NRxAnts = params.numAntenna;
channel.DopplerFreq = 70;
channel.MIMOCorrelation = 'Low';
channel.SamplingRate = params.Rs;
channel.Seed = 1;
channel.InitPhase = 'Random';
channel.ModelType = 'GMEDS';
channel.NTerms = 16;
channel.NormalizeTxAnts = 'On';
channel.NormalizePathGains = 'On';
channel.InitTime = 0;
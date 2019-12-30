function br=wlanVHTBitRate(cfgVHT)
a=validateConfig(cfgVHT);
br=8* cfgVHT.APEPLength/(1e-6*a.TxTime);
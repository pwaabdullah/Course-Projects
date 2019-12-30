function refSym=MapRefSym(numBits)
qamMod = comm.RectangularQAMModulator('ModulationOrder', 2^numBits, ...
    'BitInput', true, 'NormalizationMethod', 'Average power');
x=(0:2^numBits-1)';
H=comm.IntegerToBit('BitsPerInteger',numBits);
y=step(H,x);
refSym=step(qamMod,y);
% code to count stimulations
D = dir('*.mat'); 
nD = length(D); 
n5V = []; 
n0V = [];
nTr = []; 

disp("files read: ");
for iD=1:nD
    load(D(iD).name,'timeOut0','AmpOutNoise','foundSpotT');
    n5V = cat(1,n5V,length(timeOut0(AmpOutNoise==5))); 
    n0V = cat(1,n0V,length(timeOut0(AmpOutNoise==0))); 
    nTr = cat(1,nTr,length(foundSpotT)); 
    disp(" " +D(iD).name);
end

disp("0V stim: " + sum(n0V) + "   5V stim: " + sum(n5V) + "   Found spot: " + sum(nTr));

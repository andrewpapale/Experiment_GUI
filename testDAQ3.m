%%
clear;
DAQ.s3 = daq.createSession('ni'); % laser
addAnalogOutputChannel(DAQ.s3,'Dev1','ao0','Voltage');


%%

tic

freq = 10;
duration = 10;
amp = 4;

r=robotics.Rate(freq);

outputSingleScan(DAQ.s3,0);

while (toc < 20) 
    
    outputSingleScan(DAQ.s3,amp);
    
    for i=1:duration
        pause(1/1000);
    end
    
    outputSingleScan(DAQ.s3,0); 
    
waitfor(r);
end
s=statistics(r);
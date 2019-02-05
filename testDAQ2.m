%%
DAQ.s3 = daq.createSession('ni'); % laser
addAnalogOutputChannel(DAQ.s3,'Dev1','ao0','Voltage');
DAQ.s3.IsContinuous = true;

%%
tic
r=robotics.Rate(10);

while (toc < 10) 
output=[zeros(1,100),3*ones(1,10),zeros(1,100)];
queueOutputData(DAQ.s3, output');
startBackground(DAQ.s3);

waitfor(r);
end
s=statistics(r);
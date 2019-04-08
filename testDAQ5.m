%%
clear;
DAQ.s3 = daq.createSession('ni'); % laser
addAnalogOutputChannel(DAQ.s3,'Dev1','ao0','Voltage');
DAQ.s3.IsContinuous = true;
DAQ.s3.NotifyWhenScansQueuedBelow = 5;
DAQ.s3.Rate = 250;

r=robotics.Rate(50);
t1 = tic;
QueueCount = 0;
OutputCount = 0;
tmax = 1/12;
t=0:(1/DAQ.s3.Rate):tmax;
Qdata = [];
frameNum = 1;
QueueFrame = [];

while (toc(t1) < 20)
    
    amp = 5;
    freq = 40;
    sigOut = (amp/2)*(square(2*pi*freq*t,freq)+1);
    sigOut(end+1) = 0;
    
    if DAQ.s3.ScansQueued==0
        queueOutputData(DAQ.s3, sigOut');
        Qdata = cat(1,Qdata,sigOut);
        if ~DAQ.s3.IsRunning
            prepare(DAQ.s3);
        end
        QueueCount = QueueCount+1;
        QueueFrame(end+1)=frameNum;
    end
    if ~DAQ.s3.IsRunning
        startBackground(DAQ.s3);
    end
    waitfor(r);
    frameNum = frameNum+1;
end
pause(1);
stop(DAQ.s3);
sigOut= zeros(1,1000);
queueOutputData(DAQ.s3, sigOut');
startBackground(DAQ.s3);

s=statistics(r);
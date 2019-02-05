% TestLaser
% 2018-09-04 AndyP and Taylor K

tmax = 1/20;
nT = 100;
%
DAQ.s3 = daq.createSession('ni'); % laser
addAnalogOutputChannel(DAQ.s3,'Dev1','ao1','Voltage');
DAQ.s3.IsContinuous = true;
DAQ.s3.NotifyWhenScansQueuedBelow = 5;
DAQ.s3.Rate = 500;


queueOutputData(DAQ.s3, repmat(5,[100,1]));
startBackground(DAQ.s3);    

pause(5);

t=0:(1/DAQ.s3.Rate):tmax;
samplesQueued = 0;

for iT=1:nT
    %amp = 0.1+(5+0.1)*rand(1,1);
    amp = 5;
    %freq = 1+(40+1)*rand(1,1);
    freq = 20;
    sigOut = (amp/2)*(square(2*pi*freq*t,freq)+1);
    if DAQ.s3.ScansQueued==0
        queueOutputData(DAQ.s3, sigOut');
        samplesQueued = samplesQueued+1;
        %disp(samplesQueued);
        if ~DAQ.s3.IsRunning
            prepare(DAQ.s3);
        end
    end
    if ~DAQ.s3.IsRunning
        startBackground(DAQ.s3);
        pause(0.1);
        disp('outputting new sample');
    end
    disp(iT)
end

stop(DAQ.s3);
queueOutputData(DAQ.s3, repmat(0,[1,100])'); %#ok<RPMT0>
startBackground(DAQ.s3);
stop(DAQ.s3);
clear DAQ;
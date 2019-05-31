% TestLaser
% 2018-09-04 AndyP and Taylor K

tmax = 1;
nT = 50;
%
DAQ.s3 = daq.createSession('ni'); % laser
addAnalogOutputChannel(DAQ.s3,'Dev1','ao0','Voltage');
DAQ.s3.IsContinuous = true;
DAQ.s3.NotifyWhenScansQueuedBelow = 5;
DAQ.s3.Rate = 800;


queueOutputData(DAQ.s3, repmat(5,[100,1]));
startBackground(DAQ.s3);    

pause(5);

t=0:(1/DAQ.s3.Rate):tmax;
samplesQueued = 0;

r = robotics.Rate(1.5);
for iT=1:nT
    %amp = 0.1+(5+0.1)*rand(1,1);
    amp = 5;
    %freq = 1+(40+1)*rand(1,1);
    %freq = 1./500;
    %sigOut = (amp/2)*(square(freq*t,freq./20)+1);
    sigOut = zeros(size(t));
    sigOut(1:32) = amp;
    
    if DAQ.s3.ScansQueued==0
        queueOutputData(DAQ.s3, sigOut');
        samplesQueued = samplesQueued+1;
        %disp(samplesQueued);
%         if ~DAQ.s3.IsRunning
%             prepare(DAQ.s3);
%         end
    end
    if ~DAQ.s3.IsRunning
        startBackground(DAQ.s3);
        %pause(0.1);
        disp('outputting new sample');
    end
    disp(iT)
    waitfor(r);
end

stop(DAQ.s3);
queueOutputData(DAQ.s3, repmat(0,[1,100])'); %#ok<RPMT0>
startBackground(DAQ.s3);
stop(DAQ.s3);
clear DAQ;
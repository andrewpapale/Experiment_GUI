function DAQ = InitializeDAQ

DAQ.s1 = daq.createSession('ni'); % food
addDigitalChannel(DAQ.s1,'Dev1', 'port0/line1', 'OutputOnly');
outputSingleScan(DAQ.s1,1);

%DAQ.s2 = daq.createSession('ni'); % buzz
%addDigitalChannel(DAQ.s2,'Dev1', 'port0/line3', 'OutputOnly');

DAQ.s3 = daq.createSession('ni'); % laser
addAnalogOutputChannel(DAQ.s3,'Dev1','ao1','Voltage');
DAQ.s3.IsContinuous = true;
DAQ.s3.NotifyWhenScansQueuedBelow = 5;
DAQ.s3.Rate = 500;
%outputSingleScan(DAQ.s3,0); 
end
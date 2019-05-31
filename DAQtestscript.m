DAQ = InitializeDAQ;


array = zeros(1000, 1);
sigOut = cat(1, array, 5);
queueOutputData(DAQ.s3, sigOut);
startBackground(DAQ.s3);
stop(DAQ.s3);
clear DAQ;

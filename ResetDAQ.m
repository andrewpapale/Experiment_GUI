function ResetDAQ(DAQ)


outputSingleScan(DAQ.s1,1);
%outputSingleScan(DAQ.s2,0);
stop(DAQ.s3);
queueOutputData(DAQ.s3, repmat(0,[1,100])'); %#ok<RPMT0>
startBackground(DAQ.s3);
stop(DAQ.s3);
pause(2);
release(DAQ.s1);
%release(DAQ.s2);
clear DAQ;

end
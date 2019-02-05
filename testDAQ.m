%%
DAQ.s3 = daq.createSession('ni'); % laser
addAnalogOutputChannel(DAQ.s3,'Dev1','ao1','Voltage');


output=[zeros(10,1);ones(10,1);zeros(500,1)];

t=tic;

for iT=1:100
    
if mod(iT,3)==0
    ampOut = 5*rand(1,1);
    lh = addlistener(DAQ.s3,'DataRequired',@(src,event) src.queueOutputData(repmat(ampOut,[1,500])'));
    DAQ.s3.IsContinuous = true;
    %queueOutputData(DAQ.s3, repmat(ampOut,[1,500])');
    prepare(DAQ.s3);
    startBackground(DAQ.s3);
    delete(lh);
    disp(toc(t));
end
end

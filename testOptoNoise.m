
nT = 100;
ISI = 1;

DAQ = InitializeDAQ;

tstim_max_noise_exp = 3;
t_stim_noise_exp = 0:(1/DAQ.s3.Rate):tstim_max_noise_exp;

for iT=1:nT
    
    if DAQ.s3.ScansQueued <=3
        sigOut = zeros(length(t_stim_noise_exp),1);
        ix = 1:length(sigOut);
        switch ISI
            case 1
                sigOut(ix(mod(ix,DAQ.s3.Rate)==0)) = 5;
                sigOut(ix(mod(ix,DAQ.s3.Rate)==0)+1) = 5;
                sigOut(ix(mod(ix,DAQ.s3.Rate)==0)+2) = 5;
                sigOut(ix(mod(ix,DAQ.s3.Rate)==0)+3) = 5;
                sigOut(ix(mod(ix,DAQ.s3.Rate)==0)+4) = 5;
                sigOut(ix(mod(ix,DAQ.s3.Rate)==0)+5) = 5;
                sigOut(ix(mod(ix,DAQ.s3.Rate)==0)+6) = 5;
            case 2
                ISItime =(3)-(3-1)*rand(2,1);
                ISItime = cumsum(ISItime);
                sigOut(interp1(t_stim_noise_exp,ix,ISItime,'nearest','extrap'))= 5;
        end
        sigOut(end)=0;
        queueOutputData(DAQ.s3, sigOut);
    end
    if ~DAQ.s3.IsRunning %&& handles.DAQ.s3.ScansQueued > 3
        startBackground(DAQ.s3);
    end
    % elseif (RewardZoneOn || isnan(x) || (x > 500 && y < 100)) % signal is outputting
    %     timeOutStop0 = cat(1,timeOutStop0,timeofFrameAcq);
    %     stop(DAQ.s3); % long ~0.1Hz delay
    %  end
    
end

ResetDAQ(DAQ);
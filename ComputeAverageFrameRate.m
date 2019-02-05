function avgFrameRate = ComputeAverageFrameRate(avgFrameRate,frameNum,frameRate)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

avgFrameRate = avgFrameRate;
if mod(frameNum,100)==0
    avgFrameRate = mean(avgFrameRate);
else
    avgFrameRate = cat(1,avgFrameRate,frameRate);
end

end


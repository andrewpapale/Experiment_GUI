function [IM,x,y,mouseArea0,fillV] = getBody(V)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% 2018-08-14 AndyP, changed <ntX0,ntY0> -> <tX0,tY0>, corrected eroded
% image IMbw3 used to find nose points, versus uneroded image IMbw2 used to
% find tail points.
    x = nan;
    y = nan;
    mouseArea0 = nan;
    fillV = nan;
    % try
    IM = GetFrame(V); %gets image of current frame
    % Track Mouse
    IMg = IM-V.baseFrame;       %subtracts baseframe from image (should be left with mouse image)
    IMbw = IMg>V.videoParms.threshold;  %Creates binary image

    IMbw = bwmorph(IMbw,'majority'); %sets pixels to 0 that don't have 5 or more 1 neighbors
    fillV = 0;
    CC = bwconncomp(IMbw); %returns array of connected component structs found in the binary image.
    nC = CC.NumObjects; %returns the number of connected components 
    xC1 = nan(nC,1); %returns an array of dimensions number of connected components x 1.
    yC1 = nan(nC,1); %same for y 
    if nC>0 %if there is at least one connected component
        dofill = false;
        L0 = cellfun(@length,CC.PixelIdxList);
        [mouseArea0,iC1] = max(L0);
        if mouseArea0 < 100 && mouseArea0 > 20
            %             x = nan;
            %             y = nan;
            % try filling in closeby blobs
            dofill = false;
        end
        for iC=1:nC
            [yC{iC},xC{iC}] = ind2sub(size(V.videoParms.X),CC.PixelIdxList{iC}); %#ok<AGROW>
            xC1(iC)=nanmedian(xC{iC});
            yC1(iC)=nanmedian(yC{iC});
        end
    if dofill
        IMbwF = imdilate(IMbw,strel('disk',5));
        CC = bwconncomp(IMbwF);
        L0 = cellfun(@length,CC.PixelIdxList);
        [mouseArea0,iC1] = max(L0);
        fillV = 1;
    else
        for iC=1:nC
            if iC~=iC1
                IMbw(yC{iC},xC{iC})=0; % remove other blobs
            end
        end
        fillV = 0;
    end
    x = xC1(iC1);
    y = yC1(iC1);
    end
end

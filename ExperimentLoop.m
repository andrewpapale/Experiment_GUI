function [IM,x,y,IMbw,nx,ny,lastCycleOn,tswitch,tx,ty,mouseLength,t,timeOfFrameAcq,amp,dur,mouseArea0,switchNT,fillV,DAQoutput,tsincelaststim] = ExperimentLoop(V,DAQ,frameNum,amp_map,lastCycleOn,tswitch,freq_map,t,optoControl,tstart,xset,yset,time,nx0,ny0,tx0,ty0)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% 2018-08-14 AndyP, changed <ntX0,ntY0> -> <tX0,tY0>, corrected eroded
% image IMbw3 used to find nose points, versus uneroded image IMbw2 used to
% find tail points.
x = nan;
y = nan;
nx = nan;
ny = nan;
tx = nan;
ty = nan;
mouseLength = nan;
mouseArea0 = nan;
amp = nan;
dur = nan;
switchNT = nan;
fillV = nan;
DAQoutput = 0;
% try
IM = GetFrame(V);   % 2019-05-17 Try multiple frames / trigger? Get only 1st frame for real-time processing? Output IM and IMnew from ExperimentLoop function
% IMnew = first frame of IM, process IMnew in rest of loop
timeOfFrameAcq = toc(tstart);
IMbw2 = zeros(size(IM));
% Track Mouse
IMg = IM-V.baseFrame;
IMbw = IMg>V.videoParms.threshold;
IMbw = bwmorph(IMbw,'majority');
switchNT = 0;
fillV = 0;
%IMbw(20:60,545:575)=0; % blank out feeder zone
CC = bwconncomp(IMbw);
nC = CC.NumObjects;
xC1 = nan(nC,1);
yC1 = nan(nC,1);
if nC>0
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
    %     X0 = V.videoParms.X(IMbw);
    %     Y0 = V.videoParms.Y(IMbw);
    %     x = median(Y0(:));
    %     y = median(X0(:));
    %fprintf('%0.1f     %0.1f   \n',x,y);
    
    %     if sum(IMbw(:))>50000 % lights are on  % 2018-08-15 AndyP
    %         x = nan;
    %         y = nan;
    %         if lastCycleOn
    %             tswitch = clock;
    %             lastCycleOn = 1;
    %         end
    %     else
    %         if ~lastCycleOn
    %             tswitch = clock;
    %             lastCycleOn = 0;
    %         end
    %     end
    %
    %     if etime(clock,tswitch) < 1.5  % wait 1.5s after lights turned off
    %         x = nan;
    %         y = nan;
    %     else
    %     end
    %     if sum(IMbw(:))/(size(IMbw,1)*size(IMbw,2)) < V.videoParms.areathresh %too small a track
    %         x = nan;
    %         y = nan;
    %     end
    if ~isnan(x) % get nose coordinates
        
        lastnx = nx;
        lastny = ny;
        lasttx = tx;
        lastty = ty;
        
        se = strel('disk',2);
        if ~dofill
            IMbw2 = bwperim(IMbw, 4);
            IMbw2 = bwmorph(IMbw2,'clean');
            
            IMbw3 = imerode(IMbw,se); % remove tail
            IMbw3 = bwperim(IMbw3, 4);
        else
            IMbw2 = bwperim(IMbwF,4);
            IMbw3 = imerode(IMbwF,se);
            IMbw3 = bwperim(IMbw3,4);
        end
        nX0 = V.videoParms.X(IMbw3);
        nY0 = V.videoParms.Y(IMbw3);
        tX0 = V.videoParms.X(IMbw2);
        tY0 = V.videoParms.Y(IMbw2);
        nX0 = nX0(:);
        nY0 = nY0(:);
        tX0 = tX0(:);
        tY0 = tY0(:);
        taild = sqrt((tX0-x).^2+(tY0-y).^2);
        tailv = sqrt((tX0-lasttx).^2+(tY0-lastty).^2);
        taild(taild > 75 | tailv > 75) = nan;
        tX0(isnan(taild))=[];
        tY0(isnan(taild))=[];
        taild(isnan(taild))=[];
        [~, tailI] = nanmax(taild);
        if ~isempty(tailI)
            tx = tX0(tailI);
            ty = tY0(tailI);
            lasttx = tx;
            lastty = ty;
        end
        
        nosetaildist = sqrt((nX0-tx).^2+(nY0-ty).^2);
        nosev = sqrt((nX0-lastnx).^2+(nY0-lastny).^2);
        nosetaildist(nosetaildist > 150 | nosev > 150) = nan;
        
        [mouseLength,noseI] = nanmax(nosetaildist);
        if ~isempty(noseI)
            nx = nX0(noseI);
            ny = nY0(noseI);
            lastnx = nx;
            lastny = ny;
        else
            mouseLength = nan;
        end
        
        % algorithm to correct nose tail flipping
        if length(xset)>3
            if ~isnan(nx) & sum(~isnan(xset(end-3:end)))>1 %#ok<AND2>
                time0 = cat(1,time(end-3:end),timeOfFrameAcq);
                x0 = cat(1,xset(end-3:end),x);
                y0 = cat(1,yset(end-3:end),y);
                dx = diff(x0)./diff(time0);
                dy = diff(y0)./diff(time0);
                dy0 = (y+nanmean(dy(end-3:end)))-y;
                dx0 = (x+nanmean(dx(end-3:end)))-x;
                V0 = dx0.^2+dy0.^2;
                lastx1 = nan;
                lasty1 = nan;
                if abs(V0) < Inf
                    m0 = dy0./dx0;
                    lastminX = nan;
                    lastmaxX = nan;
                    switch sign(dx0)
                        case -1
                            minX = x-20;
                            maxX = x;
                            lastminX = minX;
                            lastmaxX = maxX;
                        case 1
                            minX = x;
                            maxX = x+20;
                            lastminX = minX;
                            lastmaxX = maxX;
                        case 0
                            minX = lastminX;
                            maxX = lastmaxX;
                    end
                    result = computeline([x, y],m0, [minX maxX]);
                    nP = length(result);
                    x1 = nan(nP,1);
                    y1 = nan(nP,1);
                    for iP=1:nP
                        x1(iP) = result{iP}(:,1);
                        y1(iP) = result{iP}(:,2);
                    end
                    
                    lastx1 = nanmedian(cat(1,lastx1,x1));
                    lasty1 = nanmedian(cat(1,lasty1,y1));
                    dbn = nanmin(sqrt((nx-x1).^2+(ny-y1).^2));
                    dbt = nanmin(sqrt((tx-x).^2+(ty-y).^2));
                    
                    if dbn>dbt
                        nx1 = nx;
                        ny1 = ny;
                        nx = tx;
                        ny = ty;
                        tx = nx1;
                        ty = ny1;
                        switchNT = 1;
                    end
                else
                    if sum(~isnan(nx0))>2
                        dbnx = nanmedian(cat(1,(nx-lastx1).^2,(lastnx-lastx1).^2));
                        dbny = nanmedian(cat(1,(ny-lasty1).^2,(lastny-lasty1).^2));
                        dbn = sqrt(dbnx+dbny);
                        dbt = nanmin(sqrt((tx-x).^2+(ty-y).^2));
                        if dbn>50 || dbn>dbt
                            nx1 = nx;
                            ny1 = ny;
                            nx = tx;
                            ny = ty;
                            tx = nx1;
                            ty = ny1;
                            switchNT = 1;
                        end
                    end
                end
            end
            
        else
        end
    else
    end
end
% if optoControl > 0
%     
%     % TK write code to output a pulse every 500ms
%     
%     tsincelaststim = tic;
%     
%     
%     switch optoControl
%         case 1 % vary amp
%             %             freq=15;
%             
%             if ~isnan(x)
%                 amp = amp_map(round(y),round(x));
%             else
%                 amp = 0;
%             end
%             %sigOut = [amp*ones(3,1);zeros(15,1)]';
%             sigOut = repmat(amp,[length(t),1])';
%             %             sigOut = (amp/2)*(square(2*pi*freq*t,freq)+1);
%             %             sigOut(end+1) = 0;
%             %             disp(length(sigOut));
%             
%             
%         case 2 % vary freq
%             amp=2.5;
%             if ~isnan(x)
%                 freq = freq_map(round(y),round(x));
%             else
%                 freq = 15;
%                 amp = 0;
%             end
%             % sigOut = repmat(amp,[length(t),1])';
%             %sigOut = (amp/2)*(square(2*pi*freq*t,freq)+1);
%             %sigOut(end+1) = 0;
%         case 3 % vary amp and freq
%             
%             if ~isnan(nx)
%                 dur = freq_map(round(ny),round(nx));
%                 amp = amp_map(round(ny),round(nx));
%                 sigOut = amp*cat(2,ones(1,2),zeros(1,21-2));
%             else
%                 amp = 0;
%                 dur = 0;
%                 sigOut = zeros(1,length(t));
%             end
%             %sigOut = repmat(amp,[length(t),1])';
%             
%             %sigOut(end+1) = 0;
%             
%         case 4 % random
%             if ~isnan(x)
%                 amp = 0.1+(5+0.1)*rand(1,1);
%                 %freq = 1+(40+1)*rand(1,1);
%                 sigOut = amp*cat(2,ones(1,1),zeros(1,21-1));
%                 %sigOut(end+1) = 0;
%             else
%                 amp = nan;
%                 freq = nan;
%                 sigOut = zeros(1,length(t));  
%             end
%         otherwise
%             error('unknown optoControl variable');
%     end
%     if DAQ.s3.ScansQueued==0
%         queueOutputData(DAQ.s3, sigOut');
%         %samplesQueued = samplesQueued+1;
%         %disp(samplesQueued);
%         if ~DAQ.s3.IsRunning
%             %prepare(DAQ.s3);
%         end
%     end
%     if ~DAQ.s3.IsRunning
%         startBackground(DAQ.s3);
%         %disp('outputting new sample');
%     end
%     
% end

% if optoNoise
%     if ISI > 0 && ~isnan(x)
%         
%         sigOut = zeros(length(t),1);
%         ix = 1:length(sigOut);
%         sigOut(ix(mod(ix,5)==0))= optoNoiseAmpOut;
%         sigOut(end) = 0;
%         
%         if DAQ.s3.ScansQueued==0
%             queueOutputData(DAQ.s3, sigOut);
%             samplesQueued = samplesQueued+1;
%             %disp(samplesQueued);
%             if ~DAQ.s3.IsRunning
%                 prepare(DAQ.s3);
%             end
%         end
%         
%         if ~DAQ.s3.IsRunning && DAQgo
%                 startBackground(DAQ.s3);
%                 DAQoutput = 1;
%                 %disp('outputting new sample');
%         end
%     else
%         
%     end
% end

end
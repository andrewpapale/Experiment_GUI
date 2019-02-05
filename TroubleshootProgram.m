% 2018-09-12 AndyP and TK
% Troubleshooting program for Experiment_GUI
% runs avi video back through ExperimentLoop to determine where detection
% goes wrong
% 
% filename = uigetfile;
% V1 = VideoReader(filename);
% video = read(V1,[3802 3950]); %#ok<VIDREAD>
% matfile = uigetfile;
% load(matfile);
% function [IM,x,y,IMbw2,nx,ny,lastCycleOn,tswitch,tx,ty,mouseLength,t,timeOfFrameAcq,amp,dur,samplesQueued,mouseArea0,switchNT,fillV] = ExperimentLoop(V,DAQ,frameNum,amp_map,lastCycleOn,tswitch,freq_map,t,optoControl,tstart,samplesQueued,pulseMatrix,xset,yset,time,nx0,ny0,tx0,ty0)
% %UNTITLED Summary of this function goes here
% %   Detailed explanation goes here
% % 2018-08-14 AndyP, changed <ntX0,ntY0> -> <tX0,tY0>, corrected eroded
% % image IMbw3 used to find nose points, versus uneroded image IMbw2 used to
% % find tail points.

nF = size(video,4);

xset = x0;
yset = y0;
time = time0;

for iF=1:nF
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
% try
%IM = GetFrame(V);
%timeOfFrameAcq = toc(tstart);


IM = squeeze(video(:,:,1,iF));
IMbw2 = zeros(size(IM));
% Track Mouse
IMg = IM-V.baseFrame;
IMbw = IMg>2.5;
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
        end
        
        % algorithm to correct nose tail flipping
        if length(xset)>3
            if ~isnan(nx) & sum(~isnan(xset(end-4:end-1)))>1 %#ok<AND2>
                time1 = cat(1,time(end-4:end-1),time(end));
                x0 = cat(1,xset(end-3:end),x);
                y0 = cat(1,yset(end-3:end),y);
                dx = diff(x0)./diff(time1);
                dy = diff(y0)./diff(time1);
                dy0 = (y+nanmean(dy(end-3:end)))-y;
                dx0 = (x+nanmean(dx(end-3:end)))-x;
                V0 = dx0.^2+dy0.^2;
                lastx1 = nan;
                lasty1 = nan;
                if abs(V0) > Inf
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


 cla('reset');
        imagesc(IM); hold on;
        axis xy;
        radius = radiusAroundSpot*pixpercm;
        px = cx-radius;
        py = cy-radius;
        R = rectangle('Position',[px py 2*radius 2*radius],'Curvature',[1,1]);
        set(R,'EdgeColor','r');
        plot(x,y,'rx','markersize',20);
        plot(x,y,'ro','markersize',20);
        plot(nx,ny,'gx','markersize',10);
        plot(nx,ny,'go','markersize',10);
        plot(tx,ty,'b.','markersize',10);
        line([x,nx],[y,ny],'color','r');
        colormap('gray');
        axis off;
        
        pause;

end

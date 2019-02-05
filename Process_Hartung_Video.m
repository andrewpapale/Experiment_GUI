function [x0,y0,nx0,ny0,tx0,ty0,mL,mA,sBW,baseFrame] = Process_Hartung_Video(videoName)
% 2018-08-14 AndyP and JaneH
% [x0,y0,nx0,ny0,tx0,ty0,V,nV] = Process_Hartung_Video(videoName);
% opens an MP4 and gets <x,y>, etc from the video

dotest = false;

threshold = 5;
areathresh = 0.001; % total pixels above thr
pT = 0;


V = VideoReader(videoName); % only works on avi or mp4!!!
fprintf('loading video %s \n',videoName);
possiblebaseframes = read(V,[1 300]); %#ok<VIDREAD>
nX = V.Width;
nY = V.Height;
nT = floor(V.Duration*V.FrameRate);
[X,Y] = ndgrid(1:nX,1:nY);
X = X';
Y = Y';
x0 = [];
y0 = [];
nx0 = [];
ny0 = [];
tx0 = [];
ty0 = [];

% get baseFrame, for image subtraction
ok = false;
while ~ok
    inputVar = input('Enter a frame number:  ');
    inputVar = round(inputVar);
    figure(1); clf;
    imagesc(possiblebaseframes(:,:,:,inputVar));
    colormap gray;
    okflag = input('Is this OK?  ','s');
    
    if strcmp(okflag,'Y') || strcmp(okflag,'y')
        ok = true;
        baseFrame = possiblebaseframes(:,:,:,inputVar);
    else
        ok = false;
    end
end

% get maze points
ok = false;
while ~ok
    figure(1); clf;
    imagesc(imadjust(baseFrame(:,:,1)));
    colormap jet;
    axis xy;
    hold on;
    
    RectV = getrect;
    RectV = rectangle('Position',RectV);
    set(RectV,'EdgeColor','r','LineWidth',3);
    
    RectH = getrect;
    RectH = rectangle('Position',RectH);
    set(RectH,'EdgeColor','r','LineWidth',3);
    
    pV = RectV.Position;
    pH = RectH.Position;
    
    Vtrack = ~(X<pV(1)+pT | Y<pV(2)+pT | X>pV(1)+pV(3)-pT | Y>pV(2)+pV(4)-pT);
    Htrack = ~(X<pH(1)+pT | Y<pH(2)+pT | X>pH(1)+pH(3)-pT | Y>pH(2)+pH(4)-pT);
    
    trackdef = Vtrack | Htrack;
    
    okflag = input('Is this OK?  ','s');
    
    if strcmp(okflag,'Y') || strcmp(okflag,'y')
        ok = true;
        X(~trackdef)=nan;
        Y(~trackdef)=nan;
    else
        ok = false;
    end
end

nx = nan;
ny = nan;
tx = nan;
ty = nan;
lasttx = nan;
lastty = nan;
lastnx = nan;
lastny = nan;
mL = nan;
mA = nan;
sBW = nan;

tstart = tic;
for iT=1:nT
    
    IM = read(V,iT); %#ok<VIDREAD>
    % Track Mouse
    IMg = IM(:,:,1)-baseFrame(:,:,1);
    IMbw = IMg>threshold;
    IMbw(~trackdef)=0;
    sumBW0 = nansum(IMbw(:));
    %IMbw(~trackdef)=0;
    IMbw = bwareafilt(IMbw,3,'largest');
    CC = bwconncomp(IMbw);
    nC = CC.NumObjects;
    xC1 = nan(nC,1);
    yC1 = nan(nC,1);
    if nC>0
        for iC=1:nC
            [yC{iC},xC{iC}] = ind2sub(size(X),CC.PixelIdxList{iC}); %#ok<AGROW>
            xC1(iC)=nanmedian(xC{iC});
            yC1(iC)=nanmedian(yC{iC});
        end
        
        if ~isempty(x0) % get closest blob to last rat blob
            [~,iC1] = nanmin(sqrt((xC1-x0(end)).^2+(yC1-y0(end)).^2));
        else % use closest blob to midpoint of camera
            [~,iC1] = nanmin(sqrt((xC1-V.Width/2).^2+(yC1-V.Height/2).^2));
        end
        mouseArea0 = length(xC{iC1});
        for iC=1:nC
            if iC~=iC1
                IMbw(yC{iC},xC{iC})=0; % remove other blobs
            end
        end
        x = xC1(iC1);
        y = yC1(iC1);
        
        
        if sum(IMbw(:))/(size(IMbw,1)*size(IMbw,2)) < areathresh %too small a blob
            x = nan;
            y = nan;
        end
        
        x0 = cat(1,x0,x);
        y0 = cat(1,y0,y);
        
        if ~isnan(x) % get nose coordinates
            
            IMbw2 = bwperim(IMbw, 4);
            IMbw2 = bwmorph(IMbw2,'clean');
            
            se = strel('disk',2);
            IMbw3 = imerode(IMbw,se); % remove tail
            IMbw3 = bwperim(IMbw3, 4);
            
            nX0 = X(IMbw3);
            nY0 = Y(IMbw3);
            tX0 = X(IMbw2);
            tY0 = Y(IMbw2);
            nX0 = nX0(:);
            nY0 = nY0(:);
            tX0 = tX0(:);
            tY0 = tY0(:);
            taild = sqrt((tX0-x).^2+(tY0-y).^2);
            tailv = sqrt((tX0-lasttx).^2+(tY0-lastty).^2);
            taild(taild > 200 | tailv > 200) = nan;
            tX0(isnan(taild))=[];
            tY0(isnan(taild))=[];
            taild(isnan(taild))=[];
            [~, tailI] = nanmax(taild);
            tx = tX0(tailI);
            ty = tY0(tailI);
            if ~isnan(tx)
                lasttx = tx;
                lastty = ty;
            end
            
            if ~isempty(tx)
                
                nosetaildist = sqrt((nX0-tx).^2+(nY0-ty).^2);
                nosev = sqrt((nx-lastnx).^2+(ny-lastny).^2);
                nosetaildist(nosetaildist > 300 | nosev > 200) = nan;
                
                [mouseLength0,noseI] = nanmax(nosetaildist);
                nx = nX0(noseI);
                ny = nY0(noseI);
                if ~isnan(nx)
                    lastnx = nx;
                    lastny = ny;
                end
                
                % algorithm to correct nose tail flipping
                if length(x0)>3
                    if ~isnan(nx) & sum(~isnan(x0(end-3:end)))>1 %#ok<AND2>
                        dx = foaw_diff(x0(end-3:end),1./V.FrameRate,round(V.FrameRate),0.2,0.1);
                        dy = foaw_diff(y0(end-3:end),1./V.FrameRate,round(V.FrameRate),0.2,0.1);
                        dy0 = (y+nanmean(dy(end-3:end)))-y;
                        dx0 = (x+nanmean(dx(end-3:end)))-x;
                        V0 = dx0.^2+dy0.^2;
                        lastx1 = nan;
                        lasty1 = nan;
                        if V0 > 0.001
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
                            
                            lastx1 = x1;
                            lasty1 = y1;
                            dbnx = nanmin((nx-x1).^2);
                            dbny = nanmin((ny-y1).^2);
                            dbn = nanmin(sqrt(dbnx+dbny));
                            dbtx = nanmin((tx-x1).^2);
                            dbty = nanmin((ty-y1).^2);
                            dbt = nanmin(sqrt(dbtx+dbty));
                            
                            if dbn>dbt
                                nx0 = nx;
                                ny0 = ny;
                                nx = tx;
                                ny = ty;
                                tx = nx0;
                                ty = ny0;
                            end
                        else
                            dbnx = nanmedian(cat(1,nanmin((nx-lastx1).^2),nanmin((lastnx-lastx1).^2)));
                            dbny = nanmedian(cat(1,nanmin((ny-lasty1).^2),nanmin((lastny-lasty1).^2)));
                            dbn = sqrt(dbnx+dbny);
                            dbtx = nanmedian(cat(1,nanmin((tx-lastx1).^2),nanmin((lasttx-lastx1).^2)));
                            dbty = nanmedian(cat(1,nanmin((ty-lasty1).^2),nanmin((lastty-lasty1).^2)));
                            dbt = sqrt(dbtx+dbty);
                            if dbn>dbt
                                nx1 = nx;
                                ny1 = ny;
                                nx = tx;
                                ny = ty;
                                tx = nx1;
                                ty = ny1;
                            end
                        end
                    end
                end
            else
                tx = nan;
                ty = nan;
                nx = nan;
                ny = nan;
            end
            nx0 = cat(1,nx0,nx);
            ny0 = cat(1,ny0,ny);
            tx0 = cat(1,tx0,tx);
            ty0 = cat(1,ty0,ty);
            mL = cat(1,mL,mouseLength0);
            mA = cat(1,mA,mouseArea0);
            sBW = cat(1,sBW,sumBW0);
        else
        end
        
    end
    
    if dotest
        F1 = figure(1); clf;
        imagesc(imadjust(IM(:,:,1)));
        hold on;
        axis xy;
        colormap jet;
        
        F2 = figure(2); clf;
        imagesc(IMbw);
        hold on;
        axis xy;
        caxis([0 1]);
        plot(xC1(iC1),yC1(iC1),'r.'); % detected rat
        plot(x,y,'gx','markersize',20); % detected midpoint
        
        
        F3 = figure(3); clf;
        imagesc(IMbw2);
        hold on;
        axis xy;
        caxis([0 1]);
        plot(x,y,'gx','markersize',20);
        plot(nx,ny,'co','markersize',10);
        plot(tx,ty,'r.','markersize',15);
        
        pause;
    end
    t2 = toc(tstart);
    fprintf('frame %d/%d %0.2f, \n',iT,nT,t2);
end

end



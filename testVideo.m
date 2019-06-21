% testVideo LED
% 2019-06-06 AndyP

V = VideoReader('528818-2019-06-18-1.avi');
nF = length(x0);

ix = interp1(time0,frame0,timeOut0,'nearest');

V1 = VideoWriter('newfile.avi','Grayscale AVI');
V1.FrameRate = 48;
open(V1);
for iF=1:nF
    F = figure(1); clf;
    vid = V.readFrame;
    vid = squeeze(vid(:,:,1));
    imagesc(imadjust(uint8(vid)));
    hold on;
    axis xy;
    colormap gray;
    axis equal;
    axis off;
    if any(ix==iF)
        rectangle('Position',[50 400 50 50],'FaceColor','red');
    end
    F1 = getframe(F);
    F1.cdata = F1.cdata(:,:,1);
    writeVideo(V1,F1);
end
close(V1);

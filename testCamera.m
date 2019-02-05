nF = 10;

vid = imaq.VideoDevice('pointgrey', 1, 'F7_Mono8_1280x1024_Mode0');

vid.DeviceProperties.Brightness = 1.563;
vid.DeviceProperties.Gain = 12;

frame = step(vid);
testvid = nan(size(frame,1),size(frame,2),nF);


    frame = step(vid);
    testvid(:,:,iF)=frame; 
end

% for iF=1:nF
%     imagesc(testvid(:,:,iF));
%     pause(0.2);
% end

delete(vid);
clear vid;
clear;
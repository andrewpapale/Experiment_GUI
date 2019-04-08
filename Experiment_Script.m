function Experiment_Script
% Experiment_Script

global V
global DAQ
V=InitializeCamera;
%DAQ = InitializeDAQ;
DAQ = [];
V = GetBaseFrame(V);
frameNum = 0;
amp_map = imread('amp_map.tif');
%amp_map = amp_map./max(amp_map(:)).*5; % scale pixel intensity to voltage max
freq_map = imread('freq_map.tif');

handleE.Value = false;
handleR.Value = false;
handleS.Value = false;

F = figure('WindowKeyPressFcn', @(handle,event) disp(event.Key));
RecordButton = uicontrol('Style','pushbutton','String','Record',...
    'Position',[100,200,100,100],...
    'Callback',@(handleR,V)Record(handleR,V));
StopRecordingButton = uicontrol('Style','pushbutton','String','Stop Recording',...
    'Position',[200,200,100,100],...
    'Callback',@(handleR,V)StopRecording(handleR,V));
ExitButton = uicontrol('Style','pushbutton','String','Exit',...
    'Position',[300,200,100,100],...
    'Callback',@Exit);
while ~handleE.Value
    
    if ~handleE.Value
        t1 = clock;
        IM = ExperimentLoop(V,DAQ,frameNum,amp_map,freq_map);
        if handleR.Value
            WriteToVideoFile(V, IM);
        end
        frameNum = frameNum+1;
        imagesc(IM);
        colormap('gray');
        t2 = clock;
        frameRate = 1/etime(t2,t1);
        handles.text3.String = sprintf('%0.2f',frameRate);
        %catch
        %    warning('Experiment loop ended');
        %end
    else
        disp('Experiment over');
    end
end

end

function Record(handleR,V)

handleR.Value = 1;
videoStr = inputdlg('Enter a video name');
V.videoFP = VideoWriter(videoStr{1}, 'Motion JPEG AVI');
pause(1);

end

function StopRecording(handleR,V)

handleR.Value = 0;
CloseVideoFP(V);
pause(1);

end

function Exit()

handleE.Value = true;
ResetCamera;
%ResetDAQ(DAQ);
close all force;

end

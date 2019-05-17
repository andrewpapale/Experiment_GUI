function [handles] = initializeHandles(handles, hObject)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
handles.output = hObject;
handles.V=InitializeCamera;
handles.DAQ = InitializeDAQ;
handles.V.videoParms.areathresh = 0.001; % total pixels above thr
nX = 576;
nY = 480;
handles.V.Width = nX;
handles.V.Height = nY;
xCM = 35*2.54; % in * cm/in
yCM = 44.5*2.54; % in * cm/in
handles.pixpercm = (472-12)/xCM; % pixels / cm
[handles.V.videoParms.X,handles.V.videoParms.Y] = ndgrid(1:nX,1:nY);
handles.V.videoParms.X = handles.V.videoParms.X';
handles.V.videoParms.Y = handles.V.videoParms.Y';
handles.V.baseFrame0 = GetFrame(handles.V);
handles.V.baseFrame = imdilate((handles.V.baseFrame0),strel('disk',10));
handles.V.videoParms.startTime = tic;
handles.stopLoop = 0;
handles.nPelletsPerTrial = 3;
handles.Food = 0;
handles.changeBuzzer = 0;
handles.autoReward = 0;
handles.firstLoop = 1;
handles.useBody = false;

handles.SpotPosition = '';
handles.spotTrial = 0;
handles.ResetReward = 0;
handles.cx = [];
handles.cy = [];
handles.gauss_width = [];
handles.fanx = [];
handles.fany = [];

handles.optoNoiseAmpOut = 0;
handles.optoNoise = false;
handles.ISI = 0;
% amp_map = imread('prob_map.tif');
% amp_map = im2double(amp_map);
% handles.amp_map = amp_map./max(amp_map(:)).*5; % scale pixel intensity to voltage max
% handles.iz = find(amp_map(:)>-1);

handles.amp_map = [];
handles.freq_map = [];
handles.iz = [];


handles.RecordIt = 0;
handles.frameRate = [];
handles.V.videoFP = [];


amp=1;
fs=20500;  % sampling frequency
duration=0.5;
duration1=0.25;
freq=1000;
values=0:1/fs:duration;
values1=0:1/fs:duration1;
handles.tone=amp*sin(2*pi* freq*values);
handles.endtone = amp*sin(2*pi*freq*2*values1);

set(handles.OptoOff,'Value',1);
handles.optoControl = 0;
end


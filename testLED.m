function varargout = testLED(varargin)
% TESTLED MATLAB code for testLED.fig
%      TESTLED, by itself, creates a new TESTLED or raises the existing
%      singleton*.
%
%      H = TESTLED returns the handle to a new TESTLED or the handle to
%      the existing singleton*.
%
%      TESTLED('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TESTLED.M with the given input arguments.
%
%      TESTLED('Property','Value',...) creates a new TESTLED or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before testLED_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to testLED_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help testLED

% Last Modified by GUIDE v2.5 17-Jun-2019 17:59:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @testLED_OpeningFcn, ...
    'gui_OutputFcn',  @testLED_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before testLED is made visible.
function testLED_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to testLED (see VARARGIN)

% Choose default command line output for testLED


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

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes testLED wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = testLED_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Exit.
function Exit_Callback(hObject, eventdata, handles)
% hObject    handle to Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.stopLoop = 1;
queueOutputData(handles.DAQ.s3, repmat(0,[100,1])); startBackground(handles.DAQ.s3);
stop(handles.DAQ.s3);
guidata(hObject,handles);
ResetCamera;
ResetDAQ(handles.DAQ);
close all force;

% --- Executes on button press in Start.
function Start_Callback(hObject, eventdata, handles)
% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
queueOutputData(handles.DAQ.s3, repmat(5,[100,1])); 
startBackground(handles.DAQ.s3);
disp("LED should be visible");

hAxes = handles.axes1;
persistent hImage
cla(hAxes,'reset')

avgFrameRate = [];
nUpdate = 15;
ISItime = 0;
FoodZoneOn = 0;
RewardZoneOn = 0;
fprintf('Starting camera, updating image every %0.2f frames \n', nUpdate);
handles.V.baseFrame0 = GetFrame(handles.V);
handles.V.baseFrame = imdilate((handles.V.baseFrame0),strel('disk',2));
handles.V.medianBF = nanmean(handles.V.baseFrame0(:));
handles.stopLoop = 0;
if handles.spotTrial || handles.autoReward
    handles.tsess = clock;
end
guidata(hObject,handles);
%try
frameNum = 0;
x = nan;
y = nan;
x0 = [];
y0 = [];
nx0 = [];
ny0 = [];
tx0 = [];
ty0 = [];
xtemp = [];
ytemp = [];
frame0 = [];
time0 = [];
amp0 = [];
dur0 = [];
fillV0 = [];
switchNT0 = [];
mouseLength0 = [];
mouseArea0 = [];
tQueue = [];
timeOut0 = [];
t_stim_noise_exp = [];
timeOutStop0 = [];
ISI = [];
rn = 3-(3-1)*rand(1,1);
rnA = 0;
AmpOutNoise = [];
timeOutQ0 = [];
optoNoise = handles.optoNoise;

P1 = []; P2 = []; P3 = [];
loopRate = 50;
%freqs = linspace(0.5,40,100);
tstim_max = 1/25;
t_stim=0:(1/handles.DAQ.s3.Rate):tstim_max;
tstim_max_noise_exp = 0.25;
t_stim_noise_exp = 0:(1/handles.DAQ.s3.Rate):tstim_max_noise_exp;

%tstim = clock;
if handles.spotTrial && handles.optoControl
    % define pulses
    Pmap = unique(handles.freq_map(:));
    nP = length(Pmap);
    %     pulseMatrix = nan(length(t_stim));
    %     pulseMatrix = cat(2,ones(1,
    %     for iP=1:nP
    %
    %         %pulseMatrix(iP,:) = cat(2,ones(1,Pmap(iP)),zeros(1,length(t_stim)-Pmap(iP)));
    %     end
else
    pulseMatrix=[];
    
end

hImage = imshow(handles.V.baseFrame0,'Parent',hAxes);
pos = get(hAxes,'Position');

set(hAxes,'Units','pixels','Position',[pos(1)+100,pos(2)+150,handles.V.Width,handles.V.Height]);

set(hAxes, 'xlimmode','manual',...
    'ylimmode','manual',...
    'zlimmode','manual',...
    'climmode','manual',...
    'alimmode','manual');
set(gcf,'doublebuffer','off');

if handles.spotTrial; radius = handles.radiusAroundSpot; px = handles.cx-radius; py = handles.cy-radius; end;
if handles.spotTrial; R = rectangle('Position',[px py 2*radius 2*radius],'Curvature',[1,1]); set(R,'EdgeColor','r'); end;

r = robotics.Rate(loopRate);
tstart = tic;
etlaststim = tstart;
Qct = 0;

while ~handles.Exit.Value || ~handles.StopLoopCHK.Value
    t1 = clock;
    %disp(Qct);
    handles = guidata(hObject);
    handles.V.videoParms.threshold = str2double(handles.ThresholdText.String);
    if handles.Exit.Value
        break;
    end
    
    if frameNum < 100
        lastCycleOn = 1;
        tswitch = clock;
    end
    frameNum = frameNum+1;
    %% main experiment loop
    %handles.invertColors = handles.BlackMouse.Value;
    handles.invertColors = 0;
    tsincelaststim = NaN;
    %[IM,x,y,~,nx,ny,lastCycleOn,tswitch,tx,ty,mouseLength,t_stim,timeofFrameAcq,amp,dur,mouseArea,switchNT,fillV,DAQoutput,tsincelaststim] = ExperimentLoop(handles.V,handles.DAQ,frameNum,handles.amp_map,lastCycleOn,tswitch,handles.freq_map,t_stim,optoControl,tstart,x0,y0,time0,nx0,ny0,tx0,ty0,handles.invertColors,tsincelaststim);
    
    

    frame0 = cat(1,frame0,frameNum);

   
    %% record video
    if handles.RecordIt && ~handles.StopRecChk.Value
        handles = guidata(hObject);
        try
            writeVideo(handles.V.videoFP, IM);
        catch
            warning(sprintf('frame %n skipped %0.2f \n',frameNum,toc(tstart))); %#ok<SPWRN>
        end
    end
    %% controls image window, updates every nUpdate frames
    if mod(frameNum,nUpdate)==0 % update figure every nUpdate frames
        %cla('reset'); % old
        delete(P2); delete(P3);
        %imagesc(IM); hold on; axis xy; colormap('gray'); % old
        IM = GetFrame(handles.V);
        set(hImage,'CData',IM); hold on; axis xy; % % 2019-05-17 Try multiple frames / trigger? Change IM to IMnew
        %2019-02-27 much faster
       % P2 = plot(x,y,'ro','markersize',20); P3 = plot(nx,ny,'gx','markersize',10); %line([x,nx],[y,ny],'color','r');
        %set(gca,'Position',[hAxes.Position(1),hAxes.Position(2),hAxes.Position(3),hAxes.Position(4)]);
        %drawnow;
        %         handles = guidata(hObject);
        %         guidata(hObject,handles);
    end
    %% controls feeder and buzzer
    if handles.firstLoop % just need some initial values
        FeederOff = 1;
        BuzzerOff = 1;
        changeFood = 1;
        nPelletsDelivered = 0;
        tfood = clock;
        handles.firstLoop=0;
        if handles.Food
            soundsc(handles.tone);
        end
    else
    end
    if handles.Food % deliver food nPelletsPerTrial times
        
        foodTimer = etime(clock,tfood);
        if nPelletsDelivered < handles.nPelletsPerTrial
            
            if foodTimer > 0.5 % change state every 0.5s
                changeFood = 1;
            elseif foodTimer <= 0.5
                changeFood = 0;
            end
            if changeFood && FeederOff
                outputSingleScan(handles.DAQ.s1,0); % turn feeder on
                FeederOff = 0;
                tfood = clock;
                nPelletsDelivered = nPelletsDelivered+1;
            elseif changeFood && ~FeederOff
                outputSingleScan(handles.DAQ.s1,1); % turn feeder off
                FeederOff = 1;
                tfood = clock;
            end
        elseif foodTimer > 0.5
            outputSingleScan(handles.DAQ.s1,1);
            handles.Food = 0;
            handles.changeBuzzer = 1;
        end
    else
    end
    
    %     if handles.changeBuzzer && BuzzerOff
    %         %outputSingleScan(handles.DAQ.s2,1);
    %         handles.changeBuzzer = 0;
    %         BuzzerOff = 0;
    %     elseif handles.changeBuzzer && ~BuzzerOff
    %        % outputSingleScan(handles.DAQ.s2,0);
    %         handles.changeBuzzer = 0;
    %         BuzzerOff = 1;
    %     end
    
    if handles.spotTrial
        tsess0 = clock;
        sessT = etime(tsess0,handles.tsess);
        if sessT < handles.maxSessT
            if handles.trialNum ==1 % handles initial trial
                FoodZoneOn = 1;
                RewardZoneOn = 0;
                xtemp = [];
                ytemp = [];
            end
            xtemp = cat(1,xtemp,x); % take average position over 20 frames for error-reduction
            ytemp = cat(1,ytemp,y);
            if length(xtemp)>30
                xtemp = [];
                ytemp = [];
            end
            if handles.useBody
                x2use = x;
                y2use = y;
            else
                x2use = nx;
                y2use = ny;
            end
            
            if length(xtemp)>10 & nanmean(xtemp) > 500 && nanmean(ytemp) < 100 & RewardZoneOn %#ok<AND2> % in the reward zone, reset reward
                FoodZoneOn = 1;
                RewardZoneOn = 0;
                xtemp = [];
                ytemp = [];
                fprintf('Trial %d starting @ %0.2fs \n',handles.trialNum,sessT);
                handles.TrialStartT = cat(1,handles.TrialStartT,sessT);
            elseif sqrt((x2use-handles.cx).^2+(y2use-handles.cy).^2) <= handles.radiusAroundSpot & ~handles.Food & FoodZoneOn %#ok<AND2>
                handles.Food = 1;
                handles.firstLoop = 1;
                handles.changeBuzzer = 1;
                FoodZoneOn = 0;
                RewardZoneOn = 1;
                handles.trialNum = handles.trialNum+1;
                fprintf('Found Spot %0.2fs \n',sessT);
                handles.foundSpotT = cat(1,handles.foundSpotT,sessT);
            end
        end
    end
    
    if handles.autoReward % reset food timer
        tsess0 = clock;
        sessT = etime(tsess0,handles.tsess);
        if mod(round(sessT,1),10)==0
            fprintf('time: %0.2f \n',sessT);
        end
        tSinceLastReward = etime(clock,tfood);
        if tSinceLastReward > handles.ITI
            handles.Food = 1;
            handles.firstLoop = 1;
            handles.changeBuzzer = 1;
        end
    end
    
    %% ding at the end
    if handles.autoReward || handles.spotTrial
        
        if sessT >= handles.maxSessT || handles.SaveData.Value
            trialNum = 1:length(handles.TrialStartT);
            trialStartT = handles.TrialStartT;
            foundSpotT = handles.foundSpotT;
            maxSessT = handles.maxSessT;
            nPelletsPerTrial = handles.nPelletsPerTrial;
            spotTrial = handles.spotTrial;
            radiusAroundSpot = handles.radiusAroundSpot./handles.pixpercm;
            cx = handles.cx;
            cy = handles.cy;
            pixpercm = handles.pixpercm;
            optoControl = handles.optoControl;
            fixedRadiusBug = 1;
            fixedQueueTimeBugforOptoNoise = 1;
            useBody = handles.useBody;
            ITI = handles.ITI;
            autoReward = handles.autoReward;
            gauss_width = handles.gauss_width;
            fanx = handles.fanx;
            fany = handles.fany;
            ISI = handles.ISI;
            handles.V.ExposureMode = handles.V.src.ExposureMode;
            handles.V.Exposure = handles.V.src.Exposure;
            handles.V.GainMode = handles.V.src.GainMode;
            handles.V.Gain = handles.V.src.Gain;
            handles.V.FrameRateMode = handles.V.src.FrameRateMode;
            handles.V.FrameRate = handles.V.src.FrameRate;
            handles.V.ShutterMode = handles.V.src.ShutterMode;
            handles.V.Shutter = handles.V.src.Shutter;
            handles.V.SharpnessMode = handles.V.src.SharpnessMode;
            handles.V.Sharpness = handles.V.src.Sharpness;
            handles.V.camera.FramesPerTrigger = 1;
            manualCamera = 1; % 2018-09-17 AndyP
            optoNoiseAmpOut = handles.optoNoiseAmpOut;
            optoNoise = handles.optoNoise;
            
            % 2019-05-22 AndyP and TK, convert Qcounter0, frameCt, and
            % frameQ into timestamps based on time0, frame0

            V = [];
            if ~isempty(handles.V)
                V = handles.V;
            end
            temp = clock;
            if temp(2)<10 % add a zero
                monstr = strcat('0',mat2str(temp(2)));
            else
                monstr = mat2str(temp(2));
            end
            if temp(3)<10 % add a zero
                daystr = strcat('0',mat2str(temp(3)));
            else
                daystr = mat2str(temp(3));
            end
            saveStr = strcat(mat2str(temp(1)),'-',monstr,'-',daystr,'_',mat2str(temp(4)),'_',mat2str(temp(5)));
            save(strcat(saveStr,'.mat'),'timeOutQ0','AmpOutNoise','tQueue','fixedQueueTimeBugforOptoNoise','ISI','timeOutStop0','timeOut0','t_stim_noise_exp','t_stim','optoNoiseAmpOut','optoNoise','manualCamera','fixedRadiusBug','dur0','amp0','loopRate','tstim_max','optoControl','frame0','time0','r','tx0','ty0','mouseLength0','pixpercm','radiusAroundSpot','trialNum','trialStartT','foundSpotT','maxSessT','nPelletsPerTrial','spotTrial','x0','y0','nx0','ny0','V','cx','cy','mouseArea0','switchNT0','fillV0','useBody','ITI','autoReward','gauss_width','fanx','fany');
            
            handles.RecordIt = 0;
            soundsc(handles.endtone);
            pause(1);
            soundsc(handles.endtone);
            pause(1);
            soundsc(handles.endtone);
            handles.Food = 0;
            handles.autoReward = 0;
            %             if BuzzerOff
            %                 handles.changeBuzzer = 0;
            %             else
            %                 handles.changeBuzzer = 1;
            %             end
            handles.autoReward = 0;
            handles.spotTrial = 0;
            handles.stopLoop = 1;
            handles.RecordIt = 0;
            handles.stopLoop = 1;
            if ~isempty(handles.V.videoFP)
                close(handles.V.videoFP);
                handles.V.videoFP = [];
            end
            %             set(handles.OptoOff,'Value',1);
            %             set(handles.VaryAmplitude,'Value',0);
            %             set(handles.VaryFrequency,'Value',0);
            %             set(handles.VaryFreqAndAmp,'Value',0);
            set(handles.Start,'Value',0);
            stop(handles.DAQ.s3);
            pause(1);
            guidata(hObject,handles);
            
            guidata(hObject,handles);
            ResetCamera;
            ResetDAQ(handles.DAQ);
            close all force;
            break;
            
        end
        
    end
    
    waitfor(r);
    
    %% update frame rate
    t2 = clock;
    handles.frameRate = 1/etime(t2,t1);
    
    if mod(frameNum,100)==0
        avgFrameRate = mean(avgFrameRate);
    else
        avgFrameRate = cat(1,avgFrameRate,handles.frameRate);
    end
    handles.text3.String = sprintf('%0.2f',mean(avgFrameRate));
    
    handles.avgFrameRate = avgFrameRate;
    
    if handles.stopLoop || handles.StopLoopCHK.Value || handles.Exit.Value
        break;
    end
    
    if handles.spotTrial || handles.autoReward
        handles.currSessTime.String = sprintf('%0.2f',sessT);
    end
    if handles.spotTrial
        handles.trialNumTxt.String = sprintf('%0.2f',handles.trialNum);
    end
    guidata(hObject,handles);
end
% --- Executes on button press in Record.
function Record_Callback(hObject, eventdata, handles)
% hObject    handle to Record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.Start,'Value',0);
set(handles.StopLoopCHK,'Value',1);

videoStr = inputdlg('Enter a video name');
D = dir('*.avi');
videoStr = strcat(videoStr,'.avi');
for iD=1:length(D)
    if strcmp(videoStr,D(iD).name)
        warning('File with that name already exists');
        videoStr{1} = '';
    end
end
if ~isempty(videoStr{1})
    handles.V.videoFP = VideoWriter(videoStr{1},'Grayscale AVI');
    handles.V.videoFP.FrameRate = round(38);
    open(handles.V.videoFP);
    fprintf('Starting Video, time: %s, frame rate: %0.1f \n wait 2s to start loop \n',datestr(clock), 38);
    handles.RecordIt=1;
    pause(2);
    handles.recordtimer = clock;
    guidata(hObject,handles);
    set(handles.StopLoopCHK,'Value',0);
    guidata(hObject,handles);
end



% --- Executes on button press in SubtractBkg.
function SubtractBkg_Callback(hObject, eventdata, handles)
% hObject    handle to SubtractBkg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.StopLoopCHK,'Value',1);
handles.V.baseFrame = [];
handles.V.baseFrame0 = GetFrame(handles.V);
handles.V.baseFrame = imdilate((handles.V.baseFrame0),strel('disk',10));
if ~isempty(handles.V.baseFrame)
    disp('Base Frame Updated');
end
guidata(hObject,handles);
pause(0.2);
set(handles.StopLoopCHK,'Value',0);


function ThresholdText_Callback(hObject, eventdata, handles)
% hObject    handle to ThresholdText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ThresholdText as text
%        str2double(get(hObject,'String')) returns contents of ThresholdText as a double
set(handles.StopLoopCHK,'Value',1);
handles.V.videoParms.threshold = round(str2double(get(hObject,'string')));
%set(handles.ThresholdSlider,'Value',handles.V.videoParms.threshold);
guidata(hObject,handles);
pause(0.2);
set(handles.StopLoopCHK,'Value',0);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function ThresholdText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ThresholdText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
set(hObject,'string',5);
handles.V.videoParms.threshold = round(str2double(get(hObject,'string')));
guidata(hObject,handles);
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Reward.
function Reward_Callback(hObject, eventdata, handles)
% hObject    handle to Reward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.StopLoopCHK,'Value',1);
handles.Food = 1;
handles.firstLoop = 1;
handles.changeBuzzer = 1;
guidata(hObject,handles);
pause(0.1);
set(handles.StopLoopCHK,'Value',0);



% --- Executes on button press in AutoReward.
function AutoReward_Callback(hObject, eventdata, handles)
% hObject    handle to AutoReward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Food = 1;
handles.firstLoop = 1;
handles.changeBuzzer = 1;
handles.autoReward = 1;
handles.TrialStartT = nan;
handles.foundSpotT = nan;
pause(1);
guidata(hObject,handles);

fprintf('session time: %0.2f s reward delivered \n',handles.maxSessT);
fprintf('ITI: %0.2f s \n',handles.ITI);
soundsc(handles.endtone);
pause(1);

function ITITimeText_Callback(hObject, eventdata, handles)
% hObject    handle to ITITimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ITITimeText as text
%        str2double(get(hObject,'String')) returns contents of ITITimeText as a double
try
    handles.ITI = str2double(get(hObject,'string'));
catch
    warning('ITI must be an integer');
end
pause(0.1);
guidata(hObject,handles);
pause(0.1);

% --- Executes during object creation, after setting all properties.
function ITITimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ITITimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
try
    handles.ITI = str2double(get(hObject,'string'));
catch
    warning('ITI must be an integer');
end
guidata(hObject,handles);

function sessTimeTxt_Callback(hObject, eventdata, handles)
% hObject    handle to currSessTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of currSessTime as text
%        str2double(get(hObject,'String')) returns contents of currSessTime as a double
try
    sessTmin = str2double(get(hObject,'string'));
catch
    warning('sessTime needs to be an integer');
end
handles.maxSessT = 60*sessTmin; % to sec
pause(0.1);
guidata(hObject,handles);
pause(0.1);

% --- Executes during object creation, after setting all properties.
function sessTimeTxt_CreateFcn(hObject, eventdata, handles)
% hObject  handle to currSessTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject,'string',5);
sessTmin = str2double(get(hObject,'string'));
handles.maxSessT = 60*sessTmin; % to sec
guidata(hObject,handles);


% --- Executes on button press in SpotTrial.
function SpotTrial_Callback(hObject, eventdata, handles)
% hObject    handle to SpotTrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);


% handles.SpotPosition = PickASpot;
% fprintf('Spot Position %s \n',handles.SpotPosition);

handles.spotTrial = 1;
handles.trialNum = 1;
handles.firstLoop = 1;
handles.changeBuzzer = 0;
handles.Food = 0;
handles.nPelletsPerTrial = 3;
handles.TrialStartT = [];
handles.foundSpotT = [];

handles.V.baseFrame0 = GetFrame(handles.V);
handles.V.baseFrame = imdilate((handles.V.baseFrame0),strel('disk',10));
if ~isempty(handles.V.baseFrame)
    disp('Base Frame Updated');
end
guidata(hObject,handles);


disp('Click on the center of the target region');
imshow(handles.V.baseFrame0);
axis xy;

handles.gauss_width = 100; % How fast do you want the laser stimulation to fall off
[handles.cx,handles.cy]=ginput(1); % Click a point that you want to be the center of a circle
[handles.binary_map, handles.freq_map, handles.amp_map, handles.dist_map ] = circle_target( handles.V.baseFrame, handles.radiusAroundSpot*handles.pixpercm, handles.cx, handles.cy, handles.gauss_width,handles.optoNoiseAmpOut); % edit this script to change how the characteristics of light stimulation vary with distance from the target
fprintf('session time: %0.2f s \n',handles.maxSessT);

soundsc(handles.endtone);
pause(1);

guidata(hObject,handles);
pause(1);

radius = handles.radiusAroundSpot;
px = handles.cx-radius;
py = handles.cy-radius;
if handles.spotTrial
    R = rectangle('Position',[px py 2*radius 2*radius],'Curvature',[1,1]);
    set(R,'EdgeColor','r');
end

function DistanceToSpot_Callback(hObject, eventdata, handles)
% hObject    handle to DistanceToSpot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DistanceToSpot as text
%        str2double(get(hObject,'String')) returns contents of DistanceToSpot as a double
handles = guidata(hObject);
try
    handles.radiusAroundSpot = str2double(get(hObject,'string'))*handles.pixpercm;
catch
    warning('value must be a number');
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function DistanceToSpot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DistanceToSpot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles = guidata(hObject);
set(hObject,'string','1.5');
handles.radiusAroundSpot = str2double(get(hObject,'string'))*5.1744; % *pixpercm
guidata(hObject,handles);


% --- Executes on button press in StopLoopCHK.
function StopLoopCHK_Callback(hObject, eventdata, handles)
% hObject    handle to StopLoopCHK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of StopLoopCHK
handles.stopLoop = 1;
handles.RecordIt = 0;
if ~isempty(handles.V.videoFP)
    close(handles.V.videoFP);
    handles.V.videoFP = [];
end
guidata(hObject,handles);
pause(0.3);

% --- Executes on button press in StopRecChk.
function StopRecChk_Callback(hObject, eventdata, handles)
% hObject    handle to StopRecChk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of StopRecChk
handles.RecordIt = 0;
handles.stopLoop = 1;
if ~isempty(handles.V.videoFP)
    close(handles.V.videoFP);
    handles.V.videoFP = [];
end
guidata(hObject,handles);
pause(0.2);

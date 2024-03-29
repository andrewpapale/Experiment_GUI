function varargout = Experiment_GUI(varargin)
% EXPERIMENT_GUI MATLAB code for Experiment_GUI.fig
%      EXPERIMENT_GUI, by itself, creates a new EXPERIMENT_GUI or raises the existing
%      singleton*.
%
%      H = EXPERIMENT_GUI returns the handle to a new EXPERIMENT_GUI or the handle to
%      the existing singleton*.
%
%      EXPERIMENT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EXPERIMENT_GUI.M with the given input arguments.
%
%      EXPERIMENT_GUI('Property','Value',...) creates a new EXPERIMENT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Experiment_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Experiment_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Experiment_GUI

% Last Modified by GUIDE v2.5 20-Jun-2019 10:56:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Experiment_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @Experiment_GUI_OutputFcn, ...
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


% --- Executes just before Experiment_GUI is made visible.
function Experiment_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Experiment_GUI (see VARARGIN)

% Choose default command line output for Experiment_GUI


handles = initializeHandles(handles, hObject);

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes Experiment_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Experiment_GUI_OutputFcn(hObject, eventdata, handles)
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
guidata(hObject,handles);
ResetCamera;
ResetDAQ(handles.DAQ);
close all force;

% --- Executes on button press in Start.
function Start_Callback(hObject, eventdata, handles)
% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
ISI0 = [];
fillV0 = [];
switchNT0 = [];
mouseLength0 = [];
mouseArea0 = [];
tQueue = [];
timeOut0 = [];
t_stim_noise_exp = [];
timeOutStop0 = [];
ISI = [];
rn = 3-(3-0.5)*rand(1,1);
rnA = 2;
AmpOutNoise = [];
timeOutQ0 = [];
optoNoise = handles.optoNoise;
ISIout = [];
amp_map = [];
ISI_map = [];

P1 = []; P2 = []; P3 = [];
loopRate = 50;
%freqs = linspace(0.5,40,100);
tstim_max = 0.08;
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
ltNlast = handles.trialNum;
handles.ISItime = 0.5;
guidata(hObject,handles);

while ~handles.Exit.Value || ~handles.StopLoopCHK.Value
    t1 = clock;
    %disp(Qct);
    handles = guidata(hObject);
    handles.V.videoParms.threshold = str2double(handles.ThresholdText.String);
    optoControl = handles.optoControl;
    if handles.stopLoop || handles.StopLoopCHK.Value || handles.Exit.Value
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
    
    [IM,x,y,~,nx,ny,lastCycleOn,tswitch,tx,ty,mouseLength,t_stim,timeofFrameAcq,amp,dur,mouseArea,switchNT,fillV] = ExperimentLoop(handles.V,handles.DAQ,frameNum,handles.amp_map,lastCycleOn,tswitch,handles.freq_map,t_stim,optoControl,tstart,x0,y0,time0,nx0,ny0,tx0,ty0);
    
    
    if optoNoise
        if length(x0) > 10
            xU = sum(~isnan(x0(end-10:end)))>5;
        else
            xU = 0;
            % etlaststim = tic; 2019-06-14 AndyP and TK this is wrong!!!
        end
        
        stimclock = toc(etlaststim);
        switch handles.ISI
            case 1
                % qGO = stimclock >=1-0.1;
                % stimGO = stimclock >= 1; % 1 sec
                qGO = stimclock > rn-0.1; %TK 6/17/19
                stimGO = stimclock > rn; % rand 1-3s interval %TK 6/17/19
            case 2
                qGO = stimclock > rn-0.1;
                stimGO = stimclock > rn; % rand 1-3s interval
        end
        
        nogozone = 200 > sqrt((x-576).^2+(y-15).^2);
        edge = x < 50 | x > size(IM,2)-50 | y < 50 | y > size(IM,1)-50;
        
        
        if qGO && ~(RewardZoneOn || nogozone || edge) && xU && Qct==0 % queue signal
            %6/17/19 TK added conditional to choose 0V ISI R 1s-3s stims
            if handles.ISI == 2
                AMPmatrix = [0 5]; % change this to change amplitudes for opto noise 2019-05-31 AndyP and TK
            elseif handles.ISI==1
                AMPmatrix = [0 0];
            end
            
            if handles.trialNum > ltNlast
                rnAlast = rnA;
                rnA = randi(length(AMPmatrix),1);
                ltNlast = handles.trialNum;
                if rnAlast==1 && rnA==1
                    rnA = 2;
                end
            end
            
            
            sigOut = zeros(length(t_stim_noise_exp),1); %returns an array of zeros
            sigOut(1:40) = repmat(AMPmatrix(rnA),[40,1]);
            rn = 3-(3-0.5)*rand(1,1);
            
            queueOutputData(handles.DAQ.s3, sigOut);
            Qct = Qct + 1;
            qGO = 0;
            tQueue = cat(1,tQueue,timeofFrameAcq);
        end
        
        %         if ~handles.DAQ.s3.IsRunning && handles.DAQ.s3.ScansQueued > 3
        %             prepare(handles.DAQ.s3);
        %         end
        
        if ~mod(frameNum,nUpdate)==0 && ~handles.DAQ.s3.IsRunning && Qct > 0 && stimGO && xU && ~(RewardZoneOn || nogozone || edge)
            stimGO = 0;
            startBackground(handles.DAQ.s3);
            Qct = 0;
            etlaststim = tic;
            timeOut0 = cat(1,timeOut0,timeofFrameAcq);
            AmpOutNoise = cat(1,AmpOutNoise,AMPmatrix(rnA));
        end
        
        if ~handles.DAQ.s3.IsRunning && (RewardZoneOn || ~xU || nogozone || edge) && Qct==0 % signal is outputting
            sigOut = zeros(201,1); %returns an array of zeros
            queueOutputData(handles.DAQ.s3, sigOut);
            startBackground(handles.DAQ.s3);
            %stop(handles.DAQ.s3); % long ~0.1Hz delay, causing long
            timeOutStop0 = cat(1,timeOutStop0,timeofFrameAcq);
            etlaststim = tic;
            Qct = 0;
            %timeOutQ0 = cat(1,timeOutQ0,timeofFrameAcq);
            %outputs at high voltage?
            
            
        end
        
    end
    
    if optoControl
        %
        %     % TK write code to output a pulse every 500ms
        %
        %     tsincelaststim = tic;
        %
        %
        switch optoControl
            case 1 % vary amp
                if ~isnan(x)
                    amp = handles.amp_map(round(y),round(x));
                else
                    amp = 0;
                end
            case 2 % vary ISI
                if ~isnan(x)
                    amp = 5;
                    handles.ISItime = 1./handles.freq_map(round(y),round(x))+0.15;
                else
                    amp = 0;
                end
                % 2019-06-20 AndyP and TK do something to change
                % handles.ISItime
            case 3 % vary amp and ISI time
                if ~isnan(x)
                    amp = handles.amp_map(round(y),round(x));
                    handles.ISItime = 1./handles.freq_map(round(y),round(x))+0.15;
                else
                    amp = 0;
                end
            case 4 % random
                if ~isnan(x)
                    amp = 0+(5+0)*rand(1,1);
                    handles.ISItime = 1./handles.freq_map(round(y),round(x))+0.15;
                else
                    amp = 0;
                end
            otherwise
                error('unknown optoControl variable');
        end
        
        if length(x0) > 10
            xU = sum(~isnan(x0(end-10:end)))>5;
        else
            xU = 0;
            % etlaststim = tic; 2019-06-14 AndyP and TK this is wrong!!!
        end
        
        stimclock = toc(etlaststim);
        qGO = stimclock > handles.ISItime-0.05; %TK 6/17/19
        stimGO = stimclock > handles.ISItime; % rand 1-3s interval %TK 6/17/19

        nogozone = 200 > sqrt((x-576).^2+(y-15).^2);
        edge = x < 50 | x > size(IM,2)-50 | y < 50 | y > size(IM,1)-50;
        
        
        if qGO && ~(RewardZoneOn) && xU && Qct < 1 % queue signal

            sigOut = zeros(length(t_stim),1); %returns an array of zeros
            sigOut(1:3) = repmat(amp,[3,1]);
            queueOutputData(handles.DAQ.s3, sigOut);
            Qct = Qct + 1;
            qGO = 0;
            tQueue = cat(1,tQueue,timeofFrameAcq);
        end
        
        %         if ~handles.DAQ.s3.IsRunning && handles.DAQ.s3.ScansQueued > 3
        %             prepare(handles.DAQ.s3);
        %         end
        
        if ~mod(frameNum,nUpdate)==0 && ~handles.DAQ.s3.IsRunning && Qct > 0 && stimGO && xU && ~(RewardZoneOn || nogozone || edge)
            stimGO = 0;
            startBackground(handles.DAQ.s3);
            Qct = 0;
            etlaststim = tic;
            timeOut0 = cat(1,timeOut0,timeofFrameAcq);
            amp0 = cat(1,amp0,amp);
            ISI0 = cat(1,ISI0,handles.ISItime);
        end
        
        if ~handles.DAQ.s3.IsRunning && (RewardZoneOn || ~xU || nogozone || edge) && Qct==0 % signal is outputting
            sigOut = zeros(65,1); %returns an array of zeros
            queueOutputData(handles.DAQ.s3, sigOut);
            startBackground(handles.DAQ.s3);
            %stop(handles.DAQ.s3); % long ~0.1Hz delay, causing long
            timeOutStop0 = cat(1,timeOutStop0,timeofFrameAcq);
            etlaststim = tic;
            Qct = 0;
            %timeOutQ0 = cat(1,timeOutQ0,timeofFrameAcq);
            %outputs at high voltage?
            
            
        end
        
    end
    
    
    
    x0 = cat(1,x0,x);
    y0 = cat(1,y0,y);
    nx0 = cat(1,nx0,nx);
    ny0 = cat(1,ny0,ny);
    tx0 = cat(1,tx0,tx);
    ty0 = cat(1,ty0,ty);
    frame0 = cat(1,frame0,frameNum);
    time0 = cat(1,time0,timeofFrameAcq);
    mouseLength0 = cat(1,mouseLength0,mouseLength);
    mouseArea0 = cat(1,mouseArea0,mouseArea);
    fillV0 = cat(1,fillV0,fillV);
    switchNT0 = cat(1,switchNT0,switchNT);

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
        set(hImage,'CData',IM); hold on; axis xy; % % 2019-05-17 Try multiple frames / trigger? Change IM to IMnew
        %2019-02-27 much faster
        P2 = plot(x,y,'ro','markersize',20); P3 = plot(nx,ny,'gx','markersize',10); %line([x,nx],[y,ny],'color','r');
        set(gca,'Position',[hAxes.Position(1),hAxes.Position(2),hAxes.Position(3),hAxes.Position(4)]);
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
            amp_map = handles.amp_map;
            ISI_map = handles.freq_map;
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
            save(strcat(saveStr,'.mat'),'amp_map','ISI_map','timeOutQ0','AmpOutNoise','tQueue','fixedQueueTimeBugforOptoNoise','ISI','timeOutStop0','timeOut0','t_stim_noise_exp','t_stim','optoNoiseAmpOut','optoNoise','manualCamera','fixedRadiusBug','ISI0','amp0','loopRate','tstim_max','optoControl','frame0','time0','r','tx0','ty0','mouseLength0','pixpercm','radiusAroundSpot','trialNum','trialStartT','foundSpotT','maxSessT','nPelletsPerTrial','spotTrial','x0','y0','nx0','ny0','V','cx','cy','mouseArea0','switchNT0','fillV0','useBody','ITI','autoReward','gauss_width','fanx','fany');
            
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

handles.optoNoiseAmpOut = 5; % 2019-06-20 AndyP and TK fixed at 5V
handles.gauss_width = handles.radiusAroundSpot*5.174; % How fast do you want the laser stimulation to fall off
[handles.cx,handles.cy]=ginput(1); % Click a point that you want to be the center of a circle
[handles.binary_map, handles.freq_map, handles.amp_map, handles.dist_map ] = circle_target( handles.V.baseFrame, handles.radiusAroundSpot, handles.cx, handles.cy, handles.gauss_width,handles.optoNoiseAmpOut); % edit this script to change how the characteristics of light stimulation vary with distance from the target
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


% --- Executes on button press in OptoOff.
function OptoOff_Callback(hObject, eventdata, handles)
% hObject    handle to OptoOff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OptoOff
if get(hObject,'Value')==1
    handles.optoControl = 0;
    set(handles.OneSecondButton,'Value',0);
    set(handles.RandomAmp,'Value',0);
    set(handles.RandButton,'Value',0);
    set(handles.OptoOff,'Value',1);
    set(handles.VaryAmplitude,'Value',0);
    set(handles.OptoNoiseON,'Value',false);
    guidata(hObject,handles);
end

% --- Executes on button press in VaryAmplitude.
function VaryAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to VaryAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VaryAmplitude
if get(hObject,'Value')==1
    handles.optoControl = 1;
    set(handles.OneSecondButton,'Value',0);
    set(handles.RandomAmp,'Value',0);
    set(handles.RandButton,'Value',0);
    set(handles.OptoOff,'Value',0);
    set(handles.VaryAmplitude,'Value',1);
    set(handles.OptoNoiseON,'Value',false);
    %     set(handles.VaryFrequency,'Value',0);
    %     set(handles.VaryFreqAndAmp,'Value',0);
    guidata(hObject,handles);
end

% % --- Executes on button press in VaryFrequency.
% function VaryFrequency_Callback(hObject, eventdata, handles)
% % hObject    handle to VaryFrequency (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
%
% % Hint: get(hObject,'Value') returns toggle state of VaryFrequency
% if get(hObject,'Value')==1
%     handles.optoControl = 2;
%     set(handles.OptoOff,'Value',0);
%     set(handles.VaryAmplitude,'Value',0);
%     set(handles.VaryFreqAndAmp,'Value',0);
%     guidata(hObject,handles);
% end

% % --- Executes on button press in VaryFreqAndAmp.
% function VaryFreqAndAmp_Callback(hObject, eventdata, handles)
% % hObject    handle to VaryFreqAndAmp (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
%
% % Hint: get(hObject,'Value') returns toggle state of VaryFreqAndAmp
% if get(hObject,'Value')==1
%     handles.optoControl = 3;
%     set(handles.OptoOff,'Value',0);
%     set(handles.VaryAmplitude,'Value',0);
%     set(handles.VaryFrequency,'Value',0);
%     guidata(hObject,handles);
% end


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


% --- Executes on button press in UseBody.
function UseBody_Callback(hObject, eventdata, handles)
% hObject    handle to UseBody (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of UseBody
set(handles.StopLoopCHK,'Value',1);
handles.useBody = true;
%set(handles.ThresholdSlider,'Value',handles.V.videoParms.threshold);
guidata(hObject,handles);
pause(0.2);
set(handles.StopLoopCHK,'Value',0);
guidata(hObject,handles);


% --- Executes on button press in SaveData.
function SaveData_Callback(hObject, eventdata, handles)
% hObject    handle to SaveData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SaveData


% --- Executes on button press in WindTrial.
function WindTrial_Callback(hObject, eventdata, handles)
% hObject    handle to WindTrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

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
[handles.binary_map, handles.freq_map, handles.amp_map, handles.dist_map ] = circle_target( handles.V.baseFrame, handles.radiusAroundSpot*handles.pixpercm, handles.cx, handles.cy, handles.gauss_width); % edit this script to change how the characteristics of light stimulation vary with distance from the target
disp('Click on the tip of the pen placed next to the fan');
[handles.fanx,handles.fany]=ginput(1); % Click a point on the table where the axis of the fan is, put a pen on the table to click on.

fprintf('session time: %0.2f s \n',handles.maxSessT);

soundsc(handles.endtone);
pause(1);

guidata(hObject,handles);
pause(1);


% % --- Executes on button press in BlackMouse.
% function BlackMouse_Callback(hObject, eventdata, handles)
% % hObject    handle to BlackMouse (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
%
% % Hint: get(hObject,'Value') returns toggle state of BlackMouse


% --- Executes on button press in OptoNoiseON.
function OptoNoiseON_Callback(hObject, eventdata, handles)
% hObject    handle to OptoNoiseON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OptoNoiseON
if get(handles.OptoNoiseON,'Value')
    handles.optoNoise = true;
    set(handles.OptoOff,'Value',1);
    %     set(handles.VaryAmplitude,'Value',0);
    %     set(handles.VaryFrequency,'Value',0);
    %     set(handles.VaryFreqAndAmp,'Value',0);
else
    handles.optoNoise = false;
end
%set(handles.ThresholdSlider,'Value',handles.V.videoParms.threshold);
pause(0.2);
guidata(hObject,handles);


% --- Executes on button press in OneSecondButton.
function OneSecondButton_Callback(hObject, eventdata, handles)
% hObject    handle to OneSecondButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%This button will now be used for 0V random stims TK 6/17/19
% Hint: get(hObject,'Value') returns toggle state of OneSecondButton
set(handles.OneSecondButton,'Value',1);
set(handles.RandomAmp,'Value',0);
set(handles.RandButton,'Value',0);
set(handles.OptoOff,'Value',1);
set(handles.VaryAmplitude,'Value',0);
% set(handles.VaryAmplitude,'Value',0);
% set(handles.VaryFrequency,'Value',0);
% set(handles.VaryFreqAndAmp,'Value',0);
handles.optoNoise = true;
set(handles.OptoNoiseON,'Value',true);
handles.ISI = 1;
guidata(hObject,handles);

% --- Executes on button press in RandButton.
function RandButton_Callback(hObject, eventdata, handles)
% hObject    handle to RandButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RandButton
set(handles.OneSecondButton,'Value',0);
set(handles.RandomAmp,'Value',0);
set(handles.RandButton,'Value',1);
set(handles.OptoOff,'Value',1);
set(handles.VaryAmplitude,'Value',0);
%set(handles.VaryFrequency,'Value',0);
%set(handles.VaryFreqAndAmp,'Value',0);
handles.optoNoise = true;
set(handles.OptoNoiseON,'Value',true);
handles.ISI = 2;
guidata(hObject,handles);


% --- Executes on button press in RandomAmp.
function RandomAmp_Callback(hObject, eventdata, handles)
% hObject    handle to RandomAmp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RandomAmp
if get(hObject,'Value')==1
    handles.optoControl = 4;
    set(handles.OneSecondButton,'Value',0);
    set(handles.RandomAmp,'Value',1);
    set(handles.RandButton,'Value',0);
    set(handles.OptoOff,'Value',0);
    set(handles.VaryAmplitude,'Value',0);
    set(handles.OptoNoiseON,'Value',false);
    guidata(hObject,handles);
end



% --- Executes during object creation, after setting all properties.
function VaryOptoAmp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VaryOptoAmp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in varyISI.
function varyISI_Callback(hObject, eventdata, handles)
% hObject    handle to varyISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of varyISI
if get(hObject,'Value')==1
    handles.optoControl = 2;
    set(handles.OneSecondButton,'Value',0);
    set(handles.RandomAmp,'Value',0);
    set(handles.RandButton,'Value',0);
    set(handles.OptoOff,'Value',0);
    set(handles.VaryAmplitude,'Value',0);
    set(handles.OptoNoiseON,'Value',false);
    guidata(hObject,handles);
end

% --- Executes on button press in varyAmpandISI.
function varyAmpandISI_Callback(hObject, eventdata, handles)
% hObject    handle to varyAmpandISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of varyAmpandISI
if get(hObject,'Value')==1
    handles.optoControl = 3;
    set(handles.OneSecondButton,'Value',0);
    set(handles.RandomAmp,'Value',0);
    set(handles.RandButton,'Value',0);
    set(handles.OptoOff,'Value',0);
    set(handles.VaryAmplitude,'Value',0);
    set(handles.OptoNoiseON,'Value',false);
    guidata(hObject,handles);
end
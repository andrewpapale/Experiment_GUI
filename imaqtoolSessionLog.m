vid = videoinput('pointgrey', 1, 'F7_Mono8_1280x1024_Mode0');
src = getselectedsource(vid);

vid.FramesPerTrigger = 1;

preview(vid);

stoppreview(vid);

src.ExposureMode = 'Manual';

src.FrameRatePercentageMode = 'Manual';

src.SharpnessMode = 'Manual';

src.ShutterMode = 'Manual';

src.GainMode = 'Manual';

src.FrameRatePercentage = 30;

preview(vid);

start(vid);

stoppreview(vid);

stop(vid);

vid.FramesPerTrigger = Inf;

vid.LoggingMode = 'disk';

diskLogger = VideoWriter('C:\Users\pwjones\matlab\Matlab_makeROI\Matlab_makeROI\test.avi', 'Grayscale AVI');

vid.DiskLogger = diskLogger;

diskLogger = VideoWriter('C:\Users\pwjones\matlab\Matlab_makeROI\Matlab_makeROI\test.avi', 'Motion JPEG AVI');

vid.DiskLogger = diskLogger;

preview(vid);

start(vid);

stoppreview(vid);

stop(vid);

vid.FramesPerTrigger = 1;

vid.FramesPerTrigger = 900;

src.FrameRatePercentage = 100;

preview(vid);

start(vid);

stoppreview(vid);

stop(vid);


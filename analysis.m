

% Displays stim & amplitudes at positions on table
% load one file
% ix = interp1(time0,frame0,timeOut0,'nearest');
%plot(x0,y0,'k.')
%hold on
%scatter(x0(ix),y0(ix),ISI0*100,amp0,'filled')
%viscircles([cx,cy],2.0*5.174) % shows spot 2cm
%colorbar

%plot(frame0,x0)
%hold on
%ix = interp1(time0,frame0,timeOut0,'nearest');
%ixs = interp1(time0,frame0,trialStartT,'nearest');
%plot(ixs,x0(ixs),'go')
%ixf = interp1(time0,frame0,foundSpotT,'nearest');
%plot(ixf,x0(ixf),'ro');
%plot(ix,x0(ix),'bx')

%only of interest for OptoNoise
%ix = interp1(time0,frame0,timeOut0(AmpOutNoise==5),'nearest');
%plot(ix,x0(ix),'bo')
%clf
%plot(frame0,x0)
%hold on

ix0 = interp1(time0,frame0,timeOut0(AmpOutNoise==0),'nearest');
ix5 = interp1(time0,frame0,timeOut0(AmpOutNoise==5),'nearest');
 
time_1 = ix5(1);
x_before = x0((time_1 - 10):time_1-1);
x_after = x0((time_1+1):(time_1+10));

y_before = y0((time_1 - 10):time_1-1);
y_after = y0((time_1+1):(time_1+10));

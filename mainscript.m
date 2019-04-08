clear;

% Open and show image of table

%cd('C:\Users\pwjones\dev\ccv15_pgr\apps\addonsExamples\VS2008\bin');
table_img=imread('savedBg.jpg');
%cd('C:\Users\pwjones\matlab\Matlab_makeROI\Matlab_makeROI');
%table_img=flipud(table_img);

imshow(table_img);

gauss_width = 100; % How fast do you want the laser stimulation to fall off

max_amp = 1; % maximum amplitude of the laser 

% Now decide whether you want to draw a trail or a circle. Block out the
% code that you won't use.


% Draw circle

radius = 50; % How big of a target do you want? 40 is perfect for the 7cm diameter filter papers that are in the behavioral room

disp('Click on the center of the target region');
[cx,cy]=ginput(1); % Click a point that you want to be the center of a circle
[ binary_map, prob_map, amp_map, dist_map ] = circle_target( table_img, radius, cx, cy, gauss_width, max_amp ); % edit this script to change how the characteristics of light stimulation vary with distance from the target

%disp('Make the region where the animal will be in between trials'); % draw area where the animal will be in between trials - the next trial will not start until the animal leaves this area
%[J,lick_map]=roifill(table_img);

binary_map=uint8(binary_map*255); % binary map that is white where the target is


%prob_map=uint8(255*prob_map); % map of how the probability of laser stimulation falls off with distance from the target
%lick_map=uint8(lick_map)*255; % map of where the prechamber is - that is, where the animal will be kept in between trials. You 
%amp_map=uint8(255*amp_map); % same as the probablity map only with the value of the laser amplitude vary with distance

figure;imshow(prob_map);
figure;imshow(binary_map);
%figure;imshow(lick_map);
figure;imshow(amp_map);

cd('C:\Users\pwjones\dev\ccv15_pgr\apps\addonsExamples\VS2008\bin');

imwrite(binary_map,'binary_map.tif');
imwrite(prob_map,'prob_map.tif');
%imwrite(lick_map,'lick_map.tif');
imwrite(amp_map,'amp_map.tif');

cd('C:\Users\pwjones\matlab\Matlab_makeROI\Matlab_makeROI');

clear


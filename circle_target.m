function [ binary_map, freq_map, amp_map, dist_map ] = circle_target( table_img, radius, cx, cy, gauss_width,optoNoiseAmpOut)
% table_img : pic of the table
% radius : size of target region
% cx, cy : x and y location of the center of the target
% gauss width : how quickly the amplitude or probability of laser
%               stimulation falls off
% max_amp : maximum laser amplitude

% number of pixels of the table
y_tot=length(table_img(:,1)); 
x_tot=length(table_img(1,:));


binary_map=zeros(y_tot,x_tot);
d_sqrd=zeros(y_tot,x_tot);

for i=1:y_tot
    for j=1:x_tot
        d_sqrd(i,j)=((i-cy)^2) + ((j-cx)^2); % This loop finds the distance from every point in the map to the center of the target
    end
end

dist_map=sqrt(d_sqrd);

%freq_map=round((21*gaussmf(dist_map,[gauss_width 0]))+1);
freq_map = [];

%amp_map=gaussmf(dist_map,[gauss_width 0]);
% BIG ASSUMPTION!!! currently, the script assumes that the gaussian for the probablity and amplitude maps will be the same 
                          % alter script accordingly if we want these two
                          % parameters to change independently of each
                          % other


                          
nX = size(dist_map,1);
nY = size(dist_map,2);
%temp = log10(1./(dist_map+0.1));
% https://math.stackexchange.com/questions/914823/shift-numbers-into-a-different-range
% f(t) = c+((d-c)/(b-a))(t-a)  [a,b]->[c,d]

dist_map(dist_map <= radius) = 0;
temp = dist_map;
amp_map = 4+((2-4)./(max(temp(:))-min(temp(:)))).*(temp)-min(temp(:));

% amp_map = (amp_map - min(amp_map(:)))*(4-2)/(max(amp_map(:))-min(amp_map(:))) + 2;  
end


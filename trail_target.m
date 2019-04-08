function [ binary_map, prob_map, amp_map, dist_map ] = trail_target(table_img, width, pos, gauss_width, max_amp)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

y_tot=length(table_img(:,1));
x_tot=length(table_img(1,:));

binary_map=zeros(y_tot,x_tot);
d_sqrd=zeros(y_tot,x_tot);



for i=1:y_tot
    for j=1:x_tot
        d2=zeros(length(pos(:,1)),1);
        for k=1:length(pos(:,1))
            
            d2(k,1)=((i-pos(k,2))^2) + ((j-pos(k,1))^2);
            [C,ind]=min(d2);
           
        end
        
        d_sqrd(i,j)=((i-pos(ind,2))^2) + ((j-pos(ind,1))^2);
    end
end

dist_map=sqrt(d_sqrd);
binary_map(d_sqrd<(width^2))=1;

prob_map=gaussmf(dist_map,[gauss_width 0]);
amp_map=prob_map*max_amp;

end


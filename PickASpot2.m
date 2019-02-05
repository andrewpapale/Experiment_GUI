%PickASpot
function[answer] = PickASpot2()

%Nspots = 14;

rng('shuffle');
%switch Nspots
   % case 14
        % return a letter A-M
        B = randperm(8);
        C = {'1 ON','2 ON','3 ON','4 ON','1 OFF','2 OFF', '3 OFF', '4 OFF'};
        A = C(B);
  %  case 72
        % return a number 1-72
      %  A = randi(72,[5,1]);
  %  otherwise
     %   error('unknown Nspots, choose 16 or 72 to match with cardboard template');
%end


answer=[A];
end


clear all
close all
clc;
vid = videoinput('pointgrey', 1, 'F7_Mono8_1280x1024_Mode0');

                    
                
vidInfo = imaqhwinfo(vid); % Acquire input video property
hVideoIn = vision.VideoPlayer('Name', 'Final Video', ... % Output video player
                                'Position', [100 100 vidInfo.MaxWidth+20 vidInfo.MaxHeight+30]);
nFrame = 0; % Frame number initialization
umbral=0.2; %Umbral para binarizar
%    rectangle('position',[(406-40),(399-40),80,80],'EdgeColor', 'b');
% rectangle('position',[(532-40),(344-40),80,80],'EdgeColor', 'm');
%% Processing Loop
tic
              %variables
recorte1=0;
bandera=0;
%bandera2=0;
sent=0;
%tiempo=toc;
velocidad=0;
estado=0;
giro=0;
tiempo=toc;
%variables para contabilizar RPM
rpm=0;
bandera_vuelta=0;
tic  %comienza el conteo de frames
while(nFrame < 10)
    
    frame = vid; % Acquire single frame
        recorte=frame((399-40):(399+40),(406-40):(406+40));
        recorbin1=im2bw(recorte,umbral);
        recorte2=frame((344-40):(344+40),(532-40):(532+40));
        recorbin2=im2bw(recorte2,umbral);
        subplot(3,1,1),imshow(frame)
        rectangle('position',[(406-40),(399-40),80,80],'EdgeColor', 'b');
        rectangle('position',[(532-40),(344-40),80,80],'EdgeColor', 'm');
        subplot(3,1,2),imshow(recorbin1)
        subplot(3,1,3),imshow(recorbin2)
        pause(0.01)
        
        %Conteo de vueltas
        if (recorbin1==1 & bandera_vuelta==0  )
            if (bandera_vuelta==0)
                %bandera_vuelta=1;
                rpm=rpm+1
                
            end
        end
        
        nFrame=nFrame+1;
        if nFrame==10
            toc
            nFrame=0;
            tic
        end 
%               %variables
% recorte1=0;
% bandera=0;
% sent=0;
% %tiempo=toc;

        %Crear matrices de rectangulos
variable=[(406-40),(399-40),80,80];
M=imcrop(recorbin1,variable);
variable1=[(532-40),(344-40),80,80];
M1=imcrop(recorbin2,variable1);

SM=(sum(sum(not(recorbin1)))); %Suma de matriz para que te quede un valor
SM1=(sum(sum(not(recorbin2))));
% SM=(sum(sum(M)/11*11)); %Suma de matriz para que te quede un valor
% SM1=(sum(sum(M1)/11*11));

SM_1=floor(SM); % Elimina decimales de la matriz
SM_2=floor(SM1);

%Direccion del giro
  switch recorte1
     case 0
         if (SM_1~=1 && SM_2~=0)%1,1
           recorte1=1;
         end 
             case 1
                 if (SM_1~=1 && SM_2~=0) % 0,0
           recorte1=2;
                 end
             case 2
                 if(SM_1~=0 && SM_2~=0 && bandera==0)
                     disp('derecha');
                       bandera=1; %1 ... 0
                       sent=1;
                 elseif (SM_1~=1 && SM_2~=0 && bandera==0)
                  disp('izquierda');
                   bandera=1; %1....1
                   sent=2;
                 end
%                  
%               %  giro en rpm
%                   switch velocidad
%                      case 0
%                         if M==1
%                             giro=giro;
%                             eatado=1;
%                             %disp('desplegar dato=')
%                         else
%                             estado=0;
%                         end
%                      case 1
%                          if M==1
%                              giro=giro+1;
%                              estado=0;
%                          else
%                              estado=1;
%                          end
%  
%                  end
%  veloz_1=(round(giro/2));% rouund=redondeo
%  veloz=(round((veloz_1/tiempo)*60));% toc=tiempo de captura de imagenes 
%  disp('giro=');
%  %desplegar velocidad
%  disp(veloz);


  end
end
 
% toc
%% Clearing Memory
release(hVideoIn); % Release all memory and buffer used
release(vidDevice);
clear all;
clc;
%estados de giros

%% Get file to analyze  ***FOR NEW DATA

data_dir=uigetdir('C:\Documents and Settings\UrbanLab\Desktop\basic_code_2015_revamp Folder','Choose a data folder to import');
destination=uigetdir('C:\Data','Choose a folder to keep this data');
[pathstr,name]=fileparts(data_dir);
mkdir(destination,name);
new_dir=fullfile(destination,name);
disp(strcat('Working on:','   ',name));
   
%% Get file to analyze **FOR EXISTING DATA

new_dir=uigetdir('C:\Data','Choose a folder to analyze');

%% Get metadata script    

meta=metadata();
save(fullfile(destination,name,'meta.mat'),'meta');

%% FFI inhib

ffi=ffi_inhib(new_dir);
save(fullfile(new_dir,'ffi.mat'),'ffi');

%% Import IBW files
image_NU=fullfile('C:\Documents and Settings\UrbanLab\Desktop\Image_Basic_NU3 Folder');
imports=uigetfile('.ibw','What ibw files should be analyzed?', image_NU, 'MultiSelect', 'on');
%import_ibws; c=imfuse(gbz2,cell_adapt);

import_movies;

%% Import MINIs

imports=uigetfile('.ibw','FOR MINIS ONLY: What ibw files should be analyzed?', data_dir, 'MultiSelect', 'on');
import_minis;

%% Structure MINI Data

restructure_exs;
restructure_m;
redo_minis;

%% Import and analyze passive membrane properties (passive)

pass_props=uigetfile('*.ibw','What passive file should be analyzed?', data_dir);
passive=pass_mem_data(data_dir,pass_props);

save(fullfile(destination,name,'passive.mat'),'passive');


%% Import and analyze Rs (transients)


trans=uigetfile('*.ibw','What transients file should be analyzed?', data_dir);
transients=transients_data(data_dir,trans);
save(fullfile(destination,name,'transients.mat'),'transients');

%% Recurrent Inhibion

recurrent=recurr_calc(new_dir);
save(fullfile(new_dir,'recurrent.mat'),'recurrent');



%% Import current steps

depol=uigetfile('*.ibw','What depol file should be analyzed to calculate an FI curve?', data_dir);
fis=IBWread(fullfile(data_dir,depol));
FI=FI_props(fis.y);
save(fullfile(destination,name,'FI.mat'),'FI');


%% Calculate the Reliability of noise
noise=noise_calc(new_dir);
save(fullfile(new_dir,'noise.mat'),'noise');



%% Paired Pulse Ratio

PPR_importer; 
save(fullfile(new_dir,'ppr.mat'),'ppr');

%% Glomerular Input-Output curve

stimI=stimi_data(new_dir);
save(fullfile(new_dir,'stimI.mat'),'stimI');

%% Glomerular Stim w/ Spiking and PSTH construction

stimSP=stimi_spike(new_dir); 

stimSP_final=stim_PSTH(stimSP);

[stimSP,stimSP_final]=PSTH_resort_compile(stimSP,stimSP_final);
stimSP=reliability1(stimSP);

save(fullfile(new_dir,'stimSP_final.mat'),'stimSP_final');
save(fullfile(new_dir,'stimSP.mat'),'stimSP');


%% STIMSP1
stimSP1=stimi_spike(new_dir); 

stimSP_final1=stim_PSTH(stimSP1);

[stimSP1,stimSP_final1]=PSTH_resort_compile(stimSP1,stimSP_final1);
stimSP1=reliability1(stimSP1);

save(fullfile(new_dir,'stimSP_final1.mat'),'stimSP_final1');
save(fullfile(new_dir,'stimSP1.mat'),'stimSP1');


%% STIMSP2
stimSP2=stimi_spike(new_dir); 

stimSP_final2=stim_PSTH(stimSP2);

[stimSP2,stimSP_final2]=PSTH_resort_compile(stimSP2,stimSP_final2);
stimSP2=reliability1(stimSP2);

save(fullfile(new_dir,'stimSP_final2.mat'),'stimSP_final2');
save(fullfile(new_dir,'stimSP2.mat'),'stimSP2');

%% Glomerular Stim w/ drugs

[stimSP_d, stimSP_final_d, stim_compare]=stimi_drugs(new_dir);

save(fullfile(new_dir,'stimSP_final_d.mat'),'stimSP_final_d');
save(fullfile(new_dir,'stimSP_d.mat'),'stimSP_d');

save(fullfile(new_dir,'stim_compare.mat'),'stim_compare');


%% M72-Chr2 Lateral Inhibition

m72_lat=m72_lat_data(new_dir);
save(fullfile(new_dir,'m72_lat.mat'),'m72_lat');

%% OMP-Chr2 Lateral Inhibition

omp_lat_pre=omp_lat_data_pre(new_dir);
omp_lat_post=omp_lat_data_post(new_dir);
omp_lat_ratio=omp_lat_data_ratio(omp_lat_pre,omp_lat_post);

save(fullfile(new_dir,'omp_lat_pre.mat'),'omp_lat_pre');
save(fullfile(new_dir,'omp_lat_post.mat'),'omp_lat_post');
save(fullfile(new_dir,'omp_lat_ratio.mat'),'omp_lat_ratio');

%% M72-ChR2 Lat Inhibition --- SPIKING
m72_spike=m72_spike_data(new_dir);
save(fullfile(new_dir,'m72_spike.mat'),'m72_spike');



%% Image Importer

image_NU=fullfile('C:\Documents and Settings\UrbanLab\Desktop\Image_Basic_NU3 Folder');
m72_im=m72_image_data(image_NU);
save(fullfile(new_dir,'m72_im.mat'),'m72_im');

%% Import hyperpolarizations

hyper=uigetfile('*.ibw','What hyper file should be analyzed to calculate Sag current?', data_dir);
sag=sag_calc(hyper,data_dir);
save(fullfile(data_dir,'sag.mat'),'sag');


%% Import entrainment experiments
%% Import spontaneous spiking
LLDs=dir(fullfile(data_dir,'LLD_ic*'));
[ LLD_ic ] = LLD_ic_importer( LLDs, data_dir );
[LLD_ic]=LLD_ic_data(LLD_ic);
save(fullfile(data_dir,'LLD_ic.mat'),'LLD_ic');
    

%% Calcium imaging movie importer
image_NU=fullfile('C:\Documents and Settings\UrbanLab\Desktop\Image_Basic_NU2 Folder');
imports=uigetfile('.ibw','What ibw files should be analyzed?', image_NU , 'MultiSelect', 'on');

import_movies;

%% Process Calcium imaging experiments

import_s=uigetfile('.mat','FOR SPIKING TRIAL ONLY: What .mat files should be analyzed?', new_dir);
import_m=uigetfile('.mat','FOR MOVIE TRIALS ONLY: What .mat files should be analyzed?', new_dir, 'MultiSelect', 'on');

FI=ca_spikes(new_dir,import_s);
ca_im=ca_imaging(new_dir, FI,import_m);

cd(new_dir);
uisave('ca_im','ca_im');
uisave('FI','FI');
cd('C:\Documents and Settings\UrbanLab\My Documents\Dropbox\Code\Entrainment_code');
function [] = PSDSInSAR_estimator(Coh,  slcstack, slclist, interfstack, interflist, SHP, reference_ind,  InSAR_path, BroNumthre, Cohthre, Cohthre_slc_filt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   This file is part of TomoSAR.
%
%   TomoSAR is distributed in the hope that it will be useful,
%   but without warranty of any kind; without even the implied 
%   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
%   See the Apache License for more details.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author : Dinh Ho Tong Minh (INRAE) and Yen Nhi Ngo, Jan. 2022 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function provides the combination of PS and DS targets
% see more detail in section 2 of [1]:
% [1] Dinh Ho Tong Minh and Yen Nhi Ngo. 
% "Compressed SAR Interferometry in the Big Data Era". Remote Sensing.  
% 2022, 14, 390. https://doi.org/10.3390/rs14020390 
%
% This file can be used only for research purposes, you should cite 
% the aforementioned papers in any resulting publication.
%

% Phase Linking
[phi_PL,Coh_cal] =  Intf_PL(Coh, 10,reference_ind);

% Phase filtering
[infstack_filt] = Intf_filt(interfstack,SHP,phi_PL,Coh_cal,reference_ind,BroNumthre,Cohthre);

% DeSpeckle
mli_despeckle = Image_DeSpeckle(abs(slcstack),SHP);
[SLCstack] = SLC_filt(mli_despeckle,slcstack,SHP,Coh_cal,BroNumthre,Cohthre_slc_filt);

% Export
Intf_export(infstack_filt,interflist,[InSAR_path,'/diff0'],'.psds');
SLC_export(SLCstack,slclist,[InSAR_path,'/rslc'],'.psar');

return
function [] = ComSAR_estimator(Coh_matrix, slcstack, slclist, interfstack, interflist, SHP_ComSAR, InSAR_path, BroNumthre, Cohthre, miniStackSize, Cohthre_slc_filt)

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

% This function provides the compressed SAR of PS and DS targets
% see more detail in section 3 of [1]:
% [1] Dinh Ho Tong Minh and Yen Nhi Ngo. 
% "Compressed SAR Interferometry in the Big Data Era". Remote Sensing.  
% 2022, 14, 390. https://doi.org/10.3390/rs14020390 
%
% This file can be used only for research purposes, you should cite 
% the aforementioned papers in any resulting publication.
%

[nlines,nwidths,n_interf] = size(interfstack);
n_slc = n_interf + 1;

% normalize 
interfstack(interfstack~=0) = interfstack(interfstack~=0)./abs(interfstack(interfstack~=0));

[~,idx]=ismember(interflist,slclist);

reference_ind = idx(1);

if reference_ind > 1
    temp(:,:,[1:reference_ind-1,reference_ind+1:n_slc]) = interfstack;
    temp(:,:,reference_ind) = abs(slcstack(:,:,reference_ind-1));
else
    temp(:,:,1) = abs(slcstack(:,:,1));
    temp(:,:,[2:n_slc]) = interfstack;
end   
interfstack = temp; clear temp

interfstack = abs(slcstack).*exp(1i*angle(interfstack)); % get SLC amplitude

% assume the reference is not change, size of mini stacks and number of mini stack
if reference_ind > miniStackSize
    mini_ind_before = sort(reference_ind-miniStackSize:-miniStackSize:1); 
    mini_ind_after = reference_ind:miniStackSize:n_slc; 
    mini_ind = [mini_ind_before, mini_ind_after]; 
else
    mini_ind = reference_ind:miniStackSize:n_slc;
end

[~,reference_ComSAR_ind]=ismember(reference_ind,mini_ind);

numMiniStacks = length(mini_ind);

% Compressed SLCs stack
compressed_SLCs = zeros(nlines,nwidths, numMiniStacks, 'single'); 
slcstack_ComSAR = zeros(nlines,nwidths, numMiniStacks, 'single'); 

for k = 1 : numMiniStacks 
    if k == numMiniStacks
        cal_ind = mini_ind(k):n_slc; 
    else    
        cal_ind = mini_ind(k):mini_ind(k+1)-1; 
    end    
    Coh_temp = Coh_matrix(cal_ind, cal_ind,:,:); 
    
    % The transformation for the mini-stack 
    [~, ~, v_ML] = Intf_PL(Coh_temp, 10);
 
    % Compressing SLC 
    compressed_SLCs(:,:,k) = sum(v_ML.*interfstack(:,:,cal_ind),3); 
end

% If the number of compressed_SLCs > 15, SHP can be recalculated   
% [SHP_ComSAR]=SHP_SelPoint(abs(compressed_SLCs),CalWin,Alpha); 

% phase linking for Compressed SLCs 
cov_compressed_slc = SLC_cov(compressed_SLCs,SHP_ComSAR);
[phi_PL_compressed,Coh_cal] =  Intf_PL(cov_compressed_slc, 10,reference_ComSAR_ind);
phi_PL_compressed(:,:,reference_ComSAR_ind) = []; % the reference is removed in the differential phases

% Phase filtering
mask_coh = Coh_cal > Cohthre;
mask_PS = SHP_ComSAR.BroNum>BroNumthre;    
mask = and(mask_PS,mask_coh); %PS keep 
mask = repmat(mask,[1,1,numMiniStacks-1]);

interfstack_ComSAR = compressed_SLCs;
interfstack_ComSAR (:,:,reference_ComSAR_ind) = []; % the reference is removed in the differential phases
interfstack_ComSAR(mask) = abs(interfstack_ComSAR(mask)).*exp(1i*phi_PL_compressed(mask));
    
% DeSpeckle for Compressed SLCs
mli_despeckle = Image_DeSpeckle(abs(compressed_SLCs),SHP_ComSAR);
mask_coh = Coh_cal > Cohthre_slc_filt; 
mask = and(mask_PS,mask_coh);
mask = repmat(mask,[1,1,numMiniStacks]);
slcstack_ComSAR(mask) = abs(mli_despeckle(mask)).*exp(1i*angle(compressed_SLCs(mask)));
 
% Name index for ComSAR
slcstack_ComSAR_filename = slclist(mini_ind);
[~,idx]=ismember(interflist,slcstack_ComSAR_filename);
interfstack_ComSAR_filename = interflist(find(idx(:,2) ~= 0),: );

% Export ComSAR products
Intf_export(interfstack_ComSAR,interfstack_ComSAR_filename,[InSAR_path,'/diff0'],'.comp');
SLC_export(slcstack_ComSAR,slcstack_ComSAR_filename,[InSAR_path,'/rslc'],'.csar');


return  


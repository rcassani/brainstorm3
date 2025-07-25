function bst_spmtrip(SpmDir, FieldTripDir, OutputDir)
% BST_SPMTRIP Make a copy of some of the FieldTrip and SPM functions compiled with Brainstorm
%
% Requirements: 
%  - Run spm_make_standalone first
%  - FieldTrip configuration: Edit the list of compatibility path 
%
% Brainstorm features using external SPM functions:
%  - Anatomy: Import MRI > DICOM converter
%  - Anatomy: Import MRI > MNI normalization (SPM 'segment' method)
%  - Anatomy: Import MRI > MRI coregistration (SPM) and reslice (SPM)
%  - Anatomy: Import MRI > MRI realign (SPM)
%  - Anatomy: Import MRI > MRI skul stripping (SPM)
%  - Input: Read SPM .mat/.dat recordings
%  - Output: Save SPM .mat/.dat recordings
%  - Process1: Import > Import anatomy > Generate SPM canonical surfaces
%  - Process1: Epilepsy > Epileptogenicity maps
%  - Process1: Test > Apply statistic threshold
%  
% Brainstorm features using external FieldTrip:
%  - Input: Read FieldTrip data structure
%  - Process1: Frequency > FieldTrip: ft_mtmconvol (multitaper)
%  - Process1: Standardize > FieldTrip: ft_channelrepair
%  - Process1: Standardize > FieldTrip: ft_scalpcurrentdensity
%  - Process1: Sources > FieldTrip: ft_dipolefitting
%  - Process1: Sources > FieldTrip: ft_sourceanalysis
%  - Process2: Test > FieldTrip: ft_timelockstatistics
%  - Process2: Test > FieldTrip: ft_sourcestatistics
%  - Process2: Test > FieldTrip: ft_freqstatistics
%  - Process1: Sources > FieldTrip: ft_prepare_leadfield
%    => MRI: Undefined function or variable 'GridLoc'
%    => Using fieldtrip surfaces not implemented: requires ft_volumesegment
%  - Process1: Import > Import anatomy > FieldTrip: ft_volumesegment
%    => NOT SUPPORTED YET:  ft_checkconfig (line 155) : Missing cfg.template, cfg.tmp?

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c) University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Francois Tadel, 2019-2023


% ===== SPM STANDALONE =====
if ~exist(fullfile(SpmDir, 'Contents.txt'), 'file') || ~exist(fullfile(fileparts(SpmDir), 'standalone'), 'file')
    bst_plugin('Load', 'spm12');
    disp('SPMTRIP> Compiling SPM...');
    spm eeg;
    spm quit;
    spm_make_standalone();
    bst_plugin('Unload', 'spm12');
end

% ===== REQUIRED FUNCTIONS =====
% List required functions, valid for:
%   FieldTrip v.20210920
%   SPM12 v7771
needFunc = {...
    ... % === FIELDTRIP ====
    fullfile(FieldTripDir, 'ft_defaults.m'), ...
    fullfile(FieldTripDir, 'compat', 'matlablt2017b', 'isfolder.m'), ...
    fullfile(FieldTripDir, 'fileio', 'ft_read_headshape.m'), ...
    fullfile(FieldTripDir, 'forward', 'ft_apply_montage.m'), ...
    fullfile(FieldTripDir, 'forward', 'ft_convert_units.m'), ...
    fullfile(FieldTripDir, 'forward', 'ft_compute_leadfield.m'), ...
    fullfile(FieldTripDir, 'forward', 'ft_headmodel_concentricspheres.m'), ...
    fullfile(FieldTripDir, 'forward', 'ft_headmodel_localspheres.m'), ...
    ... fullfile(FieldTripDir, 'forward', 'ft_headmodel_simbio.m'), ...
    fullfile(FieldTripDir, 'forward', 'ft_headmodel_singleshell.m'), ...
    fullfile(FieldTripDir, 'forward', 'ft_headmodel_singlesphere.m'), ...
    fullfile(FieldTripDir, 'forward', 'private', 'eeg_leadfield1.m'), ...
    fullfile(FieldTripDir, 'forward', 'private', 'eeg_leadfield4.m'), ...
    fullfile(FieldTripDir, 'forward', 'private', 'eeg_leadfield4_prepare.m'), ...
    fullfile(FieldTripDir, 'forward', 'private', 'eeg_leadfieldb.m'), ...
    fullfile(FieldTripDir, 'forward', 'private', 'meg_forward.m'), ...
    fullfile(FieldTripDir, 'forward', 'private', 'meg_ini.m'), ...
    fullfile(FieldTripDir, 'forward', 'private', 'meg_leadfield1.mexw64'), ...
    ... fullfile(FieldTripDir, 'statfun', 'ft_statfun_depsamplesFmultivariate.m'), ...
    ... fullfile(FieldTripDir, 'statfun', 'ft_statfun_depsamplesFunivariate.m'), ...
    ... fullfile(FieldTripDir, 'statfun', 'ft_statfun_depsamplesregrT.m'), ...
    fullfile(FieldTripDir, 'statfun', 'ft_statfun_depsamplesT.m'), ...
    ... fullfile(FieldTripDir, 'statfun', 'ft_statfun_indepsamplesF.m'), ...
    ... fullfile(FieldTripDir, 'statfun', 'ft_statfun_indepsamplesregrT.m'), ...
    fullfile(FieldTripDir, 'statfun', 'ft_statfun_indepsamplesT.m'), ...
    ... fullfile(FieldTripDir, 'statfun', 'ft_statfun_indepsamplesregrT.m'), ...
    fullfile(FieldTripDir, 'ft_channelrepair.m'), ...
    fullfile(FieldTripDir, 'ft_dipolefitting.m'), ...
    fullfile(FieldTripDir, 'ft_freqstatistics.m'), ...
    fullfile(FieldTripDir, 'ft_prepare_headmodel.m'), ...
    fullfile(FieldTripDir, 'ft_prepare_leadfield.m'), ...
    fullfile(FieldTripDir, 'ft_prepare_neighbours.m'), ...
    fullfile(FieldTripDir, 'ft_prepare_sourcemodel.m'), ...
    fullfile(FieldTripDir, 'ft_scalpcurrentdensity.m'), ...
    fullfile(FieldTripDir, 'ft_sourceanalysis.m'), ...
    fullfile(FieldTripDir, 'ft_sourcestatistics.m'), ...
    fullfile(FieldTripDir, 'ft_timelockanalysis.m'), ...
    fullfile(FieldTripDir, 'ft_timelockstatistics.m'), ...
    fullfile(FieldTripDir, 'ft_statistics_montecarlo.m'), ...
    fullfile(FieldTripDir, 'ft_volumesegment.m'), ...
    fullfile(FieldTripDir, 'plotting', 'ft_plot_mesh.m'), ...
    fullfile(FieldTripDir, 'plotting', 'ft_plot_sens.m'), ...
    fullfile(FieldTripDir, 'compat', 'obsolete', 'ft_plot_vol.m'), ...
    fullfile(FieldTripDir, 'specest', 'ft_specest_mtmconvol.m'), ...
    fullfile(FieldTripDir, 'utilities', 'ft_datatype_sens.m'), ...
    fullfile(FieldTripDir, 'external', 'freesurfer', 'load_nifti.m'), ...
    fullfile(FieldTripDir, 'external', 'freesurfer', 'load_nifti_hdr.m'), ...
    fullfile(FieldTripDir, 'external', 'freesurfer', 'MRIread.m'), ...
    fullfile(FieldTripDir, 'external', 'freesurfer', 'MRIfspec.m'), ...
    fullfile(FieldTripDir, 'external', 'freesurfer', 'strlen.m'), ...
    fullfile(FieldTripDir, 'external', 'freesurfer', 'vox2ras_0to1.m'), ...
    fullfile(FieldTripDir, 'external', 'freesurfer', 'vox2ras_tkreg.m'), ...
    fullfile(FieldTripDir, 'external', 'images', 'rgb2hsv.m'), ...
    ...
    ... % === SPM12 ====
    fullfile(SpmDir, 'spm.m'), ...
    fullfile(SpmDir, 'spm_affine_priors.m'), ...
    fullfile(SpmDir, 'spm_bsplinc.m'), ...
    fullfile(SpmDir, 'spm_data_read.m'), ...
    fullfile(SpmDir, 'spm_dicom_convert.m'), ...
    fullfile(SpmDir, 'spm_dicom_header.m'), ...
    fullfile(SpmDir, 'spm_dicom_text_to_dict.m'), ...
    fullfile(SpmDir, 'spm_dilate.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_events.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_eyeblink.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_flat.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_heartbeat.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_jump.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_nans.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_peak2peak.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_saccade.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_threshchan.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_zscore.m'), ...
    fullfile(SpmDir, 'spm_eeg_artefact_zscorediff.m'), ...
    fullfile(SpmDir, 'spm_eeg_reduce_cva.m'), ...
    fullfile(SpmDir, 'spm_eeg_reduce_imagcsd.m'), ...
    fullfile(SpmDir, 'spm_eeg_reduce_pca.m'), ...
    fullfile(SpmDir, 'spm_eeg_reduce_pca_adapt.m'), ...
    fullfile(SpmDir, 'spm_eeg_regressors_chandata.m'), ...
    fullfile(SpmDir, 'spm_eeg_regressors_movement_ctf.m'), ...
    fullfile(SpmDir, 'spm_eeg_regressors_tfphase.m'), ...
    fullfile(SpmDir, 'spm_eeg_regressors_tfpower.m'), ...
    fullfile(SpmDir, 'spm_eeg_specest_hilbert.m'), ...
    fullfile(SpmDir, 'spm_eeg_specest_morlet.m'), ...
    fullfile(SpmDir, 'spm_eeg_specest_mtmfft.m'), ...
    fullfile(SpmDir, 'spm_eeg_specest_mtmspec.m'), ...
    fullfile(SpmDir, 'spm_eeg_inv_mesh.m'), ...
    fullfile(SpmDir, 'spm_eeg_inv_spatnorm.m'), ...
    fullfile(SpmDir, 'spm_eeg_load.m'), ...
    fullfile(SpmDir, 'spm_eeg_morlet.m'), ...
    fullfile(SpmDir, 'spm_eeg_specest_mtmconvol.m'), ...
    fullfile(SpmDir, 'spm_figure.m'), ...
    fullfile(SpmDir, 'spm_fileparts.m'), ...
    fullfile(SpmDir, 'spm_fmri_spm_ui.m'), ...
    fullfile(SpmDir, 'spm_fMRI_design.m'), ...
    fullfile(SpmDir, 'spm_get_bf.m'), ...
    fullfile(SpmDir, 'spm_get_defaults.m'), ...
    fullfile(SpmDir, 'spm_get_space.m'), ...
    fullfile(SpmDir, 'spm_global.m'), ...
    fullfile(SpmDir, 'spm_Gpdf.m'), ...
    fullfile(SpmDir, 'spm_hrf.m'), ...
    fullfile(SpmDir, 'spm_input.m'), ...
    fullfile(SpmDir, 'spm_inv.m'), ...
    fullfile(SpmDir, 'spm_jobman.m'), ...
    fullfile(SpmDir, 'spm_matrix.m'), ...
    fullfile(SpmDir, 'spm_mesh_area.m'), ...
    fullfile(SpmDir, 'spm_mesh_edges.m'), ...
    fullfile(SpmDir, 'spm_mesh_smooth.m'), ...
    fullfile(SpmDir, 'spm_mesh_resels.m'), ...
    fullfile(SpmDir, 'spm_get_ons.m'), ...
    fullfile(SpmDir, 'spm_orth.m'), ...
    fullfile(SpmDir, 'spm_plot_convergence.m'), ...
    fullfile(SpmDir, 'spm_read_vols.m'), ...
    fullfile(SpmDir, 'spm_sample_vol.m'), ...
    fullfile(SpmDir, 'spm_select.m'), ...
    fullfile(SpmDir, 'spm_slice_vol.m'), ...
    fullfile(SpmDir, 'spm_sqrtm.m'), ...
    fullfile(SpmDir, 'spm_str_manip.m'), ...
    fullfile(SpmDir, 'spm_svd.m'), ...
    fullfile(SpmDir, 'spm_swarp.m'), ...
    fullfile(SpmDir, 'spm_type.m'), ...
    fullfile(SpmDir, 'spm_spm.m'), ...
    fullfile(SpmDir, 'spm_surf.m'), ...
    fullfile(SpmDir, 'spm_u.m'), ...
    fullfile(SpmDir, 'spm_uc.m'), ...
    fullfile(SpmDir, 'spm_uc_Bonf.m'), ...
    fullfile(SpmDir, 'spm_vol.m'), ...
    fullfile(SpmDir, 'spm_Volterra.m'), ...
    fullfile(SpmDir, 'spm_write_vol.m'), ...
    fullfile(SpmDir, 'config', 'spm_cfg.m'), ...
    fullfile(SpmDir, 'config', 'spm_cfg_coreg.m'), ...
    fullfile(SpmDir, 'config', 'spm_cfg_norm.m'), ...
    fullfile(SpmDir, 'config', 'spm_cfg_preproc8.m'), ...
    fullfile(SpmDir, 'config', 'spm_cfg_realign.m'), ...
    fullfile(SpmDir, 'config', 'spm_cfg_realignunwarp.m'), ...
    fullfile(SpmDir, 'config', 'spm_cfg_st.m'), ...
    fullfile(SpmDir, 'config', 'spm_run_st.m'), ...
    fullfile(SpmDir, 'config', 'spm_run_realign.m'), ...
    fullfile(SpmDir, 'config', 'spm_run_realignunwarp.m'), ...
    fullfile(SpmDir, 'config', 'spm_run_coreg.m'), ...
    fullfile(SpmDir, 'matlabbatch', 'cfg_util.m'), ...
    fullfile(SpmDir, 'matlabbatch', 'cfg_util.m'), ...
    fullfile(SpmDir, 'toolbox', 'DAiSS', 'tbx_cfg_bf.m'), ...
    fullfile(SpmDir, 'toolbox', 'DAiSS', 'bf_data.m'), ...
    fullfile(SpmDir, 'toolbox', 'DAiSS', 'bf_copy.m'), ...
    fullfile(SpmDir, 'toolbox', 'DAiSS', 'bf_group.m'), ...
    fullfile(SpmDir, 'toolbox', 'DAiSS', 'bf_group_batch.m'), ...
    fullfile(SpmDir, 'toolbox', 'DAiSS', 'bf_sources.m'), ...
    fullfile(SpmDir, 'toolbox', 'DAiSS', 'bf_std_fields.m'), ...
    fullfile(SpmDir, 'toolbox', 'DARTEL', 'tbx_cfg_dartel.m'), ...
    fullfile(SpmDir, 'toolbox', 'FieldMap', 'tbx_cfg_fieldmap.m'), ...
    fullfile(SpmDir, 'toolbox', 'Longitudinal', 'tbx_cfg_longitudinal.m'), ...
    fullfile(SpmDir, 'toolbox', 'OldNorm', 'spm_cfg_normalise.m'), ...
    fullfile(SpmDir, 'toolbox', 'OldSeg', 'spm_cfg_preproc.m'), ...
    fullfile(SpmDir, 'toolbox', 'SRender', 'tbx_cfg_render.m'), ...
    fullfile(SpmDir, 'toolbox', 'Shoot', 'tbx_cfg_shoot.m'), ...
};

% Extra data files
extraFiles = {...
    fullfile(SpmDir, 'spm_dicom_dict.txt'), ...
    fullfile(SpmDir, 'Contents.txt'), ...
    fullfile(SpmDir, 'Contents.m'), ...
    fullfile(SpmDir, 'EEGtemplates', 'fiducials.sfp'), ...
    fullfile(SpmDir, 'canonical', 'cortex_5124.surf.gii'), ...
    fullfile(SpmDir, 'canonical', 'cortex_8196.surf.gii'), ...
    fullfile(SpmDir, 'canonical', 'cortex_20484.surf.gii'), ...
    fullfile(SpmDir, 'canonical', 'iskull_2562.surf.gii'), ...
    fullfile(SpmDir, 'canonical', 'oskull_2562.surf.gii'), ...
    fullfile(SpmDir, 'canonical', 'scalp_2562.surf.gii'), ...
    fullfile(SpmDir, 'toolbox', 'OldSeg', 'csf.nii'), ...
    fullfile(SpmDir, 'toolbox', 'OldSeg', 'grey.nii'), ...
    fullfile(SpmDir, 'toolbox', 'OldSeg', 'white.nii'), ...
    fullfile(SpmDir, 'toolbox', 'OldNorm', 'T1.nii'), ...       % For ft_volumesegment
};

% Detect missing functions
iMissing = find(~cellfun(@(c)exist(c,'file'), needFunc));
if iMissing
    for i = 1:length(iMissing)
        disp(['SPMTRIP> ERROR: Missing function: ', needFunc{iMissing(i)}]);
    end
    error('Missing dependent functions.');
end


% ===== SET PATH =====
tDepend = tic;
% Path spmtrip
warning off
rmpath(genpath(OutputDir));
warning on
% Initalize FieldTrip
bst_plugin('Load', 'fieldtrip');
ft_defaults;
if ~exist('contains', 'builtin')
    addpath(fullfile(FieldTripDir, 'compat', 'matlablt2016b'));
end
if ~exist('isfolder', 'builtin')
    addpath(fullfile(FieldTripDir, 'compat', 'matlablt2017b'));
end
% Initalize SPM
addpath(SpmDir);
addpath(fullfile(SpmDir, 'config'));
addpath(fullfile(SpmDir, 'matlabbatch'));
addpath(fullfile(SpmDir, 'matlabbatch', 'cfg_basicio'));
addpath(fullfile(SpmDir, 'toolbox', 'FieldMap'));
addpath(fullfile(SpmDir, 'toolbox', 'DARTEL'));
addpath(fullfile(SpmDir, 'toolbox', 'Longitudinal'));
addpath(fullfile(SpmDir, 'toolbox', 'OldNorm'));
addpath(fullfile(SpmDir, 'toolbox', 'OldSeg'));
addpath(fullfile(SpmDir, 'toolbox', 'SRender'));
addpath(fullfile(SpmDir, 'toolbox', 'Shoot'));
% Empty destination folder
if isdir(OutputDir)
    rmdir(OutputDir, 's');
end
pause(0.2);
mkdir(OutputDir);


% ===== GET DEPENDENCIES =====
% Get all dependencies
disp('SPMTRIP> Building dependendy list...');
listDep = matlab.codetools.requiredFilesAndProducts(needFunc);

% Remove everything not coming from the SPM or FieldTrip folder
iExclude = find(cellfun(@(c)isempty(strfind(c,FieldTripDir)), listDep) & cellfun(@(c)isempty(strfind(c,SpmDir)), listDep));
listDep(iExclude) = [];
% Remove all the classes
iClass = find(~cellfun(@(c)isempty(strfind(c, '@')), listDep));
listDep(iClass) = [];
% Remove all the files from external/signal (already available from the signal processing toolbox)
iSignal = find(~cellfun(@(c)isempty(strfind(c, ['external' filesep 'signal'])), listDep));
listDep(iSignal) = [];
% Add all the 64bit versions of all the included mex-files
iMex = find(~cellfun(@(c)isempty(strfind(c, '.mexw64')), listDep));
for i = 1:length(iMex)
    for ext = {'.mexa64', '.mexmaci64'}
        extFile = strrep(listDep{iMex(i)}, '.mexw64', ext{1});
        if exist(extFile, 'file') && ~ismember(extFile, listDep)
            listDep{end+1} = extFile;
        end
    end
end
% Add extra data files
listDep = {listDep{:}, extraFiles{:}};
% Make sure the list contains unique files
listDep = unique(listDep);


% ===== COPY FILES =====
disp('SPMTRIP> Copying files...');
% Copy the FieldTrip class folders entirely
for className = {'@config'}
    copydir(fullfile(FieldTripDir, className{1}), fullfile(OutputDir, className{1}));
end
% Copy the SPM class folders entirely
for className = {'@file_array', '@gifti', '@meeg', '@nifti', '@xmltree'}
    copydir(fullfile(SpmDir, className{1}), fullfile(OutputDir, className{1}));
end
% Copy SPM matlabbatch
copydir(fullfile(SpmDir, 'config'), fullfile(OutputDir, 'config'));
copydir(fullfile(SpmDir, 'matlabbatch'), fullfile(OutputDir, 'matlabbatch'));
copydir(fullfile(SpmDir, 'toolbox', 'DAiSS'), fullfile(OutputDir, 'toolbox', 'DAiSS'));
copydir(fullfile(SpmDir, 'toolbox', 'TSSS'), fullfile(OutputDir, 'toolbox', 'TSSS'));
% Copy all the dependency files
for i = 1:length(listDep)
    % If file not found: ignore
    if ~file_exist(listDep{i})
        disp(['SPMTRIP> File not found: ' listDep{i}]);
        continue;
    end
    % If file shadows a Matlab builtin function: skip
    [fPath, fBase, fExt] = fileparts(listDep{i});
    if exist(fBase, 'builtin')
        disp(['SPMTRIP> Removed (Matlab builtin): ' listDep{i}]);
        continue;
    end
    % Get source subdirectory
    srcSubdir = strrep(fPath, FieldTripDir, '');
    srcSubdir = strrep(srcSubdir, SpmDir, '');
    if ~isempty(srcSubdir)
        destDir = fullfile(OutputDir, srcSubdir(2:end));
    else
        destDir = OutputDir;
    end
    if ~isdir(destDir)
        mkdir(destDir);
        if isempty(strfind(listDep{i}, 'private'))
            disp(['Created: ' destDir]);
        end
    end
    % Copy file to include folder
    copyfile(listDep{i}, destDir);
    % Replace references to TPM.nii with Brainstorm's version
    if ismember(fBase, {'ft_volumebiascorrect', 'ft_volumenormalise', 'ft_volumesegment', 'ft_convert_coordsys', ...
            'spm_cfg_norm', 'spm_cfg_preproc8', 'spm_cfg_preproc8', 'spm_cfg_tissue_volumes', 'spm_rewrite_job', ...
            'spm_deformations', 'spm_eeg_inv_spatnorm', 'spm_get_matdim', 'spm_dartel_norm_fun', 'spm_klaff', 'spm_shoot_norm'})
        % Read file
        ScriptFile = fullfile(destDir, [fBase, '.m']);
        fid = fopen(ScriptFile, 'rt');
        txtScript = fread(fid, [1, Inf], '*char');
        fclose(fid);
        % Replace references to TPM.nii
        txtScript = strrep(txtScript, 'spm(''dir''),''tpm'',''TPM.nii''', 'bst_get(''BrainstormUserDir''), ''defaults'', ''spm'', ''TPM.nii''');
        txtScript = strrep(txtScript, 'spm(''Dir''),''tpm'',''TPM.nii''', 'bst_get(''BrainstormUserDir''), ''defaults'', ''spm'', ''TPM.nii''');
        txtScript = strrep(txtScript, 'spm(''dir''),''tpm'',''TPM.nii,''', 'bst_get(''BrainstormUserDir''), ''defaults'', ''spm'', ''TPM.nii,''');
        txtScript = strrep(txtScript, 'spm(''dir''), ''tpm'', ''TPM.nii''', 'bst_get(''BrainstormUserDir''), ''defaults'', ''spm'', ''TPM.nii''');
        % Only for fieldtrip: consider it is not deployed
        if strcmpi(fBase(1:3), 'ft_')
            txtScript = strrep(txtScript, 'isdeployed', '0');
        end
        % Save modified script
        fid = fopen(ScriptFile, 'wt');
        fwrite(fid, txtScript);
        fclose(fid);
    end
end

% Print elapsed time
stopTime = toc(tDepend);
if (stopTime > 60)
    disp(sprintf('SPMTRIP> Done in %dmin\n', round(stopTime/60)));
else
    fprintf('SPMTRIP> Done in %ds\n\n', round(stopTime));
end
end


%% ===== COPY =====
function copydir(src, dest)
    if ispc
        system(['xcopy "', src, '" "', dest, '" /s /e /y /q /i']);
    else
        system(['cp -rf "', src, '" "', dest, '"']);
    end
end


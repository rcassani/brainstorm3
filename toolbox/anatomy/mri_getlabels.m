function [Labels, AtlasName] = mri_getlabels(MriFile, sMri)
% MRI_GETLABELS: Get labels associated with a volume atlas (based on the MRI or the atlas name)
% 
% USAGE:  Labels = mri_getlabels(MriFile)       : Get labels based on filename (look for .txt file next to it, or use standard filenames)
%         Labels = mri_getlabels(MriFile, sMri) : Keep only the labels available in the sMRI structure
%         Labels = mri_getlabels(AtlasName)     : Get labels based on atlas name {'aseg', 'marsatlas'}
%
% INPUT:
%    - MriFile   : Full path to the volume atlas (eg. '/path/to/aseg.mgz')
%    - AtlasName : Name of the atlas: {'aseg', 'marsatlas'}
% 
% OUTPUT:
%    - Labels : Cell-array {nLabels x 3}
%               Labels{i,1} = integer, label in the atlas volume (eg. 18)
%               Labels{i,2} = string, human-readable label (eg. 'Amygdala L')
%               Labels{i,3} = color, as a [1x3] double
%
% REFERECES:
%    - https://www.lead-dbs.org/helpsupport/knowledge-base/atlasesresources/cortical-atlas-parcellations-mni-space/
%    - https://www.lead-dbs.org/helpsupport/knowledge-base/atlasesresources/atlases/

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2020 University of Southern California & McGill University
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
% Authors: Francois Tadel, 2020-2021

% Parse inputs
if (nargin < 2) || isempty(sMri)
    sMri = [];
end
% Initialize returned values
Labels = [];
AtlasName = [];
maxNameLength = 16;

% If the input is a filename
if (any(MriFile == '.') || (length(MriFile) > maxNameLength)) && file_exist(MriFile)
    % Get file name
    [fPath, fBase, fExt] = bst_fileparts(MriFile);
    fBase = strrep(fBase, '.nii', '');
    % Try to get a side .csv with the labels
    LabelsFile = bst_fullfile(fPath, [fBase, '.csv']);
    if file_exist(LabelsFile)
        Labels = in_tsv(LabelsFile, {'ROIid','ROIname','ROIcolor'}, 0, ';');
        if any(cellfun(@isempty, Labels(:)))
            disp('BST> Error: Missing columns is CSV file: ROIid, ROIname or ROIcolor.');
            Labels = [];
        else
            Labels(:,1) = cellfun(@str2double,  Labels(:,1), 'UniformOutput', 0);
            Labels(:,3) = cellfun(@str2num,  Labels(:,3), 'UniformOutput', 0);
        end
    end
    % If labels were read: use the filename as the atlas name
    fBase = lower(fBase);
    if ~isempty(Labels)
        AtlasName = fBase;
    % Standard atlases (FreeSurfer/ASEG, BrainSuite/SVREG)
    elseif ~isempty(strfind(fBase, 'aseg')) || ~isempty(strfind(fBase, 'aparc'))  % aseg.mgz
        AtlasName = 'aseg';
    elseif ~isempty(strfind(fBase, '.svreg.label.'))   % *.svreg.label.nii.gz
        AtlasName = 'svreg';
    elseif ~isempty(strfind(fBase, '.svreg.label.'))   % *.svreg.label.nii.gz
        AtlasName = 'svreg';
    end
end
% If the name of the altas is in the file comment
if isempty(AtlasName) && ~isempty(sMri) && ~isempty(sMri.Comment)
    if ~isempty(strfind(sMri.Comment, 'aseg'))
        AtlasName = 'aseg';
    elseif ~isempty(strfind(sMri.Comment, 'svreg'))
        AtlasName = 'svreg';
    elseif ~isempty(strfind(sMri.Comment, 'tissues'))
        AtlasName = 'tissues5';
    end
% Atlas name is given in input
elseif ~any(MriFile == '.') && (length(MriFile) <= maxNameLength)
    AtlasName = MriFile;
end
% No atlas identified
if isempty(AtlasName)
	return;
end

% Switch by atlas name
if isempty(Labels)
    switch lower(AtlasName)
        case 'aseg'          % FreeSurfer ASEG + Desikan-Killiany (2006) + Destrieux (2010)
            Labels = mri_getlabels_aseg();
        case 'marsatlas'     % BrainVISA MarsAtlas (Auzias 2006)
            Labels = mri_getlabels_marsatlas();
        case 'svreg'         % BrainSuite SVREG (Brainsuite1, USCBrain)
            Labels = mri_getlabels_svreg();
        case 'tissues5'    % Basic head tissues
            Labels = {...
                    0, 'Background',    [  0,   0,   0]; ...
                    1, 'White',         [220, 220, 220]; ...
                    2, 'Gray',          [130, 130, 130]; ...
                    3, 'CSF',           [ 44, 152, 254]; ...
                    4, 'Skull',         [255, 255, 255]; ...
                    5, 'Scalp',         [255, 205, 184]};               
        case 'aseg3'   % Old FreeSurfer labels
            Labels = {...
                0,  'Unknown'; ...
                6,  'White L'; ...
                9,  'Cortex L'; ...
               21,  'Cerebellum white L'; ...
               24,  'Cerebellum L'; ...
               30,  'Thalamus L'; ...
               36,  'Putamen L'; ...
               39,  'Pallidum L'; ...
               48,  'Brainstem'; ...
               51,  'Hippocampus L'; ...
              123,  'White R'; ...
              126,  'Cortex R'; ...
              138,  'Cerebellum white R'; ...
              141,  'Cerebellum R'; ...
              147,  'Thalamus R'; ...
              153,  'Putamen R'; ...
              156,  'Pallidum R'; ...
              159,  'Hippocampus R'; ...
            };
    end
end


%% ===== FIX LABELS LIST =====
if ~isempty(sMri) && ~isempty(Labels)
    % Add background if missing
    if ~ismember(0, [Labels{:,1}])
        Labels = [{0, 'Background', [0 0 0]}; Labels];
    end
    % Get labels available in the MRI volume
    toKeep = unique(sMri.Cube(:));
    % Find the corresponding indices in the Labels array
    isLabels = ismember([Labels{:,1}], toKeep);
    % Keep only these labels
    Labels = Labels(isLabels, :);
    % Check for undocumented labels: console warning and display in white (255,255,255)
    iMissing = find(~ismember(toKeep, [Labels{:,1}]));
    if ~isempty(iMissing)
        disp(['BST> Warning: Labels missing in atlas:' sprintf(' %d', toKeep(iMissing))]);
        Labels = cat(1, Labels, cat(2, num2cell(toKeep(iMissing)), repmat({'Unknown', [255 255 255]}, length(iMissing), 1)));
    end
end


function sSubject = db_surface_default( iSubject, SurfaceType, iSurface, isUpdate )
% DB_SURFACE_DEFAULT: Set a surface as default of its category for a given subject.
%
% USAGE:  db_surface_default( iSubject, SurfaceType, iSurface, isUpdate=1 );

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
% Authors: Francois Tadel, 2008-2011
%          Raymundo Cassani, 2021-2022

% Get protocol description
ProtocolInfo = bst_get('ProtocolInfo');
sqlConn = sql_connect();
sSubject = db_get(sqlConn, 'Subject', iSubject);
% Lock Subject
LockId = lock_acquire(sqlConn, mfilename, sSubject.Id);

% ===== GET DEFAULT SURFACE =====
% By default: update tree
if (nargin < 4) || isempty(isUpdate)
    isUpdate = 1;
end
% If default surface is not defined yet: find one
if (nargin < 3) || isempty(iSurface)
    iSurface = [];
    % Try to find the default surface in the brainstormsubject.mat file
    subjMat = load(bst_fullfile(ProtocolInfo.SUBJECTS, sSubject.FileName));
    % Default surface name
    if isfield(subjMat, SurfaceType)
        defSurfFile = subjMat.(SurfaceType);
    else
        defSurfFile = [];
    end
    % Try to find the default anatomy / surface file
    if ~isempty(defSurfFile)
        sAnatFile = db_get(sqlConn, 'AnatomyFile', defSurfFile);
        iSurface = sAnatFile.Id;
    end
    % If no default file, or it was not found: Use the first one
    if isempty(iSurface)
        if strcmpi(SurfaceType, 'Anatomy')
            % == VOLUME IMAGE ==
            sAnatFiles = db_get(sqlConn, 'AnatomyFilesWithSubject', sSubject.Id, 'volume', 'Id', 'Image');
        else
            % == SURFACE ==
            sAnatFiles = db_get(sqlConn, 'AnatomyFilesWithSubject', sSubject.Id, 'surface', 'Id', SurfaceType);
        end
        if ~isempty(sAnatFiles)
            iSurface = sAnatFiles(1).Id;
        end
    end
end

% Get new default surface
if ~isempty(iSurface)
    sAnatFile = db_get(sqlConn, 'AnatomyFile', iSurface, 'FileName');
    DefaultFile = sAnatFile.FileName;
else
    DefaultFile = '';
end
% Make filename linux-style
DefaultFile = file_win2unix(DefaultFile);

% ===== UPDATE DATABASE =====
% Save in database selected file
db_set(sqlConn, 'Subject', struct(['i' SurfaceType], iSurface), sSubject.Id);

% Unlock Subject
lock_release(sqlConn, LockId);

% Update SubjectFile
matUpdate.(SurfaceType) = DefaultFile;
bst_save(bst_fullfile(ProtocolInfo.SUBJECTS, sSubject.FileName), matUpdate, 'v7', 1);

% ===== UPDATE TREE =====
if isUpdate
    % Try to find the tree node associated to this surface
    if ~isempty(iSurface)
        surfNode = panel_protocols('SelectNode', [], lower(SurfaceType), sSubject.Id, iSurface );
        % If node was found in this display
        if ~isempty(surfNode)
            % Select node (and unselect all the others)
            panel_protocols('MarkUniqueNode', surfNode);
        end
    else
        panel_protocols('UpdateNode', 'Subject', sSubject.Id);
    end
end

% ===== REMOVE INTERPOLATIONS =====
% If the default MRI changes, all the surface-MRI interpolations saved in the surface files must be updated
if strcmpi(SurfaceType, 'Anatomy')
    % Surfaces for Subject
    sAnatFiles = db_get(sqlConn, 'AnatomyFilesWithSubject', sSubject.Id, 'surface', 'FileName');
    for i = 1:length(sAnatFiles)
        % Load surface
        TessFile = file_fullpath(sAnatFiles(i).FileName);
        TessMat = in_tess_bst(TessFile, 0);
        % If there is an interpolation
        if isfield(TessMat, 'tess2mri_interp') && ~isempty(TessMat.tess2mri_interp)
            % Remove interpolation
            TessMat.tess2mri_interp = [];
            % Save cleaned surface file
            bst_save(TessFile, TessMat, 'v7');
            % Unload from memory
            bst_memory('UnloadSurface', TessFile, 1);
        end
    end
end
sql_close(sqlConn);




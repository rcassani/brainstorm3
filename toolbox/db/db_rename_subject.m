function db_rename_subject( oldName, newName, isRefresh )
% DB_RENAME_SUBJECT: Rename a subject in the Brainstorm database.
%
% USAGE:  db_rename_subject( oldPath, newPath, isRefresh )
%         db_rename_subject( oldPath, newPath )

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
% Authors: Francois Tadel, 2011

%% ===== INITIALIZATION =====
% Parse inputs
if (nargin < 3) || isempty(isRefresh)
    isRefresh = 1;
end
% Get protocol directories
ProtocolInfo = bst_get('ProtocolInfo');
% Get subject index
sSubject = db_get('Subject', oldName, 'Id');
if isempty(sSubject.Id)
    return;
end
% No modification
if strcmpi(oldName, newName)
    return;
end
% Progress bar
bst_progress('start', 'Rename subject', ['Rename: ' oldName ' => ' newName]);
% SUBJECTS: Check that old condition exists
if ~isdir(bst_fullfile(ProtocolInfo.SUBJECTS, oldName))
    bst_error(['Folder "anat/' oldName '" does not exists.'], 'Rename', 0);
    return;
end
% SUBJECTS: Check that new condition does not exist
if isdir(bst_fullfile(ProtocolInfo.SUBJECTS, newName))
    bst_error(['Folder "anat/' newName '" already exists.'], 'Rename', 0);
    return;
end
% STUDIES: Check that old condition exists
if ~isdir(bst_fullfile(ProtocolInfo.STUDIES, oldName))
    bst_error(['Folder "data/' oldName '" does not exists.'], 'Rename', 0);
    return;
end
% STUDIES: Check that new condition does not exist
if isdir(bst_fullfile(ProtocolInfo.STUDIES, newName))
    bst_error(['Folder "data/' newName '" already exists.'], 'Rename', 0);
    return;
end

%% ===== MOVE ANATOMY FOLDER =====
isOk = file_move(bst_fullfile(ProtocolInfo.SUBJECTS, oldName), bst_fullfile(ProtocolInfo.SUBJECTS, newName));
if ~isOk
    bst_error(['Could not rename anat/"' oldName '" to anat/"' newName '".'], 'Rename', 0);
    return;
end

%% ===== RENAME ALL THE CONDITIONS =====
dataDir = bst_fullfile(ProtocolInfo.STUDIES, oldName);
listDir = dir(dataDir);
for iDir = 1:length(listDir)
    % Skip non-study folders
    if ~listDir(iDir).isdir || (listDir(iDir).name(1) == '.') || isempty(dir(bst_fullfile(dataDir, listDir(iDir).name, 'brainstormstudy*.mat')))
        continue;
    end
    % Call the function to rename condition (DO NOT MOVE FILES)
    Condition = listDir(iDir).name;
    oldPath = bst_fullfile(oldName, Condition);
    newPath = bst_fullfile(newName, Condition);
    db_rename_condition(oldPath, newPath, 0);
end

%% ===== MOVE DATA FOLDER =====
isOk = file_move(bst_fullfile(ProtocolInfo.STUDIES, oldName), bst_fullfile(ProtocolInfo.STUDIES, newName));
if ~isOk
    bst_error(['Error: Could not rename data/"' oldName '" to data/"' newName '".'], 'Rename', 0);
    return;
end


%% ===== UPDATE DATABASE =====
% Update subject definition
sqlConn = sql_connect();
sSubject = db_get(sqlConn, 'Subject', oldName, {'Id', 'Name', 'FileName'}, 'raw');
sSubject.Name = newName;
% Update subject filename
[fPath, fBase, fExt] = bst_fileparts(sSubject.FileName);
sSubject.FileName = bst_fullfile(newName, [fBase, fExt]);
db_set(sqlConn, 'Subject', sSubject, sSubject.Id);
% Update anatomy and surfaces
sAnatFiles = db_get(sqlConn, 'AnatomyFilesWithSubject', sSubject.Id, {'Id', 'FileName'});
for i = 1 : length(sAnatFiles)
    [fPath, fBase, fExt] = bst_fileparts(sAnatFiles(i).FileName);
    sAnatFiles(i).FileName = bst_fullfile(newName, [fBase, fExt]);
    db_set(sqlConn, 'AnatomyFile', sAnatFiles(i), sAnatFiles(i).Id);
end
sql_close(sqlConn);

% Close progress bar
bst_progress('stop');
% Update tree display
if isRefresh
    panel_protocols('UpdateTree');
end



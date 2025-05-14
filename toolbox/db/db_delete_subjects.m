function errFolders = db_delete_subjects( iSubjects )
% DB_DELETE_SUBJECTS: Delete some subjects from the brainstorm database.
%
% USAGE:  errFolders = db_delete_subjects( iSubjects )
%
% INPUT:
%    - iSubjects : indices of the subejcts to delete
% 
% OUTPUT:
%    - errFolders : Cell-array with full paths to folders that could not be deleted

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
% Authors: Francois Tadel, 2012-2022
%          Raymundo Cassani, 2022

sqlConn = sql_connect();
ProtocolInfo = bst_get('ProtocolInfo');
errFolders = {};
save_db = 0;

% Get @default_subject Id
sSubjectDef = db_get(sqlConn, 'Subject', bst_get('DirDefaultSubject'), 'Id');

% Cannot delete default subject
iInvalid = find(iSubjects == sSubjectDef.Id);
if ~isempty(iInvalid)
    disp('DELETE> Cannot delete default subject.');
    iSubjects(iInvalid) = [];
end

% For each subject
for i = 1:length(iSubjects)
    sSubject = db_get(sqlConn, 'Subject', iSubjects(i), {'Id','FileName'}, 'raw');
    % === DELETE STUDIES ===
    % Find all the studies that are associated with the current brainstormsubject file
    sStudies = db_get(sqlConn, 'StudiesFromSubject', sSubject.Id, {'Id','FileName'}, '@intra', '@default_study');
    if ~isempty(sStudies)
        % Delete study folders and from database
        errFolders = cat(2, errFolders, db_delete_studies([sStudies.Id]));
        % Delete the studies folder for the subject
        subjDataDir = bst_fullfile(ProtocolInfo.STUDIES, bst_fileparts(bst_fileparts(sStudies(1).FileName)));
        if (file_delete(subjDataDir, 1, 1) ~= 1)
            errFolders{end+1} = subjDataDir;
            return;
        end
    end    
    % === DELETE SUBJECT ===
    % Remove subject's directory
    subjAnatDir = bst_fullfile(ProtocolInfo.SUBJECTS, bst_fileparts(sSubject.FileName));
    if (file_delete(subjAnatDir, 1, 1) ~= 1)
        errFolders{end+1} = subjAnatDir;
        return;
    end
    % Delete from DB, Subject, and their AnatomyFiles, Studies and FunctionalFiles through cascade
    db_set(sqlConn, 'Subject', 'Delete', sSubject.Id);
    save_db = 1;
end
% If something was deleted, save database
if save_db
    % Update tree
    panel_protocols('UpdateTree');
    % Save database
    db_save();
end


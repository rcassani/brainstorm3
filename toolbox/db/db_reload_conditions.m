function iNewStudies = db_reload_conditions(iSubjects)
% DB_RELOAD_CONDITIONS: Reload all the conditions for a subject
%
% USAGE:  db_reload_conditions( iSubjects );
%
% INPUT:  iSubjects: array of subjects indices to reload in protocol studies array

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
% Authors: Francois Tadel, 2009-2013
%          Raymundo Cassani, 2022-2023

% Parse inputs
if isempty(iSubjects)
    return
end
iNewStudies = [];
% Get protocol information
ProtocolInfo = bst_get('ProtocolInfo');

% If no progressbar is visible: create one
isProgressBar = ~bst_progress('isVisible');
if isProgressBar
    bst_progress('start', 'Reload subject', 'Reloading datasets...', 0, 100 * length(iSubjects));
end

sqlConn = sql_connect();
% Process all the subjects
for i = 1:length(iSubjects)
    % Get subject
    sSubject = db_get(sqlConn, 'Subject', iSubjects(i), '*', 1);
    % Get all the dependent studies at the moment
    sOldStudies = db_get(sqlConn, 'StudiesFromSubject', sSubject.Id, {'Id', 'FileName'}, '@inter', '@intra', '@default_study');
    % Get subject directory for studies
    subjectSubDir = bst_fileparts(sSubject.FileName);
    % Protocol error
    if ~file_exist(ProtocolInfo.STUDIES)
        bst_error(['Data folder has been deleted or moved:' 10 ProtocolInfo.STUDIES], 'Reload studies', 0);
        return
    % Check the existance of the study's directory
    elseif ~file_exist(bst_fullfile(ProtocolInfo.STUDIES, subjectSubDir)) || ...
       ~file_exist(bst_fullfile(ProtocolInfo.STUDIES, subjectSubDir, bst_get('DirDefaultStudy'))) || ...
       ~file_exist(bst_fullfile(ProtocolInfo.STUDIES, subjectSubDir, bst_get('DirAnalysisIntra')))
        db_fix_protocol();
        bst_progress('stop');
        return
    end
    
    % Read all the studies in the subject directory
    sReadStudies = db_parse_study(ProtocolInfo.STUDIES, subjectSubDir, 100);
    % Place studies in protocol DataBase
    for ix = 1 : length(sReadStudies)
        % Update Studies and their Functional Files
        [~, ~, ib] = intersect({sOldStudies.FileName},{sReadStudies.FileName});
        for iy = 1 : length(ib)
            db_set(sqlConn, 'ParsedStudy', sReadStudies(ib(iy)), sOldStudies(ib(iy)).Id);
        end
        % Studies to Insert or Delete
        [~, ia, ib] = setxor({sOldStudies.FileName},{sReadStudies.FileName});
        ia = sort(ia);
        ib = sort(ib);
        % Delete Studies (and their Functional Files) present in DB but not in sStudies
        for iy = 1 : length(ia)
            db_set(sqlConn, 'Study', 'Delete', sOldStudies(ia(iy)).Id);
        end
        % Insert Studies (and their Functional Files) present in sStudies but not in DB
        for iy = 1 : length(ib)
            db_set(sqlConn, 'ParsedStudy', sReadStudies(ib(iy)));
        end
    end
    % Update links
    db_links(sqlConn, 'Subject', iSubjects(i));
end
sql_close(sqlConn);

% Save database to disk
db_save();
% Update tree display
panel_protocols('UpdateTree');
% Select and open subject node
panel_protocols('SelectNode', [], 'studysubject', -1, iSubjects(1) );
% Close progress bar
if isProgressBar
    bst_progress('stop');
end



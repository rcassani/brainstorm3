function iStudies = db_add_condition(SubjectName, ConditionName, isRefresh, DateOfStudy)
% DB_ADD_CONDITION: Add a subdirectory with a default study file to one or all subjects (current protocol)
%
% USAGE:  iStudies = db_add_condition(SubjectName, ConditionName, isRefresh)
%         iStudies = db_add_condition(SubjectName, ConditionName)  : Refresh display by default
%         iStudies = db_add_condition(SubjectName)                 : Ask ConditionName to the user
%         iStudies = db_add_condition(iSubject, ...)               : Indicated subject's index instead of name
% INPUT: 
%     - SubjectName   : String, name of the target subject. 
%                       Use '*' to specify all the subjects
%     - ConditionName : String, name of the condition to add.
%                       If empty or ommitted, asked to the user
%     - isRefresh     : If 0, tree is not refreshed after adding condition
%                       If 1, tree is refreshed
%     - DateOfStudy   : String 'dd-MMM-yyyy', force Study entries created in the database to use this acquisition date
% OUTPUT: 
%     - iStudies : Indices of the studies that were created. 
%                  Returns [] if an error occurs

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
% Authors: Francois Tadel, 2008-2018


%% ===== PARSE INPUTS =====
if (nargin < 4) || isempty(DateOfStudy)
    DateOfStudy = date;
end
if (nargin < 3) || isempty(isRefresh)
    isRefresh = 1;
end
if (nargin < 2)
    ConditionName = java_dialog('input', 'New folder name: ', 'Add folder', [], 'NewCondition');
    if isempty(ConditionName)
        return
    end
end
if (nargin < 1) || isempty(SubjectName)
    error('You must define the first argument "SubjectName".');
end
% Normalize names (in order to create a directory out of it)
ConditionName = file_standardize(ConditionName, 1);
% Get protocol subjects database
ProtocolInfo     = bst_get('ProtocolInfo');
% Returned value
iStudies = [];
isModified = 0;


sqlConn = sql_connect();
%% ===== GET SUBJECTS =====
subjectFields = {'Id', 'FileName', 'Name'};
% If SubjectDir starts with '*' : get all subjects except @default_subject
if ischar(SubjectName) && (SubjectName(1) == '*')
    sSubjects = db_get(sqlConn, 'AllSubjects', subjectFields);
% Else: Look for subject
else
    sSubjects = db_get(sqlConn, 'Subject', SubjectName, subjectFields, 'raw');
end
% No subject found
if isempty(sSubjects)
    bst_error('Invalid subject.', 'Add condition', 0);
    return;
end


%% ===== CREATE STUDIES =====
for ix = 1 : length(sSubjects)
    % Cannot add study to default anatomy
    if strcmp(sSubjects(ix).Name, bst_get('DirDefaultSubject'))
        error('Cannot add folders to the default anatomy.');
    end
    % Get conditions for subject
    sStudies = db_get(sqlConn, 'StudiesFromSubject', sSubjects(ix).Id, {'Id', 'Condition'}, '@intra', '@default_study');
    
    % If condition already exists for this subject: return it
    iExistStudy = find(strcmpi({sStudies.Condition}, ConditionName));
    if ~isempty(iExistStudy)
        disp(['BST> Condition "' ConditionName '" already exists for subject "' sSubjects(ix).Name '".']);
        iStudies(end+1) = sStudies(iExistStudy).Id;
        continue
    end
    
    % === Create study file ===
    % Create structure
    StudyMat = db_template('studymat');
    StudyMat.Name = ConditionName;
    StudyMat.DateOfStudy = DateOfStudy;
    % Filename : STUDIES/dirSubject/ConditionName/brainstormstudy.mat
    StudyFile = bst_fullfile(bst_fileparts(sSubjects(ix).FileName), ConditionName, 'brainstormstudy.mat');
    StudyFileFull = bst_fullfile(ProtocolInfo.STUDIES, StudyFile);
    % Create folder
    if ~file_exist(bst_fileparts(StudyFileFull))
        mkdir(bst_fileparts(StudyFileFull));
    end
    % Save brainstormstudy.mat file
    bst_save(StudyFileFull, StudyMat, 'v7');

    % === Create Study db structure ===
    sNewStudy = db_template('Study');
    sNewStudy.Subject           = sSubjects(ix).Id;
    sNewStudy.Name              = StudyMat.Name;
    sNewStudy.FileName          = file_win2unix(StudyFile);
    sNewStudy.DateOfStudy       = StudyMat.DateOfStudy;
    sNewStudy.Condition         = ConditionName;
    % Add study to Brainstorm database
    iNewStudy = db_set(sqlConn, 'Study', sNewStudy);
    % Add to returned indices list
    iStudies = [iStudies iNewStudy];
    isModified = 1;
end
sql_close(sqlConn);

%% ===== REFRESH DISPLAY =====
if isModified
    % Set default study to the last added study
    ProtocolInfo.iStudy = iStudies(end);
    bst_set('ProtocolInfo', ProtocolInfo);
    % GUI update
    if isRefresh
        % Redraw tree
        panel_protocols('UpdateTree');
    end
    % Save database
    db_save();
end


end








function [sSubject, iSubject] = db_add_subject( varargin )
% DB_ADD_SUBJECT: Add a subject to data base.
%
% USAGE:                        db_add_subject(sSubject, iSubject)
%        [sSubject, iSubject] = db_add_subject(sSubject)
%        [sSubject, iSubject] = db_add_subject(SubjectName)
%        [sSubject, iSubject] = db_add_subject(SubjectName, iSubject)
%        [sSubject, iSubject] = db_add_subject(SubjectName, iSubject, UseDefaultAnat, UseDefaultChannel)
%
% INPUT:
%     - SubjectName : Name of the subject
%     - sSubject    : subject structure
%     - iSubject    : Indice of the subject in the ProtocolSubjects.Subject array
%                     Set to [] to create a new subject
%     - UseDefaultAnat, UseDefaultChannel : values for new subject
% OUTPUT:
%     - sSubject : Subject structure (set to [] if an error occurs)
%     - iSubject : Subject index in current protocol

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

% Get protocol description
ProtocolInfo = bst_get('ProtocolInfo');

%% ===== PARSE INPUTS =====
% CALL: db_add_subject( sSubject )
if isstruct(varargin{1})
    sSubject = varargin{1};
% CALL: db_add_subject( SubjectName )
elseif ischar(varargin{1})
    % Get subject name
    SubjectName = file_standardize(varargin{1});
    % Create a new empty subject
    sSubject = db_template('Subject');
    sSubject.Name              = SubjectName;
    sSubject.FileName          = bst_fullfile(SubjectName, 'brainstormsubject.mat');
    sSubject.UseDefaultAnat    = ProtocolInfo.UseDefaultAnat;
    sSubject.UseDefaultChannel = ProtocolInfo.UseDefaultChannel;
else
    error('Invalid call to db_add_subject()');
end
% CALL: db_add_subject( ..., iSubject )
if (nargin < 2) || isempty(varargin{2})
    % New indice
    sSubject.Id = [];
else
    sSubject.Id = varargin{2};
end
% CALL: db_add_subject( ..., UseDefaultAnat, UseDefaultChannel )
if (nargin >= 3)
    sSubject.UseDefaultAnat = varargin{3};
end
if (nargin >= 4)
    sSubject.UseDefaultChannel = varargin{4};
end

%% ===== UPDATE DATABASE =====
sqlConn = sql_connect();

% Add or Update subject in database
if isempty(sSubject.Id)
    % Check the subject unicity
    if sql_query(sqlConn, 'EXIST', 'Subject', struct('Name', sSubject.Name))
        % A subject with the same Name is found : display an error box and return to 'Subject editor' window
        bst_error(sprintf('Subject "%s" already exists in protocol.', sSubject.Name), 'Subject editor', 0);
        sSubject = [];
        iSubject = [];
        sql_close(sqlConn);
        return
    end
    % Add subject to database
    iSubject = db_set(sqlConn, 'Subject', sSubject);
else
    % Update subject in database
    iSubject = db_set(sqlConn, 'Subject', sSubject, sSubject.Id);
end
% Get raw Subject from DB
sSubject = db_get(sqlConn, 'Subject', iSubject, '*', 'raw');
sql_close(sqlConn);

%% ===== SAVE SUBJECT FILE =====
SubjectMat = db_template('subjectmat');
SubjectMat.Comments          = sSubject.Comments;
SubjectMat.UseDefaultAnat    = sSubject.UseDefaultAnat;
SubjectMat.UseDefaultChannel = sSubject.UseDefaultChannel;
try
    fullFileName = bst_fullfile(ProtocolInfo.SUBJECTS, sSubject.FileName);
    % Create target directory
    if ~file_exist(bst_fileparts(fullFileName))
        mkdir(bst_fileparts(fullFileName));
    end
    % Save file
    bst_save(fullFileName, SubjectMat, 'v7');
catch
    bst_error(sprintf('Error : cannot save subject file "%s".', sSubject.Name), 'Subject editor');
    sSubject = [];
    iSubject = [];
    return
end

% Update node
panel_protocols('UpdateNode', 'Subject', iSubject);

% === Create extra system conditions ===
% Add conditions: analysis_intra and default_study
db_add_condition(sSubject.Name, bst_get('DirAnalysisIntra'), 0);
db_add_condition(sSubject.Name, bst_get('DirDefaultStudy'),  0);


function varargout = db_set(varargin)
% DB_SET: Set values in the protocol database from a Brainstorm structure
% This function is a newer API than bst_set
% 
% USAGE :
%    - db_set(contextName) or 
%    - db_set(sqlConn, contextName)
%
% ====== PROTOCOLS =====================================================================
%    - sProtocol = db_set('Protocol', sProtocol)    : Update current Protocol information
%    - sProtocol = db_set('Protocol', sProtocol, 1) : Insert current Protocol information
%
% ====== SUBJECTS ======================================================================
%    - db_set('ParsedSubject', sParsedSubject)           : Insert parsed subject, from db_parse_subject()
%    - db_set('ParsedSubject', sParsedSubject, iSubject) : Update parsed subject, from db_parse_subject()
%    - db_set('Subject', 'Delete')                       : Delete all Subjects
%    - db_set('Subject', 'Delete', SubjectId)            : Delete Subject by ID
%    - db_set('Subject', 'Delete', CondQuery)            : Delete Subject with Query
%    - db_set('Subject', sSubject)                       : Insert Subject
%    - db_set('Subject', sSubject, SubjectId)            : Update Subject by ID
%
% ====== ANATOMY FILES =================================================================
%    - db_set('AnatomyFile', 'Delete')                      : Delete all AnatomyFiles
%    - db_set('AnatomyFile', 'Delete', AnatomyFileId)       : Delete AnatomyFile by ID
%    - db_set('AnatomyFile', 'Delete', CondQuery)           : Delete AnatomyFile with Query
%    - db_set('AnatomyFile', sAnatomyFile)                  : Insert AnatomyFile
%    - db_set('AnatomyFile', sAnatomyFile, AnatomyFileId)   : Update AnatomyFile by ID
%    - db_set('AnatomyFilesWithSubject', 'Delete' , SubjectID)     : Delete all AnatomyFiles from SubjectID
%    - db_set('AnatomyFilesWithSubject', sAnatomyFiles, SubjectID) : Insert AnatomyFiles with SubjectID
%
% ====== STUDIES =======================================================================
%    - db_set('ParsedStudy', sParsedStudy)           : Insert parsed study, from db_parse_study()
%    - db_set('ParsedStudy', sParsedStudy, iStudy)   : Update parsed study, from db_parse_study()
%    - db_set('Study', 'Delete')                     : Delete all Studies
%    - db_set('Study', 'Delete', StudyId)            : Delete Study by ID
%    - db_set('Study', 'Delete', CondQuery)          : Delete Study with Query
%    - db_set('Study', sStudy)                       : Insert Study
%    - db_set('Study', sStudy, StudyId)              : Update Study by ID
%
% ====== FUNCTIONAL FILES ==============================================================
%    - db_set('FunctionalFile', 'Delete')                              : Delete all FunctionalFiles
%    - db_set('FunctionalFile', 'Delete', FunctionalFileId)            : Delete FunctionalFile by ID
%    - db_set('FunctionalFile', 'Delete', CondQuery)                   : Delete FunctionalFile with Query
%    - db_set('FunctionalFile', sFunctionalFile)                       : Insert FunctionalFile
%    - db_set('FunctionalFile', sFunctionalFile, FunctionalFileId)     : Update FunctionalFile by ID
%    - db_set('FunctionalFilesWithStudy', 'Delete' , StudyID)          : Delete All FunctionalFiles from StudyID
%    - db_set('FunctionalFilesWithStudy', sFunctionalFiles, StudyID)   : Insert FunctionalFiles with StudyID
%    - db_set('FunctionalFilesWithStudy', sFunctionalFiles)            : Update FunctionalFiles
%    - db_set('ParentCount', ParentId, modifier, count)                : Update NumChildren field in ParentFileID
%
% SEE ALSO db_get
%
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
% Authors: Martin Cousineau, 2020
%          Raymundo Cassani, 2021-2022

%% ==== PARSE INPUTS ====
if (nargin > 1) && isjava(varargin{1})
    sqlConn = varargin{1};
    varargin(1) = [];
    handleConn = 0;
elseif (nargin >= 1) && ischar(varargin{1}) 
    sqlConn = sql_connect();
    handleConn = 1;
else
    error(['Usage : db_set(contextName) ' 10 '        db_set(sqlConn, contextName)']);
end

try
contextName = varargin{1};
args = {};
if length(varargin) > 1
    args = varargin(2:end);
end
varargout = {};
   
% Set required context structure
switch contextName
%% ==== PROTOCOL =====
    % sProtocol = db_set('Protocol', Protocol, isInsert);
    case 'Protocol'
        action = 'UPDATE';
        if length(args) < 1
            error('Error in number of arguments')
        end
        sProtocol = args{1};
        if length(args) > 1
            if logical(args{2})
                action = 'INSERT';
            end
        end
        varargout{1} = sql_query(sqlConn, action, 'Protocol', sProtocol);


%% ==== PARSED SUBJECT ====
    % iSubject = db_set('ParsedSubject', sParsedSubject)
    % iSubject = db_set('ParsedSubject', sParsedSubject, iSubject)
    case 'ParsedSubject'
        sParsedSubject = args{1};  % sParsedSubject is old sSubject structure (with Anatomy and Surface fields).
                                   % BUT default iXxxx fields are relative paths
        iSubject = [];
        if length(args) > 1
            iSubject = args{2};
        end

        % Default Anatomy and Surface files
        categories = strcat('i', {'Anatomy', 'Scalp', 'Cortex', 'InnerSkull', 'OuterSkull', 'Fibers', 'FEM'});
        fieldValPairs = [categories; cell(1,length(categories))];
        sDefSurfFiles = struct(fieldValPairs{:});
        for iCat = 1 : length(categories)
            sDefSurfFiles.(categories{iCat}) = sParsedSubject.(categories{iCat});
            sParsedSubject.(categories{iCat}) = [];
        end
        % Get AnatomyFiles
        sAnatFiles = [db_convert_anatomyfile(sParsedSubject.Anatomy, 'volume'), ...
                      db_convert_anatomyfile(sParsedSubject.Surface, 'surface')];
        
        % Check if Subject with index iSubject exists
        sSubjectOld = db_get(sqlConn, 'Subject', iSubject, 'Id');
        if isempty(sSubjectOld)
            % Insert Subject
            iSubject = db_set(sqlConn, 'Subject', sParsedSubject);
        else
            % Update Subject
            iSubject = db_set(sqlConn, 'Subject', sParsedSubject, sSubjectOld.Id);
        end
        % Delete current sAnatFiles in iSubject
        db_set(sqlConn, 'AnatomyFilesWithSubject', 'Delete', iSubject);
        if ~isempty(sAnatFiles)
            % Insert sAnatFiles in iSubject
            db_set(sqlConn, 'AnatomyFilesWithSubject', sAnatFiles, iSubject);
        end
        % Update indices in sSubject for default Anatomy and Surface files
        sDefSurfIds = struct(fieldValPairs{:});
        for iCat = 1 : length(categories)
            if ~isempty(sDefSurfFiles.(categories{iCat}))
                sAnatFile = db_get(sqlConn, 'AnatomyFile', sDefSurfFiles.(categories{iCat}), 'Id');
                if ~isempty(sAnatFile)
                    sDefSurfIds.(categories{iCat}) = sAnatFile.Id;
                end
            end
        end
        varargout{1} = db_set(sqlConn, 'Subject', sDefSurfIds, iSubject);


%% ==== PARSED STUDY ====
    % iStudy = db_set('ParsedStudy', sParsedStudy)
    % iStudy = db_set('ParsedStudy', sParsedStudy, iStudy)
    case 'ParsedStudy'
        sParsedStudy = args{1};  % sParsedStudy is old sStudy structure: (with BrainstormSubject, Channel, Data, HeadModel, Result, Stat, Image, NoiseCov, Dipoles, Timefreq and Matrix fields)
                                 % BUT default iChannel and iHeadModel fields are relative paths
        iStudy = [];
        if length(args) > 1
            iStudy = args{2};
        end

        % Get ID of parent subject
        sSubject = db_get(sqlConn, 'Subject', sParsedStudy.BrainStormSubject, 'Id');
        sParsedStudy.Subject = sSubject.Id;
        % Condition must be a string
        if ~isempty(sParsedStudy.Condition)
            sParsedStudy.Condition = char(sParsedStudy.Condition);
        else
            sParsedStudy.Condition = sParsedStudy.Name;
        end

        % Default Channel and HeadModel files
        categories = strcat('i', {'Channel', 'HeadModel'});
        fieldValPairs = [categories; cell(1,length(categories))];
        sDefSurfFiles = struct(fieldValPairs{:});
        for iCat = 1 : length(categories)
            sDefSurfFiles.(categories{iCat}) = sParsedStudy.(categories{iCat});
            sParsedStudy.(categories{iCat}) = [];
        end
        % Get FunctionalFiles
        sFuncFiles = [];
        % Order is not relevant
        types = {'Channel', 'HeadModel', 'Data', 'Matrix', 'Result', ...
                 'Stat', 'Image', 'NoiseCov', 'Dipoles', 'Timefreq'};
        for iType = 1:length(types)
            sFiles = sParsedStudy.(types{iType});
            type = lower(types{iType});
            if ~isempty(sFiles)
                sTypeFuncFiles = db_convert_functionalfile(sFiles, type);
                % Check for noisecov and ndatacov
                if strcmpi(type, 'noisecov') && length(sTypeFuncFiles) == 2
                    sTypeFuncFiles(2).Type = 'ndatacov';
                    % Ignore entries without FileName: if study has only ndatacov, sStudy.NoiseCov(1).FileName is empty
                    sTypeFuncFiles(cellfun(@isempty, {sTypeFuncFiles.FileName})) = [];
                end
                sFuncFiles = [sFuncFiles, sTypeFuncFiles];
            end
        end
        % Check if Study with index iStudy exists
        sStudyOld = db_get(sqlConn, 'Study', iStudy, 'Id');
        if isempty(sStudyOld)
            % Insert Study
            iStudy = db_set(sqlConn, 'Study', sParsedStudy);
        else
            % Update Study
            iStudy = db_set(sqlConn, 'Study', sParsedStudy, sStudyOld.Id);
        end
        % Delete current sFuncFiles in iStudy
        db_set(sqlConn, 'FunctionalFilesWithStudy', 'Delete', iStudy);
        if ~isempty(sFuncFiles)
            % Insert sFuncFiles in iStudy
            db_set(sqlConn, 'FunctionalFilesWithStudy', sFuncFiles, iStudy);
        end
        % Update indices in sStudy for default Channel and HeadModel files
        sDefSurfIds = struct(fieldValPairs{:});
        for iCat = 1 : length(categories)
            if ~isempty(sDefSurfFiles.(categories{iCat}))
                sFuncFile = db_get(sqlConn, 'FunctionalFile', sDefSurfFiles.(categories{iCat}), 'Id');
                if ~isempty(sFuncFile)
                    sDefSurfIds.(categories{iCat}) = sFuncFile.Id;
                end
            end
        end
        varargout{1} = db_set(sqlConn, 'Study', sDefSurfIds, iStudy);


%% ==== SUBJECT ====
    % Success              = db_set('Subject', 'Delete')
    %                      = db_set('Subject', 'Delete', SubjectId)
    %                      = db_set('Subject', 'Delete', SubjectName)
    %                      = db_set('Subject', 'Delete', SubjectFileName)
    %                      = db_set('Subject', 'Delete', CondQuery)
    % [SubjectId, Subject] = db_set('Subject', Subject)
    %                      = db_set('Subject', Subject, SubjectId)
    case 'Subject'
        % Default parameters
        delResult = 0;
        iSubject = [];       
        varargout{1} = [];
        
        if length(args) < 1
            error('Error in number of arguments')
        end
        
        sSubject = args{1};
        if length(args) > 1
            iSubject = args{2};
        end
        % Delete 
        if ischar(sSubject) && strcmpi(sSubject, 'delete')
            if isempty(iSubject)
                % Delete all rows in Subject table
                delResult = sql_query(sqlConn, 'DELETE', 'Subject');
                % Reset auto-increment
                sql_query(sqlConn, 'RESET-AUTOINCREMENT', 'Subject');
            elseif isnumeric(iSubject)
                iSubjectTmp.Id = iSubject;
                iSubject = iSubjectTmp;
            end
            if isstruct(iSubject)
                % Avoid deleting @default_subject
                if (isfield(iSubject, 'Id')       && iSubject.Id == 0 ) || ...
                   (isfield(iSubject, 'Name')     && strcmp(iSubject.Name, bst_get('DirDefaultSubject'))) || ...
                   (isfield(iSubject, 'FileName') && strcmp(iSubject.FileName, bst_fullfile(bst_get('DirDefaultSubject'), 'brainstormsubject.mat')))
                    disp('DB> Cannot delete @default_subject (Id = 0)');
                else
                    % Delete using struct iSubject
                    delResult = sql_query(sqlConn, 'DELETE', 'Subject', iSubject);
                end
            end
            if delResult > 0
                varargout{1} = 1;
            end

        % Insert or Update    
        elseif isstruct(sSubject)
            if isempty(iSubject)
                % Insert Subject row
                sSubject.Id = []; 
                % Insert @default_subject with special Id = 0 in DB
                if strcmp(sSubject.Name, bst_get('DirDefaultSubject'))
                    sSubject.Id = 0;
                end
                iSubject = sql_query(sqlConn, 'INSERT', 'Subject', sSubject);
                varargout{1} = iSubject;
            else
                % Update Subject row
                if ~isfield(sSubject, 'Id') || isempty(sSubject.Id) || sSubject.Id == iSubject
                    resUpdate = sql_query(sqlConn, 'UPDATE', 'Subject', sSubject, struct('Id', iSubject));
                else
                    error('Cannot update Subject, Ids do not match');
                end
                if resUpdate>0
                    varargout{1} = iSubject;
                end
            end
            % If requested, get the inserted or updated row
            if nargout > 1
                varargout{2} = db_get(sqlConn, 'subject', iSubject);
            end
        else
            % No action
        end        

        
%% ==== ANATOMY FILES ====
    % Success                      = db_set('AnatomyFile', 'Delete')
    %                              = db_set('AnatomyFile', 'Delete', AnatomyFileId)
    %                              = db_set('AnatomyFile', 'Delete', CondQuery)
    % [AnatomyFileId, AnatomyFile] = db_set('AnatomyFile', AnatomyFile)
    %                              = db_set('AnatomyFile', AnatomyFile, AnatomyFileId)
    case 'AnatomyFile'
        % Default parameters
        iAnatFile = [];
        varargout{1} = [];
        
        if length(args) < 1
            error('Error in number of arguments')
        end
        
        sAnatFile = args{1};
        if length(args) > 1
            iAnatFile = args{2};
        end
        % Delete 
        if ischar(sAnatFile) && strcmpi(sAnatFile, 'delete')
            if isempty(iAnatFile)
                % Delete all rows in AnatomyFile table
                delResult = sql_query(sqlConn, 'DELETE', 'AnatomyFile');
                % Reset auto-increment
                sql_query(sqlConn, 'RESET-AUTOINCREMENT', 'AnatomyFile');
            else
                if isstruct(iAnatFile)
                    % Delete using the CondQuery
                    delResult = sql_query(sqlConn, 'DELETE', 'AnatomyFile', iAnatFile);
                elseif isnumeric(iAnatFile)
                    % Delete using iAnatomyFile
                    delResult = sql_query(sqlConn, 'DELETE', 'AnatomyFile', struct('Id', iAnatFile));
                end
            end
            if delResult > 0
                varargout{1} = 1;
            end
            
        % Insert or Update    
        elseif isstruct(sAnatFile)
            if isempty(iAnatFile)
                % Insert AnatomyFile row
                sAnatFile.Id = [];
                iAnatFile = sql_query(sqlConn, 'INSERT', 'AnatomyFile', sAnatFile);
                varargout{1} = iAnatFile;
            else
                % Update iAnatomyFile row
                if ~isfield(sAnatFile, 'Id') || isempty(sAnatFile.Id) || sAnatFile.Id == iAnatFile
                    resUpdate = sql_query(sqlConn, 'UPDATE', 'AnatomyFile', sAnatFile, struct('Id', iAnatFile));
                else
                    error('Cannot update AnatomyFile, Ids do not match');
                end
                if resUpdate>0
                    varargout{1} = iAnatFile;
                end
            end
            % If requested, get the inserted or updated row
            if nargout > 1
                varargout{2} = db_get(sqlConn, 'AnatomyFile', iAnatFile);
            end
        else
            % No action
        end
        
%% ==== ANATOMY FILES WITH SUBJECT ====
    % Success        = db_set('AnatomyFilesWithSubject', 'Delete'     , SubjectID)
    % AnatomyFileIds = db_set('AnatomyFilesWithSubject', sAnatomyFiles, SubjectID)
    case 'AnatomyFilesWithSubject'
        sAnatFiles = args{1};
        iSubject = args{2};
        
        % Delete all AnatomyFiles with SubjectID
        if ischar(sAnatFiles) && strcmpi(sAnatFiles, 'delete')
            delResult = sql_query(sqlConn, 'DELETE', 'AnatomyFile', struct('Subject', iSubject));
            varargout{1} = 1;
        end
        % Insert AnatomyFiles to SubjectID
        if isstruct(sAnatFiles) && ~isempty(iSubject)
            [sAnatFiles.Subject] = deal(iSubject);
            insertedIds = zeros(length(sAnatFiles));
            % Insert AnatomyFiles
            for ix = 1 : length(sAnatFiles)
                insertedIds(ix) = db_set(sqlConn, 'AnatomyFile', sAnatFiles(ix));
            end
            % If requested, get inserted AnatomyFilesIds
            if nargout > 0
                varargout{1} = insertedIds;
            end
        end


%% ==== STUDY ====
    % Success          = db_set('Study', 'Delete')
    %                  = db_set('Study', 'Delete', StudyId)
    %                  = db_set('Study', 'Delete', StudyFileName)
    %                  = db_set('Study', 'Delete', CondQuery)
    % [StudyId, Study] = db_set('Study', Study)
    %                  = db_set('Study', Study, StudyId)
    case 'Study'
        % Default parameters
        delResult = 0;
        iStudy = [];
        varargout{1} = [];

        if length(args) < 1
            error('Error in number of arguments')
        end

        sStudy = args{1};
        if length(args) > 1
            iStudy = args{2};
        end
        % Delete
        if ischar(sStudy) && strcmpi(sStudy, 'delete')
            if isempty(iStudy)
                % Delete all rows in Study table
                delResult = sql_query(sqlConn, 'DELETE', 'Study');
                % Reset auto-increment
                sql_query(sqlConn, 'RESET-AUTOINCREMENT', 'Study');
            elseif isnumeric(iStudy)
                iSutudyTmp.Id = iStudy;
                iStudy = iSutudyTmp;
            end
            if isstruct(iStudy)
                % Avoid deleting special study @inter
                if (isfield(iStudy, 'Id')       && iStudy.Id == -2) || ...
                   (isfield(iStudy, 'FileName') && strcmp(iStudy.FileName, bst_fullfile(bst_get('DirAnalysisInter'), 'brainstormstudy.mat')))
                    disp('DB> Cannot delete special study @inter (Id = -2)');
                elseif (isfield(iStudy, 'Id')   && iStudy.Id == -3) || ...
                       (isfield(iStudy, 'FileName') && strcmp(iStudy.FileName, bst_fullfile(bst_get('DirDefaultStudy'), 'brainstormstudy.mat')))
                    disp('DB> Cannot delete global special study @default_study (Id = -3)');
                else
                    % Delete using struct iStudy
                    delResult = sql_query(sqlConn, 'DELETE', 'Study', iStudy);
                end
            end
            if delResult > 0
                varargout{1} = 1;
            end

        % Insert or Update
        elseif isstruct(sStudy)
            if isempty(iStudy)
                % Insert Study row
                sStudy.Id = [];
                % Insert special study @inter
                if (sStudy.Subject == 0) && strcmp(sStudy.Name, bst_get('DirAnalysisInter'))
                    sStudy.Id = -2;
                end
                % Insert special global @default_study
                if (sStudy.Subject == 0) && strcmp(sStudy.Name, bst_get('DirDefaultStudy'))
                    sStudy.Id = -3;
                end
                iStudy = sql_query(sqlConn, 'INSERT', 'Study', sStudy);
                varargout{1} = iStudy;
            else
                % Update Study row
                if ~isfield(sStudy, 'Id') || isempty(sStudy.Id) || sStudy.Id == iStudy
                    resUpdate = sql_query(sqlConn, 'UPDATE', 'Study', sStudy, struct('Id', iStudy));
                else
                    error('Cannot update Study, Ids do not match');
                end
                if resUpdate>0
                    varargout{1} = iStudy;
                end
            end
            % If requested, get the inserted or updated row
            if nargout > 1
                varargout{2} = db_get(sqlConn, 'study', iStudy);
            end
        else
            % No action
        end


%% ==== FUNCTIONAL FILES WITH STUDY ====
    % Success           = db_set('FunctionalFilesWithStudy', 'Delete'        , StudyID)
    % FunctionalFileIds = db_set('FunctionalFilesWithStudy', sFunctionalFiles, StudyID)
    case 'FunctionalFilesWithStudy'
        sFuncFiles = args{1};
        iStudy = [];
        if length(args) > 1
            iStudy = args{2};
        end
        
        % Delete all FunctionalFiles with StudyID
        if ischar(sFuncFiles) && strcmpi(sFuncFiles, 'delete') && ~isempty(iStudy)
            delResult = sql_query(sqlConn, 'DELETE', 'FunctionalFile', struct('Study', iStudy));
            varargout{1} = 1;
        end

        % Insert FunctionalFiles
        if isstruct(sFuncFiles) && ~isempty(iStudy)
            [sFuncFiles.Study] = deal(iStudy);
            % Sort FunctionalFiles
            % Note: Order important here, as potential parent files (Data, Matrix, Result)
            % should be inserted or updated before potential child files (Result, Timefreq, Dipoles)
            ix_sorted = [];
            % Ignore 'datalist' and 'matrixlist', they are handled in db_set('FunctionalFile')
            types_db = {'channel', 'headmodel', 'data', 'matrix', 'result', ...
                        'stat', 'image', 'noisecov', 'ndatacov', 'dipoles', 'timefreq'};
            for iType = 1:length(types_db)
                ix_sorted = [ix_sorted, find(strcmpi(types_db{iType}, {sFuncFiles.Type}))];
            end
            sFuncFiles = sFuncFiles(ix_sorted);
            % Ignore links ('result' with ExtraNum = '1'), they are handled in db_links()
            ixLinks = and(strcmpi({sFuncFiles.Type}, 'result'), cellfun(@(x) isequal(x,1),{sFuncFiles.ExtraNum}));
            sFuncFiles = sFuncFiles(~ixLinks);
            % Insert FunctionalFiles
            insertedIds = zeros(length(sFuncFiles));
            for ix = 1 : length(sFuncFiles)
                insertedIds(ix) = db_set(sqlConn, 'FunctionalFile', sFuncFiles(ix));
            end
            % If requested, get inserted FunctionalFilesIds
            if nargout > 0
                varargout{1} = insertedIds;
            end
        end

        
%% ==== FUNCTIONAL FILES ====
    % Success                            = db_set('FunctionalFile', 'Delete')
    %                                    = db_set('FunctionalFile', 'Delete', FunctionalFileId)
    %                                    = db_set('FunctionalFile', 'Delete', CondQuery)
    % [FunctionalFileId, FunctionalFile] = db_set('FunctionalFile', FunctionalFile)
    %                                    = db_set('FunctionalFile', FunctionalFile, FunctionalFileId)
    case 'FunctionalFile'
        % Minimum number of data (or matrix) files to create a datalist (or matrixlist)
        % TODORC: How many items to create list?
        minListChildren = 2;
        list_names = [];
        % Default parameters
        iFuncFile = [];
        varargout{1} = [];

        if length(args) < 1
            error('Error in number of arguments')
        end
        
        sFuncFile = args{1};
        if length(args) > 1
            iFuncFile = args{2};
        end
        % Delete
        if ischar(sFuncFile) && strcmpi(sFuncFile, 'delete')
            if isempty(iFuncFile)
                % Delete all rows in FunctionalFile table
                delResult = sql_query(sqlConn, 'DELETE', 'FunctionalFile');
                % Reset auto-increment
                sql_query(sqlConn, 'RESET-AUTOINCREMENT', 'FunctionalFile');
            else
                if isstruct(iFuncFile)
                    % Delete using the CondQuery
                    delResult = sql_query(sqlConn, 'DELETE', 'FunctionalFile', iFuncFile);
                elseif isnumeric(iFuncFile)
                    % Get Parent of FunctionalFile to delete
                    sParentFuncFile = db_get(sqlConn, 'ParentFromFunctionalFile', iFuncFile, {'Id', 'Type', 'NumChildren'});
                    % Delete using iFunctionalFile
                    delResult = sql_query(sqlConn, 'DELETE', 'FunctionalFile', struct('Id', iFuncFile));
                    % Handle children count
                    if ~isempty(sParentFuncFile)
                        % Decrement number of children in Parent
                        db_set(sqlConn, 'ParentCount', sParentFuncFile.Id, '-', 1);
                        % If Parent is a List and it had minListChildren (or less) children before removing one children (previous line)
                        if ismember(sParentFuncFile.Type, {'datalist', 'matrixlist'}) && sParentFuncFile.NumChildren <= minListChildren
                            % Remove iParent in former children
                            sChildrenFuncFiles = db_get(sqlConn, 'FunctionalFile', struct('Parent', sParentFuncFile.Id), 'Id');
                            for ix = 1 : length(sChildrenFuncFiles)
                                db_set(sqlConn, 'FunctionalFile', struct('Parent', []), sChildrenFuncFiles(ix).Id);
                            end
                            % Delete list
                            db_set(sqlConn, 'FunctionalFile', 'Delete', sParentFuncFile.Id);
                        end
                    end
                end
            end
            if delResult > 0
                varargout{1} = 1;
            end

        % Insert or Update
        elseif isstruct(sFuncFile)
            % Modify UNIX time
            sFuncFile.LastModified = bst_get('CurrentUnixTime');
            % Check for parent files
            if isfield(sFuncFile, 'Type') && ismember(sFuncFile.Type, {'dipoles', 'result', 'results', 'timefreq'})
                % There is parent FileName (ExtraStr1) but not iParent
                if ~isempty(sFuncFile.ExtraStr1) && ( isempty(sFuncFile.Parent) || sFuncFile.Parent == 0)
                    % Search parent in database (ignore 'datalist' and 'matrixlist' FunctionalFiles)
                    parent = sql_query(sqlConn, 'SELECT', 'FunctionalFile', ...
                             struct('FileName', sFuncFile.ExtraStr1), ...
                             'Id', 'AND Type <> "datalist" AND Type <> "matrixlist"');
                    if ~isempty(parent)
                        sFuncFile.Parent = parent.Id;
                    end
                end
            end

            % Insert FunctionalFile row
            if isempty(iFuncFile)
                sFuncFile.Id = [];
                % Handle list for data and matrix
                if ismember(sFuncFile.Type, {'data', 'matrix'})
                    list_names = {str_remove_parenth(sFuncFile.Comment)};
                    list_type  = sFuncFile.Type;
                    list_study = sFuncFile.Study;
                end
                iFuncFile = sql_query(sqlConn, 'INSERT', 'FunctionalFile', sFuncFile);
                varargout{1} = iFuncFile;
                % Increase the number of children in parent
                if ~isempty(sFuncFile.Parent) && sFuncFile.Parent > 0
                   db_set(sqlConn, 'ParentCount', sFuncFile.Parent, '+', 1);
                end

            % Update iFunctionalFile row
            else
                if ~isfield(sFuncFile, 'Id') || isempty(sFuncFile.Id) || sFuncFile.Id == iFuncFile
                    % Handle list for data and matrix in case of rename
                    if isfield(sFuncFile, 'Comment')
                        % Old row
                        sFuncFileOld = db_get(sqlConn, 'FunctionalFile', iFuncFile, {'Comment', 'Type', 'Study'});
                        if ismember(sFuncFileOld.Type, {'data', 'matrix'})
                            list_names = {str_remove_parenth(sFuncFile.Comment), str_remove_parenth(sFuncFileOld.Comment)};
                            list_type  = sFuncFileOld.Type;
                            list_study = sFuncFileOld.Study;
                        end
                    end
                    resUpdate = sql_query(sqlConn, 'UPDATE', 'FunctionalFile', sFuncFile, struct('Id', iFuncFile));
                else
                    error('Cannot update FunctionalFile, Ids do not match');
                end
                if resUpdate > 0
                    varargout{1} = iFuncFile;
                end
            end

            % Handle List in case of new (Insert) or renamed (Update) FunctionalFile
            if ~isempty(list_names) && (length(unique(list_names)) == length(list_names))
                % Look for existing list
                searchQry = struct('Comment', list_names{1}, 'Study', list_study, 'Type', [list_type, 'list']);
                list = db_get(sqlConn, 'FunctionalFile', searchQry, 'Id');
                if ~isempty(list)
                    % Update child.Parent
                    db_set(sqlConn, 'FunctionalFile', struct('Parent', list.Id), iFuncFile);
                    % Update list.NumChild
                    db_set(sqlConn, 'ParentCount', list.Id, '+', 1);
                else
                    % Look for potential sibilings (including recently inserted FunctionalFile)
                    sFuncFiles = db_get(sqlConn, 'FunctionalFilesWithStudy', list_study, {'Id', 'Comment', 'FileName', 'Parent'}, list_type);
                    if ~isempty(sFuncFiles)
                        cleanNames = cellfun(@(x) str_remove_parenth(x), {sFuncFiles.Comment}, 'UniformOutput', false);
                        % Get items with matching name
                        ix = strcmp(cleanNames, list_names{1});
                        sFunctFilesTmp = sFuncFiles(ix);
                        if length(sFunctFilesTmp) >= minListChildren
                            % Create List
                            listFunctionalFile = db_template('FunctionalFile');
                            listFunctionalFile.Study = list_study;
                            listFunctionalFile.Type = [list_type 'list'];
                            listFunctionalFile.FileName = [sFuncFiles(find(ix, 1)).FileName(1:end-4), '.lst']; % Avoid duplicate FileName
                            listFunctionalFile.Comment = list_names{1};
                            listFunctionalFile.NumChildren = length(sFunctFilesTmp);
                            % Insert List
                            iListFuncFile = db_set(sqlConn, 'FunctionalFile', listFunctionalFile);
                        else
                            iListFuncFile = [];
                        end
                        % Update all sibilings that need it
                        for j = 1 : length(sFunctFilesTmp)
                            if ~isequal(sFunctFilesTmp(j).Parent, iListFuncFile)
                                db_set(sqlConn, 'FunctionalFile', struct('Parent', iListFuncFile), sFunctFilesTmp(j).Id);
                            end
                        end
                    end
                end
            end

            % Handle OldList in case of Renamed FunctionalFile
            if length(unique(list_names)) == 2
                % Look for existing list
                searchQry = struct('Comment', list_names{2}, 'Study', list_study, 'Type', [list_type, 'list']);
                list = db_get(sqlConn, 'FunctionalFile', searchQry, {'Id', 'NumChildren'});
                if ~isempty(list)
                    % Update number of children
                    list.NumChildren = list.NumChildren - 1;
                    db_set(sqlConn, 'FunctionalFile', list, list.Id);
                    if list.NumChildren < minListChildren
                        % Remove Parent in former children
                        sFuncFiles = db_get(sqlConn, 'FunctionalFile', struct('Parent', list.Id), 'Id');
                        for j = 1 : length(sFuncFiles)
                            db_set(sqlConn, 'FunctionalFile', struct('Parent', []), sFuncFiles(j).Id);
                        end
                        % Delete list
                        db_set(sqlConn, 'FunctionalFile', 'Delete', list.Id);
                    end
                end
            end

            % If requested, get the inserted or updated row
            if nargout > 1
                varargout{2} = db_get(sqlConn, 'FunctionalFile', iFuncFile);
            end
        else
            % No action
        end


%% ==== PARENT COUNT ====       
    % db_set('ParentCount', ParentId, modifier, count)
    case 'ParentCount'
        iFile = args{1};
        modifier = args{2};
        count = args{3};
        
        qry = 'UPDATE FunctionalFile SET NumChildren = ';
        
        switch modifier
            case '+'
                qry = [qry 'NumChildren + ' num2str(count)];
            case '-'
                qry = [qry 'NumChildren - ' num2str(count)];
            case '='
                qry = [qry num2str(count)];
            otherwise
                error('Unsupported call.');
        end
        
        sql_query(sqlConn, [qry ' WHERE Id = ' num2str(iFile)]);

%% ==== ERROR ====      
    otherwise
        error('Invalid context : "%s"', contextName);
end
catch ME
    % Close SQL connection if error
    sql_close(sqlConn);
    rethrow(ME)
end

% Close SQL connection if it was created
if handleConn
    sql_close(sqlConn);
end

end



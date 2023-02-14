function OutputLinks = db_links(varargin)
% DB_LINKS: Update all the links to shared results files.
%
% USAGE:  OutputLinks = db_links(sqlConn, 'Subject', iSubject)
%         OutputLinks = db_links(sqlConn, 'Subject', SubjectFile)
%         OutputLinks = db_links(sqlConn, 'Study',   iStudiesList) : Process only the target studies (they must belong to the same subject)
%         OutputLinks = db_links(sqlConn)                          : Process all the subjects of the current protocol
%
%         Argument 'sqlConn' is optional, and is the connection with JDBC
%
% OUTPUT: Links are added to DataBase st of links created
%
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
% Authors: Francois Tadel, 2008-2013
%          Raymundo Cassani, 2022-2023

%% ===== PARSE INPUTS =====
if (length(varargin) > 0) && isjava(varargin{1})
    sqlConn = varargin{1};
    varargin(1) = [];
    handleConn = 0;
else
    sqlConn = sql_connect();
    handleConn = 1;
end

OutputLinks = {};
% CALL: db_links()
if (length(varargin) == 0)
    % For all other subjects, except default subject
    sSubjects = db_get(sqlConn, 'AllSubjects', 'Id');
    % Update results links for global default study
    db_links(sqlConn, 'Subject', 0);
    % For all other subjects
    for iSubject = 1:length(sSubjects)
        % If subject do not share channel file (already processed)
        %if (sSubjectsList.Subject(iSubject).UseDefaultChannel ~= 0)
            % Update results links for subject
            db_links(sqlConn, 'Subject', sSubjects(iSubject).Id);
        %end
    end
    % Hide progress bar
    %bst_progress('stop');
    exit_db_links();
    return
% CALL: db_links('Subject', ...)
elseif (length(varargin) == 2) && ischar(varargin{1}) && strcmpi(varargin{1}, 'Subject')
    % CALL: db_links('Subject', SubjectFile)
    if ischar(varargin{2})
        SubjectFile = varargin{2};
        sSubject = db_get(sqlConn, 'Subject', SubjectFile, '*', 1);
    % CALL: db_links('Subject', iSubject)
    else
        iSubject = varargin{2};
        if (length(iSubject) > 1)
            error('Cannot process more than one subject.');
        end
        sSubject = db_get(sqlConn, 'Subject', iSubject, '*', 1);
    end
    % Check for weird bugs
    if isempty(sSubject)
        warning('Default subject cannot be reached for this protocol.');
        exit_db_links();
        return
    end
    % Get all the studies: including @inter and global  @default_study for default subject
    %                      including @intra and subject @default_study for any other subject
    sStudiesList = db_get(sqlConn, 'StudiesFromSubject', sSubject.Id, {'Id', 'Subject'}, '@inter', '@intra', '@default_study');
% CALL: db_links('Studies', iStudiesList)
elseif (length(varargin) == 2) && ischar(varargin{1}) && strcmpi(varargin{1}, 'Study')
    % Get studies list
    sStudiesList = db_get(sqlConn, 'Study', varargin{2}, {'Id', 'Subject'});
    % Check that they all have the same subject
    [uniqueSubjects, I, J] = unique([sStudiesList.Subject]);
    if (length(uniqueSubjects) ~= 1)
        % If it is not the case: call again the function as many times as needed
        for i = 1:length(uniqueSubjects)
            % Get all the studies for subject #i
            iStudiesSubj = find(J == i);
            % Call this function only with the studies for the subject #i
            OutputLinks = cat(2, OutputLinks, db_links(sqlConn, 'Study', sStudiesList(iStudiesSubj).Id));
        end
        exit_db_links();
        return;
    else
        SubjectFile = uniqueSubjects(1);
    end
    % Get subject
    sSubject = db_get(sqlConn, 'Subject', SubjectFile, {'Id', 'UseDefaultChannel'});
else
    error('Invalid call');
end
% Invalid subject: return
if isempty(sSubject)
    exit_db_links();
    return
end


%% ===== INITIALIZATION =====
% Progress bar
isNewProgressBar = ~bst_progress('isvisible');
if isNewProgressBar
    bst_progress('start', 'Update results links', 'Updating results links...', 1, length(sStudiesList));
else
    %bst_progress('text', 'Updating results links...');
end
% Get the default study for this subject
sDefaultStudy = db_get(sqlConn, 'DefaultStudy', sSubject.Id, 'Id');
% Get 'result' FunctionalFiles
sResultFiles = db_get(sqlConn, 'FunctionalFilesWithStudy', sDefaultStudy.Id, '*', 'result');

% === CREATE NEW LINKS TEMPLATES ===
% Link to default study
if ((sSubject.Id == 0) || (sSubject.UseDefaultChannel ~= 0)) && ~isempty(sDefaultStudy) && ~isempty(sResultFiles)
    [sLinksList, linkResultFiles] = createLinksMat(sResultFiles);
else
    sLinksList = [];
    linkResultFiles = [];
end

%% ===== PROCESS EACH STUDY =====
% For each study
for iStudy = 1:length(sStudiesList)
    % === GET LOCAL SHARED RESULTS ===
    sStudySubject = db_get(sqlConn, 'Subject', sStudiesList(iStudy).Subject, {'Id', 'UseDefaultChannel'});
    % Get all 'result' functional files for study
    sResultFiles = db_get(sqlConn, 'FunctionalFilesWithStudy', sStudiesList(iStudy).Id, '*', 'result');
    if (sStudySubject.UseDefaultChannel == 0)
        % Get the results that do not have any DataFile attached => shared imaging kernels
        iSharedRes = find(cellfun(@isempty, {sResultFiles.ExtraStr1}) ... % no DataFile attached
                          & ~[sResultFiles.ExtraNum] ...                  % is not a link
                          & ~cellfun(@isempty, strfind({sResultFiles.FileName}, '_KERNEL_'))); % '_KERNEL_' in FileName
        % Create links to local shared kernels
        if ~isempty(iSharedRes)
            [sLinksList, linkResultFiles] = createLinksMat(sResultFiles(iSharedRes));
        else
            sLinksList = [];
            linkResultFiles = [];
        end
    end

    % === REMOVE OLD LINKS ===
    % Get the a list of the previous results-links
    sOldLinkRes = find([sResultFiles.ExtraNum]); % isLink
    if ~isempty(sOldLinkRes)
        for ix = 1 : length(sOldLinkRes)
        % Find Children for these links and remove the link as Parent
        sChildFiles = db_get(sqlConn, 'ChildrenFromFunctionalFile', sResultFiles(sOldLinkRes(ix)).Id, 'Id');
        for ij = 1 : length(sChildFiles)
            db_set(sqlConn, 'FunctionalFile', struct('Parent', []), sChildFiles(ij).Id);
        end
        % Remove links from database
        db_set(sqlConn, 'FunctionalFile', 'Delete', sResultFiles(sOldLinkRes(ix)).Id);
        end
    end
    
    % === CREATE NEW LINKS ===
    sDataFiles = db_get(sqlConn, 'FunctionalFilesWithStudy', sStudiesList(iStudy).Id, '*', 'data');
    nData = length(sDataFiles);
    for iData = 1:nData
        % Data structure
        sData = sDataFiles(iData);
        % Check that the file is a real recordings file
        if ~strcmpi(sData.SubType, 'recordings') && ~strcmpi(sData.SubType, 'raw')
            continue;
        end
        % Build one link for each common results file and for each data file
        for iLink = 1:length(sLinksList)
            % Build new link entry
            sLinksList(iLink).ExtraStr1 = file_win2unix(sData.FileName); % .DataFile
            sLinksList(iLink).Parent = sData.Id;
            sLinksList(iLink).Id = [];
            sLinksList(iLink).FileName  = ['link|', linkResultFiles{iLink}, '|', sLinksList(iLink).ExtraStr1];
            % Add link to database
            linkId = db_set(sqlConn, 'FunctionalFile', sLinksList(iLink));
            % Find children for created links
            sChildFiles = db_get(sqlConn, 'FunctionalFile', struct('ExtraStr1', sLinksList(iLink).FileName), 'Id');
            for ij = 1 : length(sChildFiles)
                db_set(sqlConn, 'FunctionalFile', struct('Parent', linkId), sChildFiles(ij).Id);
            end
            % Udpate children count for links (Because childrend were in DB before link was created)
            db_set(sqlConn, 'FunctionalFile', struct('NumChildren', length(sChildFiles)), linkId);
            OutputLinks{end+1} = sLinksList(iLink).FileName;
        end
    end

    % Increment progress bar
    if isNewProgressBar
        bst_progress('inc', 1);
    end
end

% Close progress bar
if isNewProgressBar
    bst_progress('stop');
end
% Handle SQL connection
exit_db_links();

% Exiting db_links, close SQL connnection if it was opened
function exit_db_links()
    if handleConn
        sql_close(sqlConn);
    end
end

end


%% ================================================================================================
%  ====== HELPERS =================================================================================
%  ================================================================================================
function [sLinksList, linkResultFiles] = createLinksMat(Results)
    sLinksList = repmat(db_template('functionalfile'), 1, length(Results));
    linkResultFiles = cell(1,length(Results));
    for iRes = 1:length(Results)
        % Create 'FunctionalFile' structure to be stored in database
        sLinksList(iRes).Study     = Results(iRes).Study;
        sLinksList(iRes).Type      = Results(iRes).Type;
        sLinksList(iRes).FileName  = '';
        sLinksList(iRes).Comment   = Results(iRes).Comment;
        sLinksList(iRes).ExtraNum  = 1;                       % .isLink
        sLinksList(iRes).ExtraStr2 = Results(iRes).ExtraStr2; % .HeadModelType
        linkResultFiles{iRes} = file_win2unix(Results(iRes).FileName);
    end
end




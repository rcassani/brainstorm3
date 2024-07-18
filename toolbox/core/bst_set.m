function argout1 = bst_set( varargin )
% BST_SET: Set a Brainstorm structure.
%
% DESCRIPTION:  This function is used to abstract the way that these structures are stored.
%
% USAGE:
% ====== DIRECTORIES ==================================================================
%    - bst_set('BrainstormHomeDir', BrainstormHomeDir)
%    - bst_set('BrainstormTmpDir',  BrainstormTmpDir)
%    - bst_set('BrainstormDbDir',   BrainstormDbDir)
%    - bst_set('LastUsedDirs',      sDirectories)
%    - bst_set('BrainSuiteDir',     BrainSuiteDir)
%    - bst_set('PythonExe',         PythonExe)
%    - bst_set('PluginCustomPath',  PluginCustomPath)
%
% ====== PROTOCOLS ====================================================================
%    - bst_set('iProtocol',         iProtocol)
%    - bst_set('ProtocolInfo',      sProtocolInfo)
%    - bst_set('ProtocolSubjects',  ProtocolSubjects)
%    - bst_set('isProtocolLoaded',  isProtocolLoaded)
%    - bst_set('isProtocolModified',isProtocolModified)
%    - bst_set('ProtocolStudies',   ProtocolStudies)
%    - bst_set('Study',   iStudy,   sStudy)    : Set a study in current protocol 
%    - bst_set('Subject', iSubject, sSubject)  : Set a subject in current protocol
%
% ====== GUI =================================================================
%    - bst_set('Layout',    sLayout)
%    - bst_set('Layout',    PropName, PropValue)
%    - bst_set('Clipboard', Nodes, isCut)  : Copy operation from the tree
%
% ====== CONFIGURATION =================================================================
%    - bst_set('Version',      Version)
%    - bst_set('ByteOrder',    value)        : 'b' for big endian, 'l' for little endian
%    - bst_set('AutoUpdates',  isAutoUpdates)
%    - bst_set('ExpertMode',   isExpertMode)
%    - bst_set('DisplayGFP',   isDisplayGFP)
%    - bst_set('DownsampleTimeSeries',  isDownsampleTimeSeries)
%    - bst_set('GraphicsSmoothing',     isGraphicsSmoothing)
%    - bst_set('ForceMatCompression',   isForceCompression)
%    - bst_set('IgnoreMemoryWarnings',  isIgnoreMemoryWarnings)
%    - bst_set('SystemCopy',            isSystemCopy)
%    - bst_set('DisableOpenGL',         isDisableOpenGL)
%    - bst_set('InterfaceScaling',      InterfaceScaling)
%    - bst_set('TSDisplayMode',         TSDisplayMode)    : {'butterfly','column'}
%    - bst_set('ElectrodeConfig',       ElectrodeConfig, Modality)
%    - bst_set('ElecInterpDist',        ElecInterpDist, Modality)
%    - bst_set('DefaultFormats'         defaultFormats)
%    - bst_set('BFSProperties',         [scalpCond,skullCond,brainCond,scalpThick,skullThick])
%    - bst_set('ImportEegRawOptions',   ImportEegRawOptions)
%    - bst_set('BugReportOptions',      BugReportOptions)
%    - bst_set('DefaultSurfaceDisplay', displayStruct)
%    - bst_set('MagneticExtrapOptions', extrapStruct)
%    - bst_set('TimefreqOptions_morlet',  Options)
%    - bst_set('TimefreqOptions_fft',     Options)
%    - bst_set('TimefreqOptions_psd',     Options)
%    - bst_set('TimefreqOptions_hilbert', Options)
%    - bst_set('TimefreqOptions_plv',     Options)
%    - bst_set('OpenMEEGOptions',         Options)
%    - bst_set('DuneuroOptions',         Options)
%    - bst_set('GridOptions_headmodel',   Options)
%    - bst_set('GridOptions_dipfit',      Options)
%    - bst_set('UniformizeTimeSeriesScales', isUniform)
%    - bst_set('FlipYAxis',             isFlipY)
%    - bst_set('AutoScaleY',            isAutoScaleY)
%    - bst_set('FixedScaleY',           Modality,  Value)
%    - bst_set('XScale',                XScale)
%    - bst_set('YScale',                YScale)
%    - bst_set('ShowXGrid',             isShowXGrid)
%    - bst_set('ShowYGrid',             isShowYGrid)
%    - bst_set('ShowZeroLines',         isShowZeroLines)
%    - bst_set('ShowEventsMode',        ShowEventsMode)
%    - bst_set('Resolution',            [resX,resY])
%    - bst_set('UseSigProcToolbox',     UseSigProcToolbox)
%    - bst_set('RawViewerOptions',      RawViewerOptions)
%    - bst_set('TopoLayoutOptions',     TopoLayoutOptions)
%    - bst_set('StatThreshOptions',     StatThreshOptions)
%    - bst_set('ContactSheetOptions',   ContactSheetOptions)
%    - bst_set('ProcessOptions',        ProcessOptions)
%    - bst_set('MriOptions',            MriOptions)
%    - bst_set('CustomColormaps',       CustomColormaps)
%    - bst_set('DigitizeOptions',       DigitizeOptions)
%    - bst_set('PcaOptions',            PcaOptions) 
%    - bst_set('ReadOnly',              ReadOnly)
%    - bst_set('LastPsdDisplayFunction', LastPsdDisplayFunction)
%    - bst_set('PlotlyCredentials',     Username, ApiKey, Domain)
%    - bst_set('KlustersExecutable',    ExecutablePath)
%    - bst_set('ExportBidsOptions'),    ExportBidsOptions)
%    - bst_set('Pipelines')             Saved Pipelines stored
%
% SEE ALSO bst_get

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
% Authors: Francois Tadel, 2008-2021
%          Martin Cousineau, 2017

global GlobalData;

%% ==== PARSE INPUTS ====
if ((nargin >= 1) && ischar(varargin{1}))
    contextName  = varargin{1};
    if (nargin >= 2)
        contextValue = varargin{2};
    else
        contextValue = [];
    end
else
    error('Usage : bst_set(contextName, contextValue)');
end
argout1 = [];

% Get required context structure
switch contextName      
%% ==== BRAINSTORM CONFIGURATION ====
    case 'Version'
        GlobalData.Program.Version = contextValue;
    case 'BrainstormHomeDir'
        GlobalData.Program.BrainstormHomeDir = contextValue;
    case 'BrainstormDbDir'
        GlobalData.DataBase.BrainstormDbDir = contextValue;
    case 'BrainstormTmpDir'
        GlobalData.Preferences.BrainstormTmpDir = contextValue;
    case 'Pipelines'
        GlobalData.Processes.Pipelines = contextValue;
    case 'ProgramStartUnixTime'
        GlobalData.Program.StartTime = contextValue;

%% ==== PROTOCOL ====
    case 'iProtocol'
        if isnumeric(contextValue)
            GlobalData.DataBase.iProtocol = contextValue;
        else
            error('iProtocol should be a number.');
        end
    
    case 'ProtocolSubjects'
        warning('bst_set(''%s'') will be deprecated in new Brainstorm database system. Use db_set(''%s'')', contextName, 'ParsedSubject');

        sqlConn = sql_connect();
        % Get filenames for default anatomy and sufaces before deleting DataBase
        sSubjects = [contextValue.DefaultSubject, contextValue.Subject];
        for ix = 1: length(sSubjects)
            if isempty(sSubjects(ix))
                continue
            end
            % Replace indexes for default anatomy and sufaces with their filenames
            categories = strcat('i', {'Anatomy', 'Scalp', 'Cortex', 'InnerSkull', 'OuterSkull', 'Fibers', 'FEM'});
            for iCat = 1 : length(categories)
                if ~isempty(sSubjects(ix).(categories{iCat}))
                    sAnatFile = db_get(sqlConn, 'AnatomyFile', sSubjects(ix).(categories{iCat}), 'FileName');
                    if ~isempty(sAnatFile)
                        sSubjects(ix).(categories{iCat}) = sAnatFile.FileName;
                    else
                        sSubjects(ix).(categories{iCat}) = [];
                    end
                end
            end
        end
        % Get all Subjects
        sSubjectsOld = db_get(sqlConn, 'AllSubjects', 'Id', '@default_subject');
        % Update Subjects and their Anatomy Files
        [~, ~, ib] = intersect([sSubjectsOld.Id],[sSubjects.Id]);
        for ix = 1 : length(ib)
            db_set(sqlConn, 'ParsedSubject', sSubjects(ib(ix)), sSubjects(ib(ix)).Id);
        end
        % Subjects to Insert or Delete
        [~, ia, ib] = setxor([sSubjectsOld.Id],[sSubjects.Id]);
        ia = sort(ia);
        ib = sort(ib);
        % Delete Subjects (and their Anatomy Files) present in DB but not in sSubjects
        for ix = 1 : length(ia)
            db_set(sqlConn, 'Subject', 'Delete', sSubjectsOld(ia(ix)).Id);
        end
        % Insert Subjects (and their Anatomy Files) present in sSubjects but not in DB
        for ix = 1 : length(ib)
            db_set(sqlConn, 'ParsedSubject', sSubjects(ib(ix)));
        end
        sql_close(sqlConn);
        
    case 'ProtocolStudies'
        warning('bst_set(''%s'') will be deprecated in new Brainstorm database system. Use db_set(''%s'')', contextName, 'ParsedStudy');

        sqlConn = sql_connect();
        % Get filenames for default channel and head model before deleting DataBase
        sStudies = [contextValue.DefaultStudy, contextValue.AnalysisStudy, contextValue.Study];
        for ix = 1: length(sStudies)
            if isempty(sStudies(ix))
                continue
            end
            % Replace indexes for channel and head model with their filenames
            categories = strcat('i', {'Channel', 'HeadModel'});
            for iCat = 1 : length(categories)
                if ~isempty(sStudies(ix).(categories{iCat}))
                    sFuncFile = db_get(sqlConn, 'FunctionalFile', sStudies(ix).(categories{iCat}), 'FileName');
                    if ~isempty(sFuncFile)
                        sStudies(ix).(categories{iCat}) = sFuncFile.FileName;
                    else
                        sStudies(ix).(categories{iCat}) = [];
                    end
                end
            end
        end
        % Get all Studies
        sStudiesOld = db_get(sqlConn, 'AllStudies', 'Id', '@inter', '@default_study');

        % Update Studies and their Functional Files
        [~, ~, ib] = intersect([sStudiesOld.Id],[sStudies.Id]);
        for ix = 1 : length(ib)
            db_set(sqlConn, 'ParsedStudy', sStudies(ib(ix)), sStudies(ib(ix)).Id);
        end
        % Studies to Insert or Delete
        [~, ia, ib] = setxor([sStudiesOld.Id],[sStudies.Id]);
        ia = sort(ia);
        ib = sort(ib);
        % Delete Studies (and their Functional Files) present in DB but not in sStudies
        for ix = 1 : length(ia)
            db_set(sqlConn, 'Study', 'Delete', sStudiesOld(ia(ix)).Id);
        end
        % Insert Studies (and their Functional Files) present in sStudies but not in DB
        for ix = 1 : length(ib)
            db_set(sqlConn, 'ParsedStudy', sStudies(ib(ix)));
        end
        % Update links
        db_links(sqlConn);
        sql_close(sqlConn);
        
        
    case 'ProtocolInfo'
        for structField = fieldnames(contextValue)'
            GlobalData.DataBase.(contextName)(GlobalData.DataBase.iProtocol).(structField{1}) = contextValue.(structField{1});
        end
    case 'isProtocolLoaded'
        GlobalData.DataBase.isProtocolLoaded(GlobalData.DataBase.iProtocol) = contextValue;
    case 'isProtocolModified'
        error('TODO: Not supported anymore.');


%% ==== SUBJECT ====
    case 'Subject'
        warning('bst_set(''%s'') will be deprecated in new Brainstorm database system. Use db_set(''%s'')', contextName, 'ParsedSubject or Subject');
        iSubject = varargin{2};
        sSubject = varargin{3};
        sqlConn = sql_connect();
        
        % Get subject
        sExistingSubject = db_get(sqlConn, 'Subject', iSubject, 'Id');
        % Convert sSubject structure to sParsedSubject by replacing indexes for
        % currently selected Anatomy and Surface files to their FileNames
        categories = strcat('i', {'Anatomy', 'Scalp', 'Cortex', 'InnerSkull', 'OuterSkull', 'Fibers', 'FEM'});
        for iCat = 1 : length(categories)
            if ~isempty(sSubject.(categories{iCat}))
                sAnatFile = db_get(sqlConn, 'AnatomyFile', sSubject.(categories{iCat}), 'FileName');
                if ~isempty(sAnatFile)
                    sSubject.(categories{iCat}) = sAnatFile.FileName;
                else
                    sSubject.(categories{iCat}) = [];
                end
            end
            % Set default selected files
            if isempty(sSubject.(categories{iCat}))
                category = categories{iCat}(2:end);
                switch category
                    case 'Anatomy'
                        if ~isempty(sSubject.(category))
                            sSubject.(categories{iCat}) = sSubject.(category)(1).FileName;
                        end
                    case {'Scalp', 'Cortex', 'InnerSkull', 'OuterSkull', 'Fibers', 'FEM'}
                        if ~isempty(sSubject.Surface)
                            ix_def = find(strcmpi({sSubject.Surface.SurfaceType}, category), 1, 'first');
                            if ~isempty(ix_def)
                                sSubject.(categories{iCat}) = sSubject.Surface(ix_def).FileName;
                            end
                        end
                end
            end
        end
        
        % If subject exists, UPDATE
        if ~isempty(sExistingSubject)
            iSubject  = db_set(sqlConn, 'ParsedSubject', sSubject, sExistingSubject.Id);
        % If subject is new, INSERT
        else
            iSubject  = db_set(sqlConn, 'ParsedSubject', sSubject);
        end
        if ~isempty(iSubject)
            argout1 = iSubject;
        end
        sql_close(sqlConn);
        
        
%% ==== STUDY ====
    case 'Study'
        warning('bst_set(''%s'') will be deprecated in new Brainstorm database system. Use db_set(''%s'')', contextName, 'ParsedStudy or Study');

        % Get studies list
        iStudies = varargin{2};
        sStudies = varargin{3};
        iStudiesOut = [];
        sqlConn = sql_connect();

        for ix = 1:length(iStudies)
            % Get study
            sExistingStudy = db_get(sqlConn, 'Study', iStudies(ix), 'Id');
            sStudy = sStudies(ix);
            % Convert sStudy structure to sParsedStudy by replacing indexes for
            % currently selected Channel and HeadModel files to their FileNames
            categories = strcat('i', {'Channel', 'HeadModel'});
            for iCat = 1 : length(categories)
                if ~isempty(sStudy.(categories{iCat}))
                    sFuncFile = db_get(sqlConn, 'FunctionalFile', sStudy.(categories{iCat}), 'FileName');
                    if ~isempty(sFuncFile)
                        sStudy.(categories{iCat}) = sFuncFile.FileName;
                    else
                        sStudy.(categories{iCat}) = [];
                    end
                end
                % Set default selected files
                if isempty(sStudy.(categories{iCat}))
                    category = categories{iCat}(2:end);
                    if ~isempty(sStudy.(category))
                        sStudy.(categories{iCat}) = sStudy.(category)(1).FileName;
                    end
                end
            end
            % If study exists, UPDATE
            if ~isempty(sExistingStudy)
                iStudy  = db_set(sqlConn, 'ParsedStudy', sStudy, sExistingStudy.Id);
            % If subject is new, INSERT
            else
                iStudy  = db_set(sqlConn, 'ParsedStudy', sStudy);
            end
            iStudiesOut = [iStudiesOut, iStudy];
        end
        if ~isempty(iStudiesOut)
            argout1 = iStudiesOut;
        end
        db_links(sqlConn, 'Study', iStudiesOut);
        sql_close(sqlConn);
        
        
%% ==== GUI ====
    % USAGE: bst_set('Layout', sLayout)
    %        bst_set('Layout', PropName, PropValue)
    case 'Layout'
        if (nargin == 2) && isstruct(contextValue)
            GlobalData.Preferences.Layout = contextValue;
            isUpdateScreens = 0;
        elseif (nargin == 3) && ischar(contextValue) && isfield(GlobalData.Preferences, 'Layout') && isfield(GlobalData.Preferences.Layout, contextValue)
            GlobalData.Preferences.Layout.(contextValue) = varargin{3};
            isUpdateScreens = strcmpi(contextValue, 'DoubleScreen');
        else
            error('Invalid call to bst_set.');
        end
        % Update screen configuration
        GlobalData.Program.ScreenDef = gui_layout('GetScreenClientArea');
        % Update layout right now
        gui_layout('Update');
        % If the number of screen was changed: update the maximum size of the Brainstorm window
        if isUpdateScreens
            gui_layout('UpdateMaxBstSize');
        end
        
    % USAGE: bst_set('FixedScaleY', [])
    %        bst_set('FixedScaleY', Modality, Value)
    case 'FixedScaleY'
        if (nargin == 3) && ~isempty(contextValue) && ~isempty(varargin{3})
            GlobalData.Preferences.FixedScaleY.(contextValue) = varargin{3};
        elseif (nargin == 2) && isempty(contextValue)
            GlobalData.Preferences.FixedScaleY = struct();
        end
        
    case 'ByteOrder'
        switch(contextValue)
            case {'b','ieee-le','n'}
                GlobalData.Preferences.ByteOrder = 'b';
            case {'l','ieee-be'}
                GlobalData.Preferences.ByteOrder = 'l';
            otherwise
                error('Invalid byte order.');
        end
        
    case 'Clipboard'
        if (length(varargin) >= 3)
            isCut = varargin{3};
        else
            isCut = 0;
        end
        GlobalData.Program.Clipboard.Nodes = contextValue;
        GlobalData.Program.Clipboard.isCut = isCut;
        
    case 'ElectrodeConfig'
        Modality = varargin{2};
        ElectrodeConf = varargin{3};
        if isequal(Modality, 'ECOG+SEEG')
            Modality = 'ECOG_SEEG';
        elseif ~ismember(Modality, {'EEG','SEEG','ECOG','MEG'})
            error(['Invalid modality: ' Modality]);
        end
        GlobalData.Preferences.(contextName).(Modality) = ElectrodeConf;

    case 'ElecInterpDist'
        Modality = varargin{2};
        ElecInterpDist = varargin{3};
        if isequal(Modality, 'ECOG+SEEG')
            Modality = 'ECOG_SEEG';
        elseif ~ismember(Modality, {'EEG','SEEG','ECOG','MEG'})
            error(['Invalid modality: ' Modality]);
        end
        GlobalData.Preferences.(contextName).(Modality) = ElecInterpDist;

    case {'UniformizeTimeSeriesScales', 'XScale', 'YScale', 'FlipYAxis', 'AutoScaleY', 'ShowXGrid', 'ShowYGrid', 'ShowZeroLines', 'ShowEventsMode', ...
          'Resolution', 'AutoUpdates', 'ExpertMode', 'DisplayGFP', 'ForceMatCompression', 'GraphicsSmoothing', 'DownsampleTimeSeries', ...
          'DisableOpenGL', 'InterfaceScaling', 'TSDisplayMode', 'UseSigProcToolbox', 'LastUsedDirs', 'DefaultFormats', ...
          'BFSProperties', 'ImportDataOptions', 'ImportEegRawOptions', 'RawViewerOptions', 'MontageOptions', 'TopoLayoutOptions', ...
          'StatThreshOptions', 'ContactSheetOptions', 'ProcessOptions', 'BugReportOptions', 'DefaultSurfaceDisplay', ...
          'MagneticExtrapOptions', 'MriOptions', 'ConnectGraphOptions', 'NodelistOptions', 'IgnoreMemoryWarnings', 'SystemCopy', ...
          'TimefreqOptions_morlet', 'TimefreqOptions_hilbert', 'TimefreqOptions_fft', 'TimefreqOptions_psd', 'TimefreqOptions_stft', 'TimefreqOptions_plv', ...
          'OpenMEEGOptions', 'DuneuroOptions', 'DigitizeOptions', 'PcaOptions', 'CustomColormaps', 'PluginCustomPath', 'BrainSuiteDir', 'PythonExe', ...
          'GridOptions_headmodel', 'GridOptions_dipfit', 'LastPsdDisplayFunction', 'KlustersExecutable', 'ExportBidsOptions'}
        GlobalData.Preferences.(contextName) = contextValue;

    case 'ReadOnly'
        GlobalData.DataBase.isReadOnly = contextValue;
    
    case 'PlotlyCredentials'
        if length(varargin) ~= 4
            error('Invalid call to bst_set.');
        end
        [username, apiKey, domain] = varargin{2:4};
        % Default domain: plot.ly
        if isempty(domain)
            domain = 'https://plot.ly';
        end
        % Plotly needs a URL with HTTP and no trailing slash.
        if strfind(domain, 'https://')
            domain = strrep(domain, 'https://', 'http://');
        elseif isempty(strfind(domain, 'http://'))
            domain = ['http://', domain];
        end
        if domain(end) == '/'
            domain = domain(1:end-1);
        end
        % Save credentials
        saveplotlycredentials(username, apiKey);
        saveplotlyconfig(domain);
        
%% ==== ERROR ====
    otherwise
        error('Invalid context : ''%s''', contextName);
        

end


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
%    - bst_set('ReadOnly',              ReadOnly)
%    - bst_set('LastPsdDisplayFunction', LastPsdDisplayFunction)
%    - bst_set('PlotlyCredentials',     Username, ApiKey, Domain)
%    - bst_set('KlustersExecutable',    ExecutablePath)
%    - bst_set('ExportBidsOptions'),    ExportBidsOptions)
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
    case 'ProgramStartTime'
        GlobalData.Program.StartTime = contextValue;

%% ==== PROTOCOL ====
    case 'iProtocol'
        if isnumeric(contextValue)
            GlobalData.DataBase.iProtocol = contextValue;
        else
            error('iProtocol should be a number.');
        end
    
    case 'ProtocolSubjects'
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
        % Delete existing subjects and anatomy files
        db_set(sqlConn, 'Subject', 'delete');
        db_set(sqlConn, 'AnatomyFile', 'delete');
        % Insert parsed subjects
        for ix = 1 : length(sSubjects)
            db_set(sqlConn, 'ParsedSubject', sSubjects(ix));
        end
        sql_close(sqlConn);
        
    case 'ProtocolStudies'
        sqlConn = sql_connect();
        % Delete existing studies and functional files
        db_set(sqlConn, 'Study', 'delete');
        db_set(sqlConn, 'FunctionalFile', 'delete');
        sql_close(sqlConn);

        for iStudy = -1:length(contextValue.Study)
            if iStudy == -1
                sStudy = contextValue.DefaultStudy;
            elseif iStudy == 0
                sStudy = contextValue.AnalysisStudy;
            else
                sStudy = contextValue.Study(iStudy);
            end

            % Skip empty Default / Analysis studies
            % TODO: If these are empty, they should be removed also from HDD
%             if isempty(sStudy) || ((iStudy < 1 || ismember(sStudy.Name, {'@default_study', '@intra', '@inter'})) ...
%                     && isempty(sStudy.Channel) && isempty(sStudy.Data) ...
%                     && isempty(sStudy.HeadModel) && isempty(sStudy.Result) ...
%                     && isempty(sStudy.Stat) && isempty(sStudy.Image) ...
%                     && isempty(sStudy.NoiseCov) && isempty(sStudy.Dipoles) ...
%                     && isempty(sStudy.Timefreq) && isempty(sStudy.Matrix))
%                 continue
%             end

            % Get ID for parent Subject
            if isempty(sStudy.Subject)
                sSubject = db_get('Subject', sStudy.BrainStormSubject, 'Id');
                sStudy.Subject = sSubject.Id;
            end
            % Insert study
            sStudy.Condition = char(sStudy.Condition);
            StudyId = db_set('Study', sStudy);
            sStudy.Id = StudyId;
            bst_set('Study', sStudy.Id, sStudy);
        end
        
        
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
            iSubject  = db_set('ParsedSubject', sSubject, sExistingSubject.Id);
        % If subject is new, INSERT
        else
            iSubject  = db_set('ParsedSubject', sSubject);
        end
        if ~isempty(iSubject)
            argout1 = iSubject;
        end
        sql_close(sqlConn);
        
        
%% ==== STUDY ====
    case 'Study'
        % Get studies list
        iStudies = varargin{2};
        sStudies = varargin{3};
        iAnalysisStudy = -2; % @inter
        iDefaultStudy  = -3; % global @default_study
        
        sqlConn = sql_connect();
        for i = 1:length(iStudies)
            % Inter-subject analysis study
            if iStudies(i) == iAnalysisStudy
                sExistingStudy = db_get(sqlConn, 'Study', '@inter', 'Id');
            % Default study
            elseif iStudies(i) == iDefaultStudy
                sExistingStudy = db_get(sqlConn, 'Study', '@default_study', 'Id');
            % Normal study
            else
                sExistingStudy = db_get(sqlConn, 'Study', iStudies(i), 'Id');
            end
            
            % Get ID of parent subject
            sSubject = db_get(sqlConn, 'Subject', sStudies(i).BrainStormSubject, 'Id');
            sStudies(i).Subject = sSubject.Id;
            
            % Get FileNames for currently selected Channel and HeadModel files
            categories = {'Channel', 'HeadModel'};
            selectedFiles = cell(1, length(categories));
            for iCat = 1:length(categories)
                category = categories{iCat};
                field = ['i' category];
                if ~isempty(sStudies(i).(field)) && ischar(sStudies(i).(field))
                    selectedFiles{iCat} = sStudies(i).(field);
                elseif ~isempty(sStudies(i).(field)) && isnumeric(sStudies(i).(field)) && sStudies(i).(field) > 0
                    % Get FileName with previous file ID before it's deleted
                    sFuncFile = db_get(sqlConn, 'FunctionalFile', sStudies(i).(field), 'FileName');
                    if ~isempty(sFuncFile)
                        selectedFiles{iCat} = sFuncFile.FileName;
                    end
                end
                % Set default selected files
                if isempty(selectedFiles{iCat}) && ~isempty(sStudies(i).(category))
                    selectedFiles{iCat} = sStudies(i).(category)(1).FileName;
                end
            end
            
            sStudies(i).Condition = char(sStudies(i).Condition);
            % If study exists, UPDATE query
            if ~isempty(sExistingStudy)
                sStudies(i).Id = sExistingStudy.Id;
                sExistingStudy.Id = db_set(sqlConn, 'Study', sStudies(i), sExistingStudy.Id);
                if sExistingStudy.Id
                    iStudy = sExistingStudy.Id;
                    argout1(end + 1) = iStudy;
                else
                    iStudy = [];
                end
            % If study is new, INSERT query
            else
                sStudies(i).Id = [];
                iStudy = db_set(sqlConn, 'Study', sStudies(i));
                if ~isempty(iStudy)
                    argout1(end + 1) = iStudy;
                end
            end
            
            if ~isempty(iStudy)
                % Delete existing functional files for this study
                db_set(sqlConn, 'FunctionalFilesWithStudy', 'Delete', iStudy);
                sFuncFiles = [];
                % Order is not relevant
                types = {'Channel', 'HeadModel', 'Data', 'Matrix', 'Result', ...
                         'Stat', 'Image', 'NoiseCov', 'Dipoles', 'Timefreq'};
                for iType = 1:length(types)
                    sFiles = sStudies(i).(types{iType});
                    type = lower(types{iType});
                    if isempty(sFiles)
                        continue
                    end
                    % Convert to FunctionalFile structure
                    sTypeFuncFiles = db_convert_functionalfile(sFiles, type);
                    % Check for noisecov and ndatacov
                    if strcmpi(type, 'noisecov') && length(sTypeFuncFiles) == 2
                        sTypeFuncFiles(2).Type = 'ndatacov';
                    end
                    sFuncFiles = [sFuncFiles, sTypeFuncFiles];
                end
                if ~isempty(sFuncFiles)
                    % Remove FunctionalFiles with empty FileName
                    iNotEmpty = ~cellfun(@isempty,{sFuncFiles.FileName});
                    % Insert FunctionalFiles in database
                    db_set(sqlConn, 'FunctionalFilesWithStudy', sFuncFiles(iNotEmpty), iStudy);
                end
                % Set selected Channel and HeadModel files
                hasSelFiles = 0;
                selFiles = struct();
                for iCat = 1:length(categories)
                    if ~isempty(selectedFiles{iCat})
                        hasSelFiles = 1;
                        sFuncFile = db_get(sqlConn, 'FunctionalFile', selectedFiles{iCat}, 'Id');
                        selFiles.(['i' categories{iCat}]) = sFuncFile.Id;
                    end
                end
                if hasSelFiles
                    db_set(sqlConn, 'Study', selFiles, iStudy);
                end
            end
        end
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
        if ~ismember(Modality, {'EEG','SEEG','ECOG'})
            error(['Invalid modality: ' Modality]);
        end
        GlobalData.Preferences.(contextName).(Modality) = ElectrodeConf;
        
    case {'UniformizeTimeSeriesScales', 'XScale', 'YScale', 'FlipYAxis', 'AutoScaleY', 'ShowXGrid', 'ShowYGrid', 'ShowZeroLines', 'ShowEventsMode', ...
          'Resolution', 'AutoUpdates', 'ExpertMode', 'DisplayGFP', 'ForceMatCompression', 'GraphicsSmoothing', 'DownsampleTimeSeries', ...
          'DisableOpenGL', 'InterfaceScaling', 'TSDisplayMode', 'UseSigProcToolbox', 'LastUsedDirs', 'DefaultFormats', ...
          'BFSProperties', 'ImportDataOptions', 'ImportEegRawOptions', 'RawViewerOptions', 'MontageOptions', 'TopoLayoutOptions', ...
          'StatThreshOptions', 'ContactSheetOptions', 'ProcessOptions', 'BugReportOptions', 'DefaultSurfaceDisplay', ...
          'MagneticExtrapOptions', 'MriOptions', 'ConnectGraphOptions', 'NodelistOptions', 'IgnoreMemoryWarnings', 'SystemCopy', ...
          'TimefreqOptions_morlet', 'TimefreqOptions_hilbert', 'TimefreqOptions_fft', 'TimefreqOptions_psd', 'TimefreqOptions_plv', ...
          'OpenMEEGOptions', 'DuneuroOptions', 'DigitizeOptions', 'CustomColormaps', 'PluginCustomPath', 'BrainSuiteDir', 'PythonExe', ...
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


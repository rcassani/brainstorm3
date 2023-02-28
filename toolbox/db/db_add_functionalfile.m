function iFuncFile = db_add_functionalfile(iStudy, FileName, iParent, Comment)
% DB_ADD_FUNCTIONALFILE: Add an FunctionalFile in database
%
% USAGE: iFuncFile = db_add_functionalfile(iStudy, FileName, iParent, Comment)
%
% INPUT:
%    - iStudy   : ID of the Study where to add the functional file
%    - FileName : Full or relative filename in which the FunctionalFile is defined
%    - iParent  : Optional ID of parent FunctionalFile
%    - Comment  : Optional FunctionalFile description
%    - SubType  : Optional string
%                 Type 'volume',  possible SubTypes: 'Image', 'Atlas'
%                 Type 'surface', possible SubTypes: 'Cortex', 'Scalp', 'InnerSkull', 'OuterSkull', 'Fibers', 'FEM', 'Other'
%
% OUTPUT:
%    - iFuncFile : ID of the FunctionalFile that was created

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
% Authors: Raymundo Cassani, 2022

% Handle iParent
if (nargin < 3)
    iParent = [];
end

% If comment is not defined
sMatFields = {};
if (nargin < 4) || isempty(Comment)
    sMatFields = [sMatFields, {'Comment'}];
end

% Prepare FunctionalFile
sFuncFile = db_template('FunctionalFile');
sFuncFile.Study    = iStudy;
sFuncFile.FileName = FileName;
sFuncFile.Parent   = iParent;

% Get metadata from file accordings its FunctionalFile type
fileType = file_gettype(FileName);
sMat = [];
% FileTypes --> FunctionalFileType
switch fileType
    % channel
    case 'channel'
        sFuncFile.Type = fileType;
        sMatFields = [sMatFields, {'nbChannels', 'Modalities', 'DisplayableSensorTypes'}];
        sMat = load(file_fullpath(FileName), sMatFields{:});
        sFuncFile.ExtraNum  = sMat.nbChannels;
        sFuncFile.ExtraStr1 = str_join(sMat.Modalities, ',');
        sFuncFile.ExtraStr2 = str_join(sMat.DisplayableSensorTypes, ',');

    % {data, spike} --> data
    case {'data', 'spike'}
        sFuncFile.Type = 'data';
        sMatFields = [sMatFields, {'DataType'}];
        sMat = load(file_fullpath(FileName), sMatFields{:});
        sFuncFile.SubType  = sMat.DataType;
        sFuncFile.ExtraNum = 0; % BadTrial

    % dipoles
    case 'dipoles'
        sFuncFile.Type = fileType;
        sMatFields = [sMatFields, {'DataFile'}];
        sMat = load(file_fullpath(FileName), sMatFields{:});
        sFuncFile.ExtraStr1 = sMat.DataFile;

    % headmodel
    case 'headmodel'
        sFuncFile.Type = fileType;
        sMatFields = [sMatFields, {'HeadModelType', 'MEGMethod', 'EEGMethod', 'ECOGMethod', 'SEEGMethod'}];
        sMat = load(file_fullpath(FileName), sMatFields{:});
        allMods = {'MEG', 'EEG', 'ECOG', 'SEEG'};
        modalities = {};
        methods = {};
        for iMod = 1:length(allMods)
            field = [allMods{iMod} 'Method'];
            if ~isempty(sMat.(field))
                modalities{end + 1} = allMods{iMod};
                methods{end + 1} = sMat.(field);
            end
        end
        sFuncFile.SubType   = sMat.HeadModelType;
        sFuncFile.ExtraStr1 = str_join(modalities, ',');
        sFuncFile.ExtraStr2 = str_join(methods, ',');

    % results --> result
    case 'results'
        sFuncFile.Type = 'result';
        sMatFields = [sMatFields, {'DataFile', 'isLink', 'HeadModelType'}];
        sMat = load(file_fullpath(FileName), sMatFields{:});
        sFuncFile.ExtraNum   = sMat.isLink;
        sFuncFile.ExtraStr1  = sMat.DataFile;
        sFuncFile.ExtraStr2  = sMat.HeadModelType;

    % {presults, pdata, ptimefreq, pmatrix} -- > stat
    case {'presults', 'pdata', 'ptimefreq', 'pmatrix'}
        sFuncFile.Type = 'stat';
        sMatFields = [sMatFields, {'Type', 'DataFile', 'pThreshold'}];
        sMat = load(file_fullpath(FileName), sMatFields{:});
        sFuncFile.SubType   = sMat.Type;
        % TODORC : Fields 'DataFile' and 'pThreshold' are not present in stat files
        % sFuncFile.ExtraStr1 = sMat.DataFile;
        % sFuncFile.ExtraStr2 = sMat.pThreshold;

    % timefreq
    case 'timefreq'
        sFuncFile.Type = fileType;
        sMatFields = [sMatFields, {'DataFile', 'DataType'}];
        sMat = load(file_fullpath(FileName), sMatFields{:});
        sFuncFile.SubType   = sMat.DataType;
        sFuncFile.ExtraStr1 = sMat.DataFile;

    % image, matrix, noisecov, ndatacov
    case 'image'
        sFuncFile.Type = fileType;
        if ~isempty(sMatFields)
            sMat = load(file_fullpath(FileName), sMatFields{:});
        end

    otherwise
        bst_error('File type does not correspond to any FunctionalFile type')
end

% Add Comment
if ~isempty(sMat) && isfield(sMat, 'Comment')
    Comment = sMat.Comment;
end
sFuncFile.Comment  = Comment;

% Add FunctionalFile to database
iFuncFile = db_set('FunctionalFile', sFuncFile);
end

% Concatenate strings using delimiter
function outStr = str_join(cellStr, delimiter)
    outStr = '';
    for iCell = 1:length(cellStr)
        if iCell > 1
            outStr = [outStr delimiter];
        end
        outStr = [outStr cellStr{iCell}];
    end
end




function iAnatFile = db_add_anatomyfile(iSubject, FileName, Comment, SubType)
% DB_ADD_ANATOMYFILE: Add an AnatomyFile in database
%
% USAGE: iAnatomyFile = db_add_anatomyfile(iSubject, FileName, Comment, SubType)
%
% INPUT:
%    - iSubject : ID of the Subject where to add the surface
%    - FileName : Full or relative filename in which the AnatomyFile is defined
%    - Comment  : Optional AnatomyFile description
%    - SubType  : Optional string
%                 Type 'volume',  possible SubTypes: 'Image', 'Atlas'
%                 Type 'surface', possible SubTypes: 'Cortex', 'Scalp', 'InnerSkull', 'OuterSkull', 'Fibers', 'FEM', 'Other'
%
% OUTPUT:
%    - iAnatomyFile : ID of the AnatomyFile that was created

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

% Volume or Surface
fileType = file_gettype(FileName);
switch fileType
    % Volume : image, altas
    case 'subjectimage'
        anatFileType = 'volume';
    % Surface : cortex, scalp, outerskull, innerskull, fibers, fem, tess
    case {'cortex', 'scalp', 'outerskull', 'innerskull', 'fibers', 'fem', 'tess'}
        anatFileType = 'surface';
    otherwise
        bst_error('Type of AnatomyFile is not supported')
end

% If comment is not defined : extract it from file
if (nargin < 3) || isempty(Comment)
    sMat = load(file_fullpath(FileName), 'Comment');
    Comment = sMat.Comment;
end

% If SubType is not defined : detect it
if (nargin < 4) || isempty(SubType)
    % Get volume surface type from file
    switch fileType
        % Volumes
        case 'subjectimage'
            SubType = 'Image';
            if ~isempty(strfind(FileName, '_volatlas')) || ~isempty(strfind(FileName, '_tissues'))
                SubType = 'Atlas';
            elseif ~isempty(strfind(FileName, '_volct'))
                SubType = 'CT';
            elseif ~isempty(strfind(FileName, '_volpet'))
                SubType = 'PET';
            end
        % Surface
        case 'cortex',       SubType = 'Cortex';
        case 'scalp',        SubType = 'Scalp';
        case 'outerskull',   SubType = 'OuterSkull';
        case 'innerskull',   SubType = 'InnerSkull';
        case 'fibers',       SubType = 'Fibers';
        case 'fem',          SubType = 'FEM';
        otherwise,           SubType = 'Other';
    end
end

% Prepare AnatomyFile
sAnatFile = db_template('AnatomyFile');
sAnatFile.Subject = iSubject;
sAnatFile.Type = anatFileType;
sAnatFile.FileName = file_short(FileName);
sAnatFile.Comment = Comment;
sAnatFile.SubType = SubType;

% Add AnatomyFile to database
iAnatFile = db_set('AnatomyFile', sAnatFile);

% Anatomy defaults (if not 'Other' nor 'Atlas' nor 'CT' nor PET)
if ~ismember(lower(SubType), {'other', 'atlas', 'ct', 'pet'})
    if strcmpi(SubType, 'image')
        SubType = 'Anatomy';
    end
    % Set AnatFile as Default if not Default defined for its Type
    sSubject = db_get('Subject', iSubject, ['i' SubType], 'raw');
    if isempty(sSubject.(['i' SubType]))
        db_surface_default(iSubject, SubType, iAnatFile);
    end
end
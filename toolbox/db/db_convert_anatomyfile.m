function outStructs = db_convert_anatomyfile(inStructs, type)
% Bidirectional conversion between Old and New structures
%
% New to Old
% sAnatomy / sSurface = db_convert_anatomyfile(sAnatomyFile)
% 
% Old to New
% sAnatomyFile = db_convert_anatomyfile(sAnatomy, 'anatomy')
% sAnatomyFile = db_convert_anatomyfile(sSurface, 'surface')
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
% Authors: Raymundo Cassani, 2021-2022

% Validate 'type' argument
if (nargin < 2) || isempty(type)
    type = '';
end

% Output
outStructs = [];

nStructs = length(inStructs);
if nStructs < 1
    return
end 

% Verify the sense of the conversion
% New to old
if all(isfield(inStructs(1), {'Id', 'Type'}))
    % Old structures should be of the same type
    if length(unique({inStructs.Type})) == 1
        outStructs = repmat(db_template(inStructs(1).Type), 1, nStructs);
        for iStruct = 1 : nStructs
            % Common fields
            outStructs(iStruct).FileName = inStructs(iStruct).FileName;
            outStructs(iStruct).Comment  = inStructs(iStruct).Comment;
            % Extra fields
            if strcmpi(inStructs(iStruct).Type, 'surface')
                outStructs(iStruct).SurfaceType = inStructs(iStruct).SubType;
            end
        end
    end
    
% Old to new    
else 
    outStructs = repmat(db_template('AnatomyFile'), 1, nStructs);
    for iStruct = 1 : nStructs
        % Common fields
        outStructs(iStruct).FileName = inStructs(iStruct).FileName;
        outStructs(iStruct).Comment  = inStructs(iStruct).Comment;
        outStructs(iStruct).Type     = type;
        % Extra fileds
        switch lower(type)
            case 'volume'
                SubType = 'Image';
                if ~isempty(strfind(inStructs(iStruct).FileName, '_volatlas'))
                    SubType = 'Atlas';
                end
                outStructs(iStruct).SubType = SubType;
                % No extra fields
            case 'surface'
                outStructs(iStruct).SubType = inStructs(iStruct).SurfaceType;
            otherwise
                error('Unsupported input structure type');
        end
    end
end
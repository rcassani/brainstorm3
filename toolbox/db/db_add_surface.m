function [ iAnatFile ] = db_add_surface( iSubject, FileName, Comment, SurfaceType )
% DB_ADD_SURFACE: Add a surface in database and refresh tree.
%
% USAGE:  [iSurface] = db_add_surface( iSubject, FileName, Comment, SurfaceType )
%
% INPUT:
%    - iSubject    : Indice of the subject where to add the surface
%    - FileName    : Relative path to the file in which the tesselation is defined
%    - Comment     : Surface description
%    - SurfaceType : String {'Cortex', 'Scalp', 'InnerSkull', 'OuterSkull', 'Fibers', 'FEM', 'Other'}
% OUTPUT:
%    - iSurface : indice of the surface that was created in the sSubject structure

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
% Authors: Francois Tadel, 2008-2019

% If surface type is not defined : detect it
if (nargin < 4)
    SurfaceType = [];
end

% Add surface AnatomyFile to database
iAnatFile = db_add_anatomyfile(iSubject, FileName, Comment, SurfaceType);





function numElems = node_create_subject(nodeSubject, nodeRoot, sSubject, iSubject, iSearch)
% NODE_CREATE_SUBJECT: Create subject node from subject structure for anatomy view.
%
% USAGE:  node_create_subject(nodeSubject, nodeRoot, sSubject, iSubject)
%
% INPUT: 
%     - nodeSubject : BstNode object with Type 'subject' => Root of the subject subtree
%     - nodeRoot    : BstNode object, root of the whole database tree
%     - sSubject    : Brainstorm subject structure
%     - iSubject    : indice of the subject node in Brainstorm subjects list
%     - iSearch     : ID of the active DB search, or empty/0 if none
% OUTPUT:
%     - numElems    : Number of node children elements (including self) that
%                     pass the active search filter. If 0, node should be hidden

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
% Authors: Francois Tadel, 2008-2016
%          Martin Cousineau, 2019-2020

% If iSubject=0 => default subject
import org.brainstorm.tree.*;

% Parse inputs
if nargin < 4 || isempty(iSearch) || iSearch == 0
    iSearch = 0;
    % No search applied: ensure the node is added to the database
    numElems = 1;
else
    numElems = 0;
end
showParentNodes = node_show_parents(iSearch);

% Update node fields
nodeSubject.setFileName(sSubject.FileName);
nodeSubject.setItemIndex(0);
nodeSubject.setStudyIndex(iSubject);
if ~strcmpi(sSubject.Name, bst_get('DirDefaultSubject'))
    nodeSubject.setComment(sSubject.Name);
else
    nodeSubject.setComment('(Default anatomy)');
end

% Anatomy files to use : Individual or Protocol defaults
% ==== Default anatomy ====
if sSubject.UseDefaultAnat && ~strcmpi(sSubject.Name, bst_get('DirDefaultSubject'))
    nodeLink = BstNode('defaultanat', '(Default anatomy)', '', 0, 0);
    nodeSubject.add(nodeLink);

% ==== Individual anatomy ====
else
    sAnatFiles = db_get('AnatomyFilesWithSubject', iSubject);
    % Volumes: images and atlases
    volimages = sAnatFiles(strcmpi('Image', {sAnatFiles.SubType}));
    volatlas  = sAnatFiles(strcmpi('Atlas', {sAnatFiles.SubType}));
    volcts    = sAnatFiles(strcmpi('CT',    {sAnatFiles.SubType}));
    % Surfaces
    surfaces  = sAnatFiles(strcmpi('surface', {sAnatFiles.Type}));
    % Sort by Id
    [~, ixs]  = sort([volimages.Id]);
    volimages = volimages(ixs);
    [~, ixs]  = sort([volcts.Id]);
    volcts    = volcts(ixs);    
    [~, ixs]  = sort([volatlas.Id]);
    volatlas  = volatlas(ixs);
    [~, ixs]  = sort([surfaces.Id]);
    surfaces  = surfaces(ixs);
    
    % Create list of volumes: [default image, other images, atlases]
    iDefaults = sSubject.iAnatomy == [volimages.Id];
    if ~isempty(iDefaults)
        volimages = [volimages(iDefaults), volimages(~iDefaults)];
    end
    volumes = [volimages, volcts, volatlas];
    % Create and add volume nodes
    for iVolume = 1 : length(volumes)
        nodeType = 'anatomy';
        if strcmpi(volumes(iVolume).SubType, 'atlas')
            nodeType = 'volatlas';
        elseif strcmpi(volumes(iVolume).SubType, 'ct')
            nodeType = 'volct';
        end
        [nodeCreated, nodeVolume] = CreateNode(nodeType, ...
            char(volumes(iVolume).Comment), ...
            char(volumes(iVolume).FileName), ...
            volumes(iVolume).Id, iSubject, iSearch);

        if nodeCreated
            % If current item is default one
            if ismember(volumes(iVolume).Id, sSubject.iAnatomy)
                nodeVolume.setMarked(1);
            end
            if showParentNodes || isempty(nodeRoot)
                nodeSubject.add(nodeVolume);
            else
                nodeRoot.add(nodeVolume);
            end
            numElems = numElems + 1;
        end
    end

    % Sort surfaces by category
    SortedSurfaces = db_surface_sort(surfaces);
    iSorted = [SortedSurfaces.IndexScalp, SortedSurfaces.IndexOuterSkull, SortedSurfaces.IndexInnerSkull, ...
               SortedSurfaces.IndexCortex, SortedSurfaces.IndexOther, SortedSurfaces.IndexFibers, SortedSurfaces.IndexFEM];
    % Process all the surfaces
    for i = 1:length(iSorted)
        iSurface = iSorted(i);
        SurfaceType = surfaces(iSurface).SubType;
        % Create a node adapted to represent this surface
        [nodeCreated, nodeSurface] = CreateNode(lower(SurfaceType), ...
            char(surfaces(iSurface).Comment), ...
            char(surfaces(iSurface).FileName), ...
            surfaces(iSurface).Id, iSubject, iSearch);
        if nodeCreated
            % If current item is default one
            if ismember(surfaces(iSurface).Id, sSubject.(['i' SurfaceType]))
                nodeSurface.setMarked(1);
            end
            if showParentNodes || isempty(nodeRoot)
                nodeSubject.add(nodeSurface);
            else
                nodeRoot.add(nodeSurface);
            end
            numElems = numElems + 1;
        end
    end
end
end

% Create a Java object for a database node if it passes the active search
%
% Inputs:
%  - nodeType to iStudy: See BstJava's constructor
%  - iSearch: ID of the active search filter (or 0 if none)
%
% Outputs:
%  - isCreated: Whether the node was actually created (1 or 0)
%  - node: Newly created Java object for the node
function [isCreated, node] = CreateNode(nodeType, nodeComment, ...
        nodeFileName, iItem, iStudy, iSearch)
    import org.brainstorm.tree.BstNode;
    % Only create Java object is required
    [isCreated, filteredComment] = node_apply_search(iSearch, nodeType, nodeComment, nodeFileName);
    if isCreated
        node = BstNode(nodeType, filteredComment, nodeFileName, iItem, iStudy);
    else
        node = [];
    end
end

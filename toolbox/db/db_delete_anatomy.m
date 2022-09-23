function sSubject = db_delete_anatomy(iSubject, isKeepMri)
% DB_DELETE_ANATOMY: Remove all the MRI and surfaces from a subject.
%
% USAGE:  sSubject = db_delete_anatomy(iSubject, isKeepMri=0)

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
% Authors: Francois Tadel, 2017-2019

% Parse inputs
if (nargin < 2) || isempty(isKeepMri)
    isKeepMri = 0;
end

sqlConn = sql_connect();

% Delete MRIs and Surfaces
if ~isKeepMri
    db_set(sqlConn, 'AnatomyFilesWithSubject', 'Delete', iSubject);
    % Empty default anatomy
    sSubject.iAnatomy = [];
% Delete only Surfaces
else
    db_set(sqlConn, 'AnatomyFile', 'Delete', struct('Subject', iSubject, 'Type', 'surface'));
end
% Empty default surfaces
sSubject.iCortex = [];
sSubject.iScalp = [];
sSubject.iInnerSkull = [];
sSubject.iOuterSkull = [];
sSubject.iFibers = [];
sSubject.iFEM = [];

% Update Subject
db_set(sqlConn, 'Subject', sSubject, iSubject);
panel_protocols('UpdateNode', 'Subject', iSubject);

if nargout > 0
    sSubject = db_get(sqlConn, 'Subject', iSubject);
end
sql_close(sqlConn);


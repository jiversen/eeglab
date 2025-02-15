function starteeglab
% starteeglab JRI wrapper to start eeglab, to avoid its undesired
% side effects on my globals and matlab path.
% Also close-proofs the eeglab window (so can use 'close all' to close figures) and 
% repositions it as desired.

%is EEGLAB running, if so, do nothing
eegwin = findobj('tag','EEGLAB');
if ~isempty(eegwin), return; end

 global G
 Gsave = G; %somehow our global gets trashed with starting eeglab.
 fname = fullfile(tempdir,'jiglobals.mat');
 save(fname,'Gsave');



%if not, start eeglab, adjust paths, move window and make it uncloseable.
%  Window is still closeable by clicking on close button or delete(eegwin).
eeglab

 load(fname)
 global G
 G = Gsave;
 clear Gsave

refreshPaths %eeglab modifies path, make sure our custom overrides are top

%locate eeglab window
eegwin = findobj('tag','EEGLAB');

monpos = get(0,'monitorpositions');
nScreen = size(monpos,1);

%move eeglab main window to second screen
if nScreen > 1
    if ~ispc
        set(eegwin,'position', [10        1700         550         440]) %adjust for your setup
    else
        set(eegwin,'position', [66 730 382 298])
    end
end
% edge case: sometimes two screens presented as a single very wide screen in the past
ss = get(0,'ScreenSize');
if ss(3) > 2000 && nScreen == 1
  set(eegwin,'position', [  10        1700         500         400]) %adjust for your setup
end
drawnow

%make EEGLAB main widow it unclosable (good for close all)
set(eegwin,'CloseRequestFcn',@closeit);

%block closes when the 'close' command is used, but allow clicks to
%close button (solution suggested by Jan Simon)
% eeglab itself calls close to e.g. redraw or reparse plugins, so allow it
% to use close. However, this doesn't handle the close upon quit or plugin
% update, which leads to problems, because those are called from menu
% callbacks and do not put a caller into the stack :(. Solution: change
% those callbacks in eeglab.m from using close() to using delete()

function closeit(src, event)
stack = dbstack;
caller = {stack.name};
calledByClose = any(strcmp(caller,'close'));
calledByEEGLAB = any(strcmp(caller,'eeglab'));
if ~calledByClose || calledByEEGLAB
    delete(src)
end

% pos = get(src,'CurrentPoint');
% bounds = get(src,'position');
% mod = get(src,'CurrentModifier');
% jFrame = get(handle(src),'JavaFrame');
% disp('close requested')


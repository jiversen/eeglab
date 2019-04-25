function starteeglab
% starteeglab JRI wrapper to start eeglab, to avoid its undesired
% sideeffects on globals.
% Also close-proof the eeglab window (so can use 'close all' to close figures) and 
% reposition it to right screen.

 global G
 Gsave = G; %somehow our global gets trashed with starting eeglab.
 fname = fullfile(tempdir,'jiglobals.mat');
 save(fname,'Gsave');

%is EEGLAB running, if so, do nothing
eegwin = findobj('tag','EEGLAB');
if ~isempty(eegwin), return; end

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
   set(eegwin,'position', [2062 804 382 298]) %adjust for your setup
end
%sometimes two screens present as a single very wide screens
ss = get(0,'ScreenSize');
if ss(3) > 2000
  set(eegwin,'position', [ 2066        860        400          236]) %adjust for your setup
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


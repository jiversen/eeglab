function [num,status,strarray] = str2double(s,cdelim,rdelim,ddelim)
%% STR2DOUBLE converts strings into numeric values
%%  [NUM, STATUS,STRARRAY] = STR2DOUBLE(STR) 
%%  
%%  STR2DOUBLE can replace STR2NUM, but avoids the insecure use of EVAL 
%%  on unknown data [1]. 
%%
%%    STR can be the form '[+-]d[.]dd[[eE][+-]ddd]' 
%%	d can be any of digit from 0 to 9, [] indicate optional elements
%%    NUM is the corresponding numeric value. 
%%       if the conversion fails, status is -1 and NUM is NaN.  
%%    STATUS = 0: conversion was successful
%%    STATUS = -1: couldnot convert string into numeric value
%%    STRARRAY is a cell array of strings. 
%%
%%    Elements which are not defined or not valid return NaN and 
%%        the STATUS becomes -1 
%%    STR can be also a character array or a cell array of strings.   
%%        Then, NUM and STATUS return matrices of appropriate size. 
%%
%%    STR can also contain multiple elements.
%%    default row-delimiters are: 
%%        NEWLINE, CARRIAGE RETURN and SEMICOLON i.e. ASCII 10, 13 and 59. 
%%    default column-delimiters are: 
%%        TAB, SPACE and COMMA i.e. ASCII 9, 32, and 44.
%%    default decimal delimiter is '.' char(46), sometimes (e.g in 
%%	Tab-delimited text files generated by Excel export in Europe)  
%%	might used ',' as decimal delimiter.
%%
%%  [NUM, STATUS] = STR2DOUBLE(STR,CDELIM,RDELIM,DDELIM) 
%%       CDELIM .. [OPTIONAL] user-specified column delimiter
%%       RDELIM .. [OPTIONAL] user-specified row delimiter
%%       DDELIM .. [OPTIONAL] user-specified decimal delimiter
%%       CDELIM, RDELIM and DDELIM must contain only 
%%       NULL, NEWLINE, CARRIAGE RETURN, SEMICOLON, COLON, SLASH, TAB, SPACE, COMMA, or ()[]{}  
%%       i.e. ASCII 0,9,10,11,12,13,14,32,33,34,40,41,44,47,58,59,91,93,123,124,125 
%%
%%    Examples: 
%%	str2double('-.1e-5')
%%	   ans = -1.0000e-006
%%
%% 	str2double('.314e1, 44.44e-1, .7; -1e+1')
%%	ans =
%%	    3.1400    4.4440    0.7000
%%	  -10.0000       NaN       NaN
%%
%%	line ='200,300,400,NaN,-inf,cd,yes,no,999,maybe,NaN';
%%	[x,status]=str2double(line)
%%	x =
%%	   200   300   400   NaN  -Inf   NaN   NaN   NaN   999   NaN   NaN
%%	status =
%%	    0     0     0     0     0    -1    -1    -1     0    -1     0
%%
%% Reference(s): 
%% [1] David A. Wheeler, Secure Programming for Linux and Unix HOWTO.
%%    http://en.tldp.org/HOWTO/Secure-Programs-HOWTO/

%% This program is free software; you can redistribute it and/or
%% modify it under the terms of the GNU General Public License
%% as published by the Free Software Foundation; either version 2
%% of the License, or (at your option) any later version.
%% 
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

%%	$Revision: 1.1 $
%%	$Id: str2double.m,v 1.1 2009-01-30 06:04:42 arno Exp $
%%	Copyright (C) 2004,2008 by Alois Schloegl <a.schloegl@ieee.org>	
%%      This function is part of Octave-Forge http://octave.sourceforge.net/

FLAG_OCTAVE = exist('OCTAVE_VERSION','builtin');
VER = version; 

% valid_char = '0123456789eE+-.nNaAiIfF';	% digits, sign, exponent,NaN,Inf
valid_delim = char(sort([0,9:14,32:34,abs('()[]{},;:"|/')]));	% valid delimiter
if nargin < 1,
        error('missing input argument.')
end;
if nargin < 2,
        cdelim = char([9,32,abs(',')]);		% column delimiter
else
        % make unique cdelim
        cdelim = char(sort(cdelim(:)));
        tmp = [1;1+find(diff(abs(cdelim))>0)];
        cdelim = cdelim(tmp)';
end;
if nargin < 3,
        rdelim = char([0,10,13,abs(';')]);	% row delimiter
else
        % make unique rdelim
        rdelim = char(sort(rdelim(:)));
        tmp = [1;1+find(diff(abs(rdelim))>0)];
        rdelim = rdelim(tmp)';
end;
if nargin<4,
        ddelim = '.';
elseif length(ddelim)~=1,
        error('decimal delimiter must be exactly one character.');
end;

% check if RDELIM and CDELIM are distinct
delim = sort(abs([cdelim,rdelim,ddelim]));
tmp   = [1; 1 + find(diff(delim')>0)]';
delim = delim(tmp);
%[length(delim),length(cdelim),length(rdelim)]
if length(delim) < (length(cdelim)+length(rdelim))+1, % length(ddelim) must be one.
        error('row, column and decimal delimiter are not distinct.');
end;

% check if delimiters are valid
tmp  = sort(abs([cdelim,rdelim]));
flag = zeros(size(tmp));
k1 = 1;
k2 = 1;
while (k1 <= length(tmp)) & (k2 <= length(valid_delim)),
        if tmp(k1) == valid_delim(k2),            
                flag(k1) = 1; 
                k1 = k1 + 1;
        elseif tmp(k1) < valid_delim(k2),            
                k1 = k1 + 1;
        elseif tmp(k1) > valid_delim(k2),            
                k2 = k2 + 1;
        end;
end;
if ~all(flag),
        error('Invalid delimiters!');
end;

%%%%% various input parameters 
if isnumeric(s) 
	if all(s<256) & all(s>=0)
    	        s = char(s);
	else
		error('STR2DOUBLE: input variable must be a string')
	end;
end;

num = [];
status = 0;
strarray = {};
if isempty(s),
        return;

elseif iscell(s),
        strarray = s;

elseif ischar(s) 
if 	all(size(s)>1),	%% char array transformed into a string. 
	for k = 1:size(s,1), 
                tmp = find(~isspace(s(k,:)));
                strarray{k,1} = s(k,min(tmp):max(tmp));
        end;

else %if isschar(s),
        num = [];
        status = 0;
        strarray = {};

        s(end+1) = rdelim(1);     % add stop sign; makes sure last digit is not skipped

	RD = zeros(size(s));
	for k = 1:length(rdelim),
		RD = RD | (s==rdelim(k));
	end;
	CD = RD;
	for k = 1:length(cdelim),
		CD = CD | (s==cdelim(k));
	end;
        
        k1 = 1; % current row
        k2 = 0; % current column
        k3 = 0; % current element
        
        sl = length(s);
        ix = 1;
        %while (ix < sl) & any(abs(s(ix))==[rdelim,cdelim]),
        while (ix < sl) & CD(ix), 
                ix = ix + 1;
        end;
        ta = ix; te = [];
        while ix <= sl;
                if (ix == sl),
                        te = sl;
                end;
                %if any(abs(s(ix))==[cdelim(1),rdelim(1)]),
                if CD(ix), 
                        te = ix - 1;
                end;
                if ~isempty(te),
                        k2 = k2 + 1;
                        k3 = k3 + 1;
                        if te<ta,
	                        strarray{k1,k2} = [];
	                else        
	                        strarray{k1,k2} = s(ta:te);
	                end;        
                        %strarray{k1,k2} = [ta,te];
                        
                        flag = 0;
                        %while any(abs(s(ix))==[cdelim(1),rdelim(1)]) & (ix < sl),
                        while CD(ix) & (ix < sl),
                                flag = flag | RD(ix);
                                ix = ix + 1;
                        end;
                        
                        if flag, 
                                k2 = 0;
                                k1 = k1 + 1;
                        end;
                        ta = ix;
                        te = [];
	        end;
                ix = ix + 1;
        end;
end; 
else
        error('STR2DOUBLE: invalid input argument');
end;

[nr,nc]= size(strarray);
status = zeros(nr,nc);
num    = repmat(NaN,nr,nc);

for k1 = 1:nr,
for k2 = 1:nc,
        t = strarray{k1,k2};
        if (length(t)==0),
		status(k1,k2) = -1;		%% return error code
                num(k1,k2) = NaN;
        else 
                %% get mantisse
                g = 0;
                v = 1;
                if t(1)=='-',
                        v = -1; 
                        l = min(2,length(t));
                elseif t(1)=='+',
                        l = min(2,length(t));
                else
                        l = 1;
                end;

                if strcmp(lower(t(l:end)),'inf')
                        num(k1,k2) = v*inf;
                        
                elseif strcmp(lower(t(l:end)),'nan');
                        num(k1,k2) = NaN;
                        
                else
			if ddelim=='.',
				t(t==ddelim)='.';
			end;	
			if FLAG_OCTAVE,		%% Octave
	    			[v,tmp2,c] = sscanf(char(t),'%f %s','C');
	    		elseif all(VER(1:2)=='3.') & any(VER(3)=='567');  %% FreeMat 3.5, 3.6, 3.7
				[v,c,em] = sscanf(char(t),'%f %s');
				c = 1;
	    		else	%% Matlab 
				[v,c,em,ni] = sscanf(char(t),'%f %s');
				c = c * (ni>length(t));
			end;
			if (c==1),
	            		num(k1,k2) = v;
			else
	            		num(k1,k2) = NaN;
	            		status(k1,k2) = -1;
			end			
		end
	end;
end;
end;        


function s = readErmaReport(filename)
%READERMAREPORT	read a text file produced by ERMA and uploaded from the glider
%
%   Syntax:
%       readErmaReport(filename)
%
%   Description:
%       Read the detection report in file 'filename' that was produced by 
%       the ErmaMain C code and then uploaded from the glider, unzipped, 
%       and cleaned up.
%
%       enc.t_D doesn't necessarily have all nClicks times in the
%       encounter, just all the click times that got uploaded. Some can get
%       omitted from the upload because of space limitations. But the total
%       click count enc.nClicks includes both the uploaded ones and the 
%       omitted ones.
%   
%       The number of encounters in this dive is length(s.enc).
%       The number of uploaded clicks in encounter i is length(s.enc(i).t_D).
%
%   Inputs:
%       filename  [string] fullfile filename to ws****az detection file
%
%   Outputs:
%       s         [struct] with these fields:
%                    t0_D      [scalar] start-time of the time period 
%                              analyzed (datenum fmt)
%                    t1_D      [scalar] end-time of the time period  
%                              analyzed (datenum fmt)
%                    procTimeS [scalar] number of seconds it took to  
%                              process the data and produce this file
%                    enc       [1xM struct array] a series of structs, one 
%                              per encounter, with these fields:
%                                 encT0_D  [scalar] start-time of the 
%                                          encounter (datenum fmt)
%                                 encT1_D  [scalar] end-time of the 
%                                          encounter (datenum fmt)
%                                 nClicks  [scalar] total number of clicks 
%                                          in the encounter
%                                 t_D      [1xN] times of (some of the) 
%                                          clicks in this encounter 
%                                          (datenum format)
%
%   Examples:
%       dets = readErmaReport(ermaReportPath);
%
%   See also PLOTERMADETECTIONS
%
%   Authors:
%       D. Mellinger <David.Mellinger@oregonstate.edu> <https://github.com/DMellinger>
%
%   First Version:   09 May 2023
%   Updated:	     22 May 2023
%
%   Created with MATLAB ver. 9.13.0.2049777 (R2022b)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fp = fopen(filename, 'r');
if (fp < 0)
  error('Can''t open detection report file "%s"', filename);
end

s = struct('enc', struct('nClicks', {}));	% field 'enc' has length 0
while (1)
  ln = fgetl(fp);
  if (~ischar(ln))			% end of file?
    fclose(fp);
    return
  end

  % Remove ^M characters, which get inserted somehow.
  ln(ln == 13) = '';
  % Remove WISPR 'W>' prompts.
  if (length(ln) >= 2 && strcmp(ln(end-1 : end), 'W>'))
    ln = ln(1 : end-2);
  end
  % Split x into its separate pieces delimited by ',' characters.
  x = strsplit(ln, ',', 'CollapseDelimiters', false);
  if (length(x) < 1), continue; end

  % Parse the various types of lines.
  switch(x{1})
    case '$analyzed'
      if (length(x) >= 3)
	s.t0_D = datenum(x{2}, 'yymmdd-HHMMSS');  
	s.t1_D = datenum(x{3}, 'yymmdd-HHMMSS');
      end
    case '$enc'
      if (length(x) >= 4)
	ix = length(s.enc) + 1;
	s.enc(ix).encT0_D = datenum(x{2}, 'yymmdd-HHMMSS');
	s.enc(ix).encT1_D = datenum(x{3}, 'yymmdd-HHMMSS');
	s.enc(ix).nClicks = str2double(x{4});
	t_S = str2double(x(5:end));
	s.enc(ix).t_D = s.enc(ix).encT0_D + t_S / (24*60*60);
      end
    case '$processtimesec'
      if (length(x) >= 2)
	s.procTimeS = str2double(x{2});
      end
  end	% switch
end	% while(1)

%#ok<*DATNM>

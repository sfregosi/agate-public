%
% matlab script to fix gain jump between data files in a directoy
%
% Loop over a set of file in a directory and compare the data (of length nbufs)
% at the end of the first file with data at the beginning of the second file.
% Determine a gain change by comparing the spectrum of each data segment
% within a range of freqs [f1 f2].
% Change the freq range by entering new values when prompted.
% Enter the new freq range as a vector, for example [50000 60000]
%
% Apply the gain, which should be a factor of 1 (no gain change) or 2
% for a 6 dB change between the base noise levels of the files.
%
% The adjusted data is saved in wav file format, leaving the .dat files unchanged.
%
%
% A .dat data file consists of an ascii file header followed by binary data
% buffers. The ascii header is formatted as matlab expressions.
% The binary data words are formatted as signed 16 or 24 bit integers.
%
% The data file format is:
% - 512 byte ascii header.
% - adc buffer 1
% - adc buffer 2
% ...
% - adc buffer N
% where N is the number of adc buffers per file
%
% The number of adc buffers is defined as
% number_buffers = file_size*512 / buffer_size;
%
% The total data file size is always a multiple of 512 bytes blocks.
% The variable 'file_size' is the number of 512 blocks in the file.
%
% Each adc buffer is of length 'buffer_size' bytes.
% The adc buffer is always a multiple of 512 bytes blocks (32 blocks in most cases).
% Each adc buffer contains a fixed number of sample (samples_per_buffer).
% Each sample is of fixed size in bytes (sample_size).
% The sample size can be 2 or 3.
% If 3 byte samples are used, there will be extra bytes of padded at the end of each adc buffer.
% The number of bytes of padding is defined as:
% padding_per_buffer = buffer_size - (samples_per_buffer * sample_size);
%
% cjones 10/2023
%
% s. fregosi 2023-11-02

clear all;
verbose = true; % or can be false to print less messages/be more automated

% set paths
path_out = 'D:\sg679_MHI_May2023\gainFixTest3';
% path_dat = uigetdir('D:\');
path_dat = 'D:\sg679_MHI_May2023\gainFixTest3\raw';
path_wav = fullfile(path_out, 'wav');

% set up log file
fid = fopen(fullfile(path_out, 'gainFix.log'), 'a');
if fid == -1
	error('Cannot open log file.');
end
fprintf(fid, '%s: %s\n', datestr(now, 0), 'Beginning gain fix process...');

% pick a data directory with the .dat file.
% directoryname ='.';
% directoryname = uigetdir(directoryname);
directoryname = path_dat;
files = dir([directoryname '\*.dat']);
nfiles = size(files, 1);
fprintf(fid, '%i %s\n', nfiles, 'total .dat files to process');

%R = input('Enter decimation factor [1]: ');
%if(isempty(R))
%    R = 1;
%end

adc_vref = 5.0;  % reference voltage of the adc (max voltage)

% number of data buffer to compare
nbufs = 64;

% don't compare data above this amplitude threshold
% set this value to eleminate spikes
max_thresh = 1.0;

% spectrum parameters
fft_size = 128;
win = hamming(fft_size)*1.59; %multiply energy correction
%window = hann(fft_size)*1.63;
overlap = fft_size/2;

% freq range (Hz) to compare spectra
f1 = 60000;
f2 = 70000;

first_file = 1;

fprintf(fid, 'Starting with file: %s\n', files(1).name);

% read the first file in the directory
file1 = files(1).name;
name1 = fullfile(directoryname,files(1).name);
% read just to get header info
[nrd1, hdr1, data1, time1] = read_wispr_file(name1, 1, 0);
% get num_bufs
% N = hdr.file_size * 512 / hdr.buffer_size;
% read
% [nrd, hdr1, data1, time1] = read_wispr_file(name1, 1, N);

% remove all zero bufs - only keep everything up to nrd
data1 = data1(:, 1:nrd1);
time1 = time1(:, 1:nrd1);

% % save data in wav file
% wavfile1 = [name1(1:end-3) 'wav'];
% audiowrite(wavfile1, data1(:)/5.0, hdr1.sampling_rate, 'BitsPerSample', 24);

% loop over files in directory
for m = 2:(nfiles-1)

	if files(m).isdir
		continue;
	end

	% read the next file
	file2 = files(m).name;
	name2 = fullfile(directoryname,files(m).name);

	fprintf(fid, 'Comparing file %s and %s\n', file1, file2);

	[nrd2, hdr2, data2, time2] = read_wispr_file(name2, 1, 0);
	% remove zeros
	data2 = data2(:, 1:nrd2);
	time2 = time2(:, 1:nrd2);

	% find a section of the data at the end of the first file (sig1)
	% and the start of he second file (sig2)
	sig1 = data1(:,nrd1-nbufs+1:nrd1); % end of data1
	sig2 = data2(:,1:nbufs); % beginning of data2

	t1 = time1(:,nrd1-nbufs+1:nrd1) - max(max(time1));
	t2 = time2(:,1:nbufs) - min(min(time2));

	if nrd2 < nrd1
		if verbose
			fprintf('Looks like %s is truncated: nrd is %d not %d\n', ...
				files(m).name, nrd2, nrd1);
		end
	end

	if nrd2 < nbufs
		fprintf(fid, 'Not enough data in %s, continue to next file\n', ...
			files(m).name);
		continue;
	end

	% plot the data segments
	figure(1); clf;
	subplot(2,1,1);
	plot(t1(:), sig1(:), t2(:), sig2(:));
	ylabel('Volts');
	title('Original data');

% find the rms and max of the data segments
	rms1 = sqrt(mean(sig1.^2));
	rms2 = sqrt(mean(sig2.^2));
	max1 = max(abs(sig1));
	max2 = max(abs(sig2));

	% try to ignore the spikes in the data by thresholding
	i1 = find(abs(max1) < max_thresh);
	i2 = find(abs(max2) < max_thresh);

	if isempty(i1)
		while isempty(i1) % all sig1 is above threshold
			% try increasing threshold
			max_thresh = max_thresh + 1;
			fprintf(fid, 'Increasing max_thresh = %i\n', max_thresh);
			% try to ignore the spikes in the data
			i1 = find(abs(max1) < max_thresh);
			i2 = find(abs(max2) < max_thresh);
			% 	   break;
		end
	end

	% alternative could skip if nothing below threshold... but don't think
	% this is valid approach. 
	    % if there's nothing below the threshold then the pumps are probably on
	   % so skip this file and proceed to the next file
%     if( isempty(i1) || isempty(i2) )
%         data1 = data2;
%         time1 = time2;
%         name1 = name2;
%         file1 = file2;
%         nrd1 = nrd2;
%         fprintf('Skipping file %s and %s - no signal below threshold\n', file1, file2);
%         continue;
%     end
%     
% 	

% 	fprintf(fid, 'Comparing file %s and %s for gain change\n', file1, file2);
	% Calc spectrum of data
	fs = hdr1.sampling_rate;
	[spec1, freq1] = my_psd(sig1(:,i1), fs, win, overlap, t1(1));
	[spec2, freq2] = my_psd(sig2(:,i2), fs, win, overlap, t2(1));

	figure(2); clf
	subplot(2,1,1);
	plot(mean(t1(:,i1)), rms1(i1), '.', mean(t2(:,i2)), rms2(i2), '.');
	%semilogx(freq1/1000, 10*log10(spec1), '.-', freq2/1000, 10*log10(spec2), '.-'); %normalize the power spec
	%plot(freq1/1000, 10*log10(spec1), '.-', freq2/1000, 10*log10(spec2), '.-'); %normalize the power spec
	xlabel('Seconds');
	ylabel('RMS');
	subplot(2,1,2);
	plot(freq1/1000, 10*log10(spec1), '.-', freq2/1000, 10*log10(spec2), '.-'); %normalize the power spec
	xlabel('Frequency [kHz]');
	ylabel('dB');
	legend('First file', 'Second file');

	%gain = round(rms2/rms1)

	% compare the spectrum in the specified freq range to determine gain
	% gain is applied to the second file
	str = sprintf('Enter freq range to compare [%d %d]: ', f1, f2);
	in = input(str);
	if (~isempty(in))
		f1 = in(1);
		f2 = in(2);
	end
	ig = find((freq1 > f1) & (freq2 < f2));
	db_gain = 10*log10(mean(spec2(ig) ./ spec1(ig)));
	gain = (10.^(db_gain/20));
	fprintf('Gain adjustment for second file based on spectrum is %.1f\n', gain);
	if( gain < 1)
		gain = round(gain*2)/2; % if gain < 1
	else
		gain = round(gain);
	end

	% if gain is less than 1 then the first file needs adjustment
	% this should only happen on the the first file in the directory
	if(gain < 1)
		% adjust and resave data1 in wav file
		fprintf('Applying gain adjustment of %.1f to the first file\n', gain);
		data1 = gain* data1;
		dat1 = gain * dat1;
		wavfile1 = [name1(1:end-3) 'wav'];
		audiowrite(wavfile1, data1(:)/(adc_vref), hdr1.sampling_rate, 'BitsPerSample', 24)
		gain = 1;
		%figure(1);
		%subplot(2,1,1);
		%plot(t1, dat1, t2, dat2);
		%ylabel('Volts');
		%xlabel('Seconds');
		%title('New data');
	end

	% prompt to verify gain
	str = sprintf('Enter gain adjustment to apply to second file [%.1f]: ', gain);
	in = input(str);
	if( ~isempty(in))
		gain = in;
	end;

	figure(1);
	subplot(3,1,3);
	dat2 = dat2/gain;
	plot(t1(:), dat1(:), t2(:), dat2(:));
	ylabel('Volts');
	xlabel('Seconds');
	title('Equalized data');

	% adjust and save data2 in wav file
	data2 = data2/gain;
	wavfile2 = [name2(1:end-3) 'wav'];
	audiowrite(wavfile2, data2(:)/(adc_vref), hdr2.sampling_rate, 'BitsPerSample', 24);

	data1 = data2;
	time1 = time2;
	name1 = name2;
	file1 = file2;

	if(input('quit [0]: ') == 1)
		break;
	end;

end

% close log
fclose(fid);

return;

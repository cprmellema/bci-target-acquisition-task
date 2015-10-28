%%%%%%%%%%%%%%%%%%%
%filterfrequency.m%
%%%%%%%%%%%%%%%%%%%

%Code to see how fitting performs on GLMs generated from known filters on different stimulus
%statistics. With actual stimulus data whose time scales are varied and used to generated spike trains
%From these GLMs we compare the quality of the fit to the frequency content of the filters

fn_out = './worksheets/10_22_2014/data_freq.mat';
N = 20000;
binsize = 0.002;
dur = N*binsize;
dt_sp = binsize;
dt_pos = binsize;
seed = 1000000;
const = 'on';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Make up 10 filters. They'll have a common spike history filter, and varying stimulus strengths
%Change the constant term such that they each have the same average firing rate

%Filters
nK_sp = 100;
nK_pos = 200;
nAlpha = 10;
target_nsp = 1000;
k_const_guess = -5;

%Spike history filter
t_sp = linspace(0,1,nK_sp);
k_sp = -0.1*exp(-50*t_sp);
k_sp = fliplr(k_sp);
%Base stim filter that will be scaled below
t_pos = linspace(0,1,nK_pos);
k_RU = -1.0*exp(-6*t_pos);
k_FE = 0.5*exp(-5*t_pos);

%Factors to scale stim content by
alphas = [1 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1];
k_const = zeros(nAlpha,1);

nevfile = './testdata/20130117SpankyUtah001.nev';
threshold = 5; offset = 0;
pre = preprocess(nevfile, binsize, threshold, offset);
%Truncate to only one unit
idx = 9;
pre.binnedspikes = pre.binnedspikes(:,idx);
pre.rates = pre.rates(:,idx);              
pre.unitnames = pre.unitnames(idx);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Generate spike train data with these filters and actual stimulus data as input
%Tweak the constant term so that the average firing rate is about what is seen in the actual data sets

%Fit filters of different lengths/resolution to this data
nK_poss = [2 5 10 20 50];
dt_poss = binsize*200./nK_poss;

processed = {};
%Determine how to set constant rate from train with the same filters
for idx = 1:nAlpha
	idx
	alpha = alphas(idx);
	%Resample input data at rate given by alpha
	p = pre;
	p.torque = [];
	p.torque(:,1) = resample(pre.torque(:,1),alpha*10,10);
	p.torque(:,2) = resample(pre.torque(:,2),alpha*10,10);	
	%Simulate GLM with filters wanted but constant term left at a guess value
	p = generate_glm_data_torque(pre, k_const_guess, k_sp, k_RU, k_FE, dt_sp, dt_pos, N, binsize);
	%Count number of spikes
	nspikes1 = sum(p.binnedspikes);
	%Estimate constant to produce wanted average firing rates
	k_const(idx) = k_const_guess+log(target_nsp/nspikes1);
	%Redo with estimated constant values
	processed{idx} = generate_glm_data_torque(pre, k_const(idx), k_sp, k_RU, k_FE, dt_sp, dt_pos, N, binsize);
	%Check that total number of spikes is around the same...
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Can start from here by loading fn_out, as just saved above
fn_out = './worksheets/10_22_2014/data_freq.mat';
save(fn_out);

fn_out = './worksheets/10_22_2014/data_freq.mat';
load(fn_out);

%Compute auto-correlation for the two torque channels (within 3s)
maxlag = 4/dt_sp;

devs_IRLS = zeros(nAlpha, length(nK_poss));
devs_SD = zeros(nAlpha, length(nK_poss));

g = figure;
h = figure;
for i = 1:nAlpha
	i
	figure(g);
	clf;
	figure(h);
	clf;
	alpha = alphas(i)
	for j = 1:length(nK_poss);
		%set dt_pos accordingly
		dt_pos = dt_poss(j);
		nK_pos = nK_poss(j);
		%for each resolution generate the data structure
		data = filters_sp_pos(processed{i}, nK_sp, nK_pos, dt_sp, dt_pos);
		%Takes a long time... will run later
		%model_SD = MLE_SD(data, const);
		model_IRLS = MLE_glmfit(data, const);
		%Compute the deviance
		%devs_SD(i,j) = deviance(model_SD, data);
		devs_IRLS(i,j) = deviance(model_IRLS, data);
		%Plot the filters estimated for each
		fn_out2 = ['./worksheets/10_22_2014/freqplots/filterstrengths_freq_alpha_' num2str(alphas(i)) '_dtpos_' num2str(dt_pos)];
		%plot_filters(model_SD, data, processed{i}, [fn_out2 '_fminunc'])
		plot_filters(model_IRLS, data, processed{i}, [fn_out2 '_IRLS'])
		IRLS_const = model_IRLS.b_hat(1);
		for k = 1:size(data.k,1)
			%Plot the estimated filters
			name = data.k{k,1};
			filt = model_IRLS.b_hat(data.k{k,2}+1);
			if k == 1
				dt = dt_sp;
			else
				%rescale filter because of different time scales
				dt = dt_pos;
				filt = filt*dt_sp/dt_pos;
			end
			figure(g);
			subplot(3,1,k)
			hold on
			plot((0:length(filt)-1)*dt, filt, 'Color', [1 0.5 0.5])  
			plot((0:length(filt)-1)*dt, filt, 'r.')  
			title(name);
			figure(h);
			subplot(3,4,(4*(k-1)+(1:3)))
			hold on
			NFFT = 2^nextpow2(length(filt)); % Next power of 2 from length of y
			Fs = 1/dt;
			Y = fft(filt,NFFT)/length(filt);
			f = Fs/2*linspace(0,1,NFFT/2+1);
			% Plot single-sided amplitude spectrum.
			plot(f,2*abs(Y(1:NFFT/2+1)), 'Color', [1 0.5 0.5])
			plot(f,2*abs(Y(1:NFFT/2+1)), 'r.')
			title(name);
		end
	end
	p.torque = [];
	p.torque(:,1) = resample(pre.torque(:,1),alpha*10,10);
	p.torque(:,2) = resample(pre.torque(:,2),alpha*10,10);	
	autocorrRU = xcorr(p.torque(:,1), maxlag);
	autocorrFE = xcorr(p.torque(:,2), maxlag);

	%Plot the actual filters
	figure(g);
	subplot(3,1,1)
	title({['Fit filters. \alpha = ' num2str(alpha)];['spike history filter']})
	hold on
	plot((0:length(k_sp)-1)*binsize, k_sp, 'b', 'LineWidth', 1)
	subplot(3,1,2)
	hold on
	plot((0:length(k_RU)-1)*binsize, k_RU, 'b', 'LineWidth', 1);
	subplot(3,1,3)
	hold on
	plot((0:length(k_FE)-1)*binsize, k_FE, 'b', 'LineWidth', 1);
	xlabel('time (s)')
	fn_out3 = ['./worksheets/10_22_2014/freqplots/filterstrengths_freq_alpha_' num2str(alphas(i)) '.eps'];
	saveplot(gcf, fn_out3, 'eps', [9 6]);

	%Plot the actual filters in fourier domain
	figure(h);
	subplot(3,4,[1 2 3])
	title({['Fourier transform of fit filters. \alpha = ' num2str(alpha)];['spike history filter']})
	hold on
	NFFT = 2^nextpow2(length(k_sp)); % Next power of 2 from length of y
	Fs = 1/dt_sp;
	Y = fft(k_sp,NFFT)/length(k_sp);
	f = Fs/2*linspace(0,1,NFFT/2+1);
	plot(f,2*abs(Y(1:NFFT/2+1)), 'b')
	ylabel('|\beta(k)|')
	subplot(3,4,[5 6 7])
	hold on
	Y = fft(k_RU,NFFT)/length(k_sp);
	plot(f,2*abs(Y(1:NFFT/2+1)), 'b')
	ylabel('|\beta(k)|')
	subplot(3,4,[9 10 11])
	hold on
	Y = fft(k_FE,NFFT)/length(k_sp);
	plot(f,2*abs(Y(1:NFFT/2+1)), 'b')
	ylabel('|\beta(k)|')
	xlabel('Freq (Hz)')
	subplot(3,4,8)
	tt = ((1:length(autocorrRU))-length(autocorrRU)/2)*dt_sp;
	plot(tt,autocorrRU)
	title('Auto-correlation RU')
	subplot(3,4,12)
	plot(tt,autocorrFE)
	title('Auto-correlation FE')
	xlabel('time(s)')
	fn_out3 = ['./worksheets/10_22_2014/freqplots/filterstrengths_freq_alpha_' num2str(alphas(i)) '_fourier.eps'];
	saveplot(gcf, fn_out3, 'eps', [9 6]);
end
%Save the outcome of all the above
save(fn_out);
%fn_out = './worksheets/10_22_2014/data_freq.mat';
%load(fn_out);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Make a plot of the deviance as a function of params
clf
imagesc(devs_IRLS)
title('Deviance as function of filter resolution and stimulus statistics')
xlabel('resolution (s)')
ylabel('alpha')
%set(gca,'XTick',1:size(S,1));
set(gca,'XTickLabel',dt_poss);
%set(gca,'YTick',1:size(S,2));
set(gca,'YTickLabel',alphas);
colorbar
saveplot(gcf, './worksheets/10_22_2014/freqplots/filterstrengths_freq_dev.eps')


%%%%%%%%%%%%%%%
%filter_real.m%
%%%%%%%%%%%%%%%

%See how filters look on actual dataset
%Plot spatial filters as a function of resolution (for IRLS and fminunc)
%Plot likelihood (and AIC and BIC) as a function of resolution

fn_out = './worksheets/10_27_2014/data.mat';
N = 200000;
binsize = 0.002;
dur = N*binsize;
dt_sp = binsize;
nK_sp = 100;
filterlen = 500;
seed = 1000000;
const = 'on';

%Fit filters of different lengths/resolution to this data
nK_poss = [2 5 10 20 50];
dt_poss = binsize*filterlen./nK_poss;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nevfile = './testdata/20130117SpankyUtah001.nev';
threshold = 5; offset = 0;
pre = preprocess(nevfile, binsize, threshold, offset);
%Truncate to only one unit
idx = 9;
pre.binnedspikes = pre.binnedspikes(:,idx);
pre.rates = pre.rates(:,idx);              
pre.unitnames = pre.unitnames(idx);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Can start from here by loading fn_out, as just saved above
fn_out = './worksheets/10_27_2014/data.mat';
save(fn_out);

fn_out = './worksheets/10_27_2014/data.mat';
load(fn_out);

%Compute auto-correlation for the two torque channels (within 3s)
maxlag = 4/dt_sp;

devs_IRLS = zeros(size(nK_poss));
devs_SD = zeros(size(nK_poss));

g = figure;clf
h = figure;clf
%Fit different filters for different timebin sizes
for j = 1:length(nK_poss);
	%set dt_pos accordingly
	dt_pos = dt_poss(j);
	nK_pos = nK_poss(j);
	%for each resolution generate the data structure
	data = filters_sp_pos(pre, nK_sp, nK_pos, dt_sp, dt_pos);
	%Takes a long time... will run later
	%model_SD = MLE_SD(data, const);
	model_IRLS = MLE_glmfit(data, const);
	%Compute the deviance
	%devs_SD(j) = deviance(model_SD, data);
	devs_IRLS(j) = deviance(model_IRLS, data);
	%Plot the filters estimated for each
	fn_out2 = ['./worksheets/10_27_2014/plots/filters_dtpos_' num2str(dt_pos)];
	%plot_filters(model_SD, data, pre, [fn_out2 '_fminunc'])
	plot_filters(model_IRLS, data, pre, [fn_out2 '_IRLS'])
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
autocorrRU = xcorr(pre.torque(:,1), maxlag);
autocorrFE = xcorr(pre.torque(:,2), maxlag);
%Plot the actual filters
figure(g);
subplot(3,1,1)
title({['Fit filters.'];['spike history filter']})
hold on
subplot(3,1,2)
hold on
subplot(3,1,3)
hold on
xlabel('time (s)')
fn_out3 = ['./worksheets/10_27_2014/plots/filters.eps'];
saveplot(gcf, fn_out3, 'eps', [9 6]);
%Plot the actual filters in fourier domain
figure(h);
subplot(3,4,[1 2 3])
title({['Fourier transform of fit filters.'];['spike history filter']})
hold on
ylabel('|\beta (k)|')
subplot(3,4,[5 6 7])
hold on
ylabel('|\beta (k)|')
subplot(3,4,[9 10 11])
hold on
ylabel('|\beta (k)|')
xlabel('Freq (Hz)')
subplot(3,4,8)
tt = ((1:length(autocorrRU))-length(autocorrRU)/2)*dt_sp;
plot(tt,autocorrRU)
title('Auto-correlation RU')
subplot(3,4,12)
plot(tt,autocorrFE)
title('Auto-correlation FE')
xlabel('time(s)')
fn_out3 = ['./worksheets/10_27_2014/plots/filters_fourier.eps'];
saveplot(gcf, fn_out3, 'eps', [9 6]);

%Save the outcome of all the above
save(fn_out);
%fn_out = './worksheets/10_27_2014/data.mat';
%load(fn_out);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Make a plot of the deviance as a function of params

%Compute AIC and BIC
nK = [nK_poss]+nK_sp + 1;
AIC_IRLS = devs_IRLS + 2*nK;
AICc_IRLS = AIC_IRLS + 2*nK.*(nK+1)./(N-1-nK);
BIC_IRLS = devs_IRLS + ([nK_poss]+nK_sp+1)*log(N);

clf
plot(dt_poss, devs_IRLS, dt_poss, AIC_IRLS, dt_poss, AICc_IRLS, dt_poss, BIC_IRLS);
legend('Deviance', 'AIC', 'AICc', 'BIC')
xlabel('resolution (s)')
ylabel('Likelihood')
saveplot(gcf, './worksheets/10_27_2014/plots/filters_dev.eps')


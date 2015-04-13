%Make data structure
runIdx = 7;
fn_out = './worksheets/04_10_2015/gpfa_example';

nevfile = './testdata/20130117SpankyUtah001.nev';
labviewfile = './testdata/Spanky_2013-01-17-1325.mat';
binsize = 0.001;
offset = 0.0;
threshold = 5;
processed = preprocess_spline_target(nevfile, labviewfile, binsize, threshold, offset);



spikes = processed.binnedspikes;
%Time bins which occur within a trial
trials = sum(abs(processed.target),2)>0;
dat = makedata(trials, spikes, processed.cursor, processed.target);

%Split into quadrants
datquads = {};
nelem = zeros(4,1);
for idx = 1:length(dat)
	q = dat(idx).quadrant;
	el = nelem(q)+1;
	datquads{q}(el).trialId = el;
	datquads{q}(el).quadrant = q;
	datquads{q}(el).spikes = dat(idx).spikes;
	nelem(q) = el;
end

%Run all trials together
[dat, octs, quads] = makedata(trials, spikes, processed.cursor, processed.target);
method = 'gpfa';
% Select number of latent dimensions
xDim = 8;
kernSD = 30;
% Extract neural trajectories
result = neuralTraj(runIdx, dat, 'method', method, 'xDim', xDim, 'kernSDList', kernSD);
% Orthonormalize neural trajectories
[estParams, seqTrain, seqTest, DD] = postprocess(result, 'kernSD', kernSD);
% Plot each dimension of neural trajectories versus time
plotEachDimVsTime_coloct(seqTrain, 'xorth', result.binWidth, octs);
saveplot(gcf, [fn_out '_EachDimVsTime_coloct.eps'], 'eps', [10 6])
plotEachDimVsTime_colquad(seqTrain, 'xorth', result.binWidth, quads, 'nPlotMax', 100);
saveplot(gcf, [fn_out '_EachDimVsTime_colquad.eps'], 'eps', [10 6])
plotEachDimVsTime_specificquad(seqTrain, 'xorth', result.binWidth, quads, 'nPlotMax', 100);
saveplot(gcf, [fn_out '_EachDimVsTime_specificquad.eps'], 'eps', [20 6])


plot3D_coloct(seqTrain, 'xorth', octs, 'dimsToPlot', 1:3, 'nPlotMax', 100);
saveplot(gcf, [fn_out '_plot3D_coloct.eps'])
plot2D_coloct(seqTrain, 'xorth', octs, 'dimsToPlot', 1:3, 'nPlotMax', 100);
saveplot(gcf, [fn_out '_plot2D_coloct.eps'])


runIdx = 2;
%load('mat_sample/sample_dat');
for q = 1:4
	runIdx = runIdx + 1;
	dat = datquads{q};
	method = 'gpfa';
	% Select number of latent dimensions
	xDim = 8;
	kernSD = 30;
	% Extract neural trajectories
	result = neuralTraj(runIdx, dat, 'method', method, 'xDim', xDim, 'kernSDList', kernSD);
	% Orthonormalize neural trajectories
	[estParams, seqTrain, seqTest, DD] = postprocess(result, 'kernSD', kernSD);
	%power
	pow = diag(DD.^2)/sum(diag(DD.^2));
	% Plot neural trajectories in 3D space
	plot3D(seqTrain, 'xorth', 'dimsToPlot', 1:3, 'nPlotMax', 8);
	title(['Quadrant ' num2str(q)])
	saveplot(gcf, [fn_out '_q_' num2str(q) '_plot3D.eps'])
	% Plot each dimension of neural trajectories versus time
	plotEachDimVsTime(seqTrain, 'xorth', result.binWidth);
	title(['Quadrant ' num2str(q)])
	saveplot(gcf, [fn_out '_q_' num2str(q) '_EachDimVsTime.eps'])
	figure
	plot(pow)
	hold on
	plot(cumsum(pow), 'r')
	legend('Power', 'Cumulative power')
	xlabel('Principle component')
	ylabel('Power')
	saveplot(gcf, [fn_out '_q_' num2str(q) '_PCAenergy.eps'])
end


% ========================================================
% 2) Full cross-validation to find:
%  - optimal state dimensionality for all methods
%  - optimal smoothing kernel width for two-stage methods
% ========================================================

% Select number of cross-validation folds
numFolds = 4;

% Perform cross-validation for different state dimensionalities.
% Results are saved in mat_results/runXXX/, where XXX is runIdx.
for xDim = [2 5 8]
  neuralTraj(runIdx, dat, 'method',  'pca', 'xDim', xDim, 'numFolds', numFolds);
  neuralTraj(runIdx, dat, 'method', 'ppca', 'xDim', xDim, 'numFolds', numFolds);
  neuralTraj(runIdx, dat, 'method',   'fa', 'xDim', xDim, 'numFolds', numFolds);
  neuralTraj(runIdx, dat, 'method', 'gpfa', 'xDim', xDim, 'numFolds', numFolds);
end
fprintf('\n');

% Plot prediction error versus state dimensionality.
% Results files are loaded from mat_results/runXXX/, where XXX is runIdx.
kernSD = 30; % select kernSD for two-stage methods
plotPredErrorVsDim(runIdx, kernSD);

% Plot prediction error versus kernelSD.
% Results files are loaded from mat_results/runXXX/, where XXX is runIdx.
xDim = 5; % select state dimensionality
plotPredErrorVsKernSD(runIdx, xDim);

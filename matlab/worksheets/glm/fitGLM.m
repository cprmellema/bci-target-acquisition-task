% fitGLM.m

%% 1.  Set parameters and display for GLM ============= % 

DTsim = .001; % Bin size for simulating model & computing likelihood.
nkt = 15;  % Number of time bins in filter;
ttk = [-nkt+1:0]';
ggsim = makeSimStruct_GLM(nkt,DTsim);  % Create GLM struct with default params
kt = ggsim.k;  % Temporal filter

%Do for each interesting channel

%% 2. Load some training data ========================================

%Load spike times, and stimulus data
%Load spike times for each unit

nevfile = './testdata/20130117SpankyUtah001.nev';
matfile = './testdata/Spanky_2013-01-17-1325.mat';
binsize = 0.001;
global RefreshRate;  % Stimulus refresh rate (Stim frames per second)
samplerate = 1/binsize;
RefreshRate = samplerate; 
offset = 0;
threshold = 5;
verbosity = 1;
fn_out = './worksheets/shoham/plots/20130117SpankyUtah001';
[binnedspikes rates torque dtorque ddtorque unitnames tspks] = preprocess_shoham_nev(nevfile, fn_out, binsize, threshold, offset);
nU = length(unitnames);

%Load 'stimulus' data
withintrial = zeros(size(rates,1),1);
targetpos = zeros(size(rates,1),2);
startpos = zeros(size(rates,1),2);
rtorque = zeros(size(torque));
%Load trial info
trials = import_trials(matfile);
for idx=1:length(trials)
  	%For each trial, use only those corresponding to the given nev file
  	[path1, name1, ext1] = fileparts(nevfile);
  	[path2, name2, ext2] = fileparts(trials(idx).nevfile);
  	if strcmp(name1, name2)
  	  	%mark the within trial times in the above vector
  	  	%Time relative to nev file recording
  	  	trialstart = round(samplerate*(trials(idx).starttime-trials(idx).offset));
  	  	trialend = round(samplerate*(trials(idx).endtime-trials(idx).offset));
  	  	l = length(trialstart:trialend);
  	  	withintrial(trialstart:trialend)=1;
  	  	targetpos(trialstart:trialend,:)=repmat(trials(idx).target, l, 1);
  	  	startpos(trialstart:trialend,:)=repmat(trials(idx).cursorstart, l, 1);
  	  	%Compute torque to subtract from torque to make target position at origin
  	  	trqend = torque(trialend,:);
  	  	%Center torque
  	  	rtorque(trialstart:trialend,:) = torque(trialstart:trialend,:)-repmat(trqend, l, 1);
  	  	trqstr = rtorque(trialstart,:);
  	  	%Compute angle to rotate torque, dtorque and ddtorque by so that cursor start is at directly below target
  	  	theta = atan(trqstr(2)/trqstr(1));
  	  	if trqstr(1)<0
  	  		if trqstr(2)>0
  	  			theta = theta + pi;
  	  		else
  	  			theta = theta - pi;
  	  		end
  	  	end
  	  	%Plot to make sure things make sense
  	  	%Before rotation
  	  	if verbosity > 1
	  	  	figure
  	  		subplot(1,2,1)
  	  		plot(rtorque(trialstart:trialend,1), rtorque(trialstart:trialend,2), trqstr(1), trqstr(2), 'or');
  	  		title('Cursor position before rotation. red = start')
  	  		xlim([-0.5 0.5])
  	  		ylim([-0.5 0.5])
  	  	end
  	  	%Place directly below torque end position (theta = pi/2)
  	  	%theta = -theta - pi/2;
  	  	%OR don't do any rotation
  	  	theta = 0;
  	  	%Rotate torque, dtorque and ddtorque
  	  	rotation = [cos(theta), -sin(theta); sin(theta), cos(theta)];
  	  	rtorque(trialstart:trialend,:) = (rotation*(rtorque(trialstart:trialend,:)'))';
  	  	trqstr = (rotation*trqstr')';
  	  	%Plot after rotation
  	  	if verbosity > 1
  	  		subplot(1,2,2)
  	  		plot(torque(trialstart:trialend,1), rtorque(trialstart:trialend,2), trqstr(1), trqstr(2), 'or');
  	  		title('Cursor position after rotation. red = start')
  	  		xlim([-0.5 0.5])
  	  		ylim([-0.5 0.5])
  	    end
  	  	display(['Trial ' num2str(idx) ' within nev file. t_start: ' num2str(trials(idx).starttime) ' t_end: ' num2str(trials(idx).endtime)]);
  	  	%pause
  	end
end

Stim = [torque, rtorque];

%For each unit, fit a GLM to the torque data
for idx=1:nU 

	tsp = tspks(idx).times;
	nsp = length(tsp);
	% Compute STA and use as initial guess for k
	sta0 = simpleSTC(Stim,tsp,nkt);
	sta = reshape(sta0,nkt,[]);
	
	%% 3. Fit GLM (traditional version) via max likelihood
	
	%  Initialize params for fitting --------------
	Filter_rank = 1;
	gg0 = makeFittingStruct_GLM(sta,DTsim);
	gg0.tsp = tsp;
	gg0.tspi = 1;
	[logli0,rr0,tt] = neglogli_GLM(gg0,Stim); % Compute logli of initial params (if desired)
	
	% Do ML estimation of model params
	opts = {'display', 'iter', 'maxiter', 100};
	[gg1, negloglival] = MLfit_GLM(gg0,Stim,opts); % do ML (requires optimization toolbox)
	
	
	%% 4. Plot results ====================
	figure(3);
	
	subplot(232);  % sta % ------------------------
	imagesc(sta);
	title('raw STA');
	ylabel('time');
	
	subplot(233); % sta-projection % ---------------
	imagesc(gg0.k)
	title('projected STA');
	
	subplot(234); % estimated filter % ---------------
	imagesc(gg1.k) 
	title('ML estimate: full filter'); xlabel('space'); ylabel('time');
	
	subplot(236); % ----------------------------------
	plot(ggsim.iht,exp(ggsim.ih),'k', gg1.iht,exp(gg1.ihbas*gg1.ih),'b',...
	    gg2.iht, exp(gg2.ihbas*gg2.ih), 'r');
	title('post-spike kernel');
	axis tight;

end
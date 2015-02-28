matfile_in = './expts/2dmanualpos_1day.mat';
settings = setupExperiment('sprc_pos_network_lv_def');
exptname = '2dmanualpos_sprc_pos_network_lv_def';
redo = true;
expts = runExperiment(matfile_in, settings, exptname, redo);
save(['./expts/' exptname '.mat'], 'expts');
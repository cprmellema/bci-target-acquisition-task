conn = database('','root','Fairbanks1!','com.mysql.jdbc.Driver', ...
	'jdbc:mysql://fairbanks.amath.washington.edu:3306/spanky_db');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Gather data%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_data = fetch(exec(conn, ['SELECT fl1.size, fl2.size, fl3.size, fl4.size, fl5.size, fl1.dir, fl2.dir, fl3.dir, fl4.dir,fl5.dir FROM '...
'`experiment_tuning` et1 '...
'INNER JOIN `fits` flin1 '...
'ON flin1.`nev file` = et1.`manualrecording`'...
'INNER JOIN `fits_linear` fl1 '...
'ON flin1.id = fl1.id '...
'INNER JOIN `fits` flin2 '...
'ON flin2.`nev file` = et1.`1DBCrecording`'...
'INNER JOIN `fits_linear` fl2 '...
'ON flin2.id = fl2.id '...
'INNER JOIN `fits` flin3 '...
'ON flin3.`nev file` = et1.`manualrecordingafter`'...
'INNER JOIN `fits_linear` fl3 '...
'ON flin3.id = fl3.id '...
'INNER JOIN `fits` flin4 '...
'ON flin4.`nev file` = et1.`1DBCrecordingafter`'...
'INNER JOIN `fits_linear` fl4 '...
'ON flin4.id = fl4.id '...
'INNER JOIN `fits` flin5 '...
'ON flin5.`nev file` = et1.`dualrecording`'...
'INNER JOIN `fits_linear` fl5 '...
'ON flin5.id = fl5.id '...
'WHERE flin1.modelID = 1 AND flin2.modelID = 1 AND flin3.modelID = 1 AND flin4.modelID = 1 AND flin5.modelID = 1 ' ...
'AND flin1.unit = flin2.unit AND flin2.unit = flin3.unit AND flin2.unit = flin4.unit AND flin2.unit = flin5.unit']));
all_d = cell2mat(all_data.Data(:,1:5));
all_angles = cell2mat(all_data.Data(:,6:10));

%MC threshold
load('./worksheets/2015_10_22-lineartuningsignificance/shuffedsizes.mat');
sizes_MC = sort(sizes_MC);
sizes_BC = sort(sizes_BC);
sizes_MC2 = sort(sizes_MC2);

clf
subplot(1,2,1)
plot(cos(all_angles(:,1)), cos(all_angles(:,2)), '.')
xlabel('Cos tuning angle MC1')
ylabel('Cos tuning angle BC')
subplot(1,2,2)
plot(cos(all_angles(:,1)), cos(all_angles(:,3)), '.')
xlabel('Cos tuning angle MC1')
ylabel('Cos tuning angle BC')
saveplot(gcf, './worksheets/2015_10_22-lineartuningsignificance/tuningangleMCBCMC2.eps')

MI(1) = mutualinfo(all_d(:,1), all_d(:,2));
MI(2) = mutualinfo(all_d(:,1), all_d(:,3));
MI(3) = mutualinfo(all_d(:,3), all_d(:,2));
MI(4) = mutualinfo(all_d(:,2), all_d(:,4));
MI(5) = mutualinfo(all_d(:,1), all_d(:,5));
MI(6) = mutualinfo(all_d(:,2), all_d(:,5));

clf
subplot(2,3,1)
plot(all_d(:,1), all_d(:,2), '.')
xlabel('Tuning strength MC1')
ylabel('Tuning strength BC1')
title(['Mutual information: ' num2str(MI(1))])
subplot(2,3,2)
plot(all_d(:,1), all_d(:,3), '.')
xlabel('Tuning strength MC1')
ylabel('Tuning strength MC2')
title(['Mutual information: ' num2str(MI(2))])
subplot(2,3,3)
plot(all_d(:,3), all_d(:,2), '.')
ylabel('Tuning strength BC1')
xlabel('Tuning strength MC2')
title(['Mutual information: ' num2str(MI(3))])
subplot(2,3,4)
plot(all_d(:,2), all_d(:,4), '.')
xlabel('Tuning strength BC1')
ylabel('Tuning strength BC2')
xlim([0 3])
ylim([0 8])
title(['Mutual information: ' num2str(MI(4))])
subplot(2,3,5)
plot(all_d(:,1), all_d(:,5), '.')
xlabel('Tuning strength MC1')
ylabel('Tuning strength DC')
title(['Mutual information: ' num2str(MI(5))])
subplot(2,3,6)
plot(all_d(:,2), all_d(:,5), '.')
xlabel('Tuning strength BC1')
ylabel('Tuning strength DC')
title(['Mutual information: ' num2str(MI(6))])
saveplot(gcf, './worksheets/2015_10_22-lineartuningsignificance/tuningstrengthMCBCMC2.eps')

clf
scatter(all_d(:,1), all_d(:,2), [], all_d(:,5))
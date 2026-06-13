function net = ieee33_data()
%IEEE33_DATA Standard IEEE 33-bus radial distribution feeder data.
%
% Branch columns:
%   1 from_bus
%   2 to_bus
%   3 resistance_ohm
%   4 reactance_ohm
%   5 resistance_pu
%   6 reactance_pu
%
% Load arrays are three-phase total bus loads in kW and kVAr. Positive
% Pnet/Qnet values in the load-flow model mean demand; negative values mean
% net generation injection.

net.nBus = 33;
net.nBranch = 32;
net.baseMVA = 100;
net.baseKV = 12.66;
net.slackBus = 1;
net.Vmin = 0.95;
net.Vmax = 1.05;
net.Vnom = 1.0;

branchOhm = [
     1  2 0.0922 0.0470
     2  3 0.4930 0.2511
     3  4 0.3660 0.1864
     4  5 0.3811 0.1941
     5  6 0.8190 0.7070
     6  7 0.1872 0.6188
     7  8 1.7114 1.2351
     8  9 1.0300 0.7400
     9 10 1.0440 0.7400
    10 11 0.1966 0.0650
    11 12 0.3744 0.1238
    12 13 1.4680 1.1550
    13 14 0.5416 0.7129
    14 15 0.5910 0.5260
    15 16 0.7463 0.5450
    16 17 1.2890 1.7210
    17 18 0.7320 0.5740
     2 19 0.1640 0.1565
    19 20 1.5042 1.3554
    20 21 0.4095 0.4784
    21 22 0.7089 0.9373
     3 23 0.4512 0.3083
    23 24 0.8980 0.7091
    24 25 0.8960 0.7011
     6 26 0.2030 0.1034
    26 27 0.2842 0.1447
    27 28 1.0590 0.9337
    28 29 0.8042 0.7006
    29 30 0.5075 0.2585
    30 31 0.9744 0.9630
    31 32 0.3105 0.3619
    32 33 0.3410 0.5302
];

baseZ = net.baseKV^2 / net.baseMVA;
rpu = branchOhm(:, 3) / baseZ;
xpu = branchOhm(:, 4) / baseZ;
net.branch = [branchOhm rpu xpu];

loadData = [
     1   0   0
     2 100  60
     3  90  40
     4 120  80
     5  60  30
     6  60  20
     7 200 100
     8 200 100
     9  60  20
    10  60  20
    11  45  30
    12  60  35
    13  60  35
    14 120  80
    15  60  10
    16  60  20
    17  60  20
    18  90  40
    19  90  40
    20  90  40
    21  90  40
    22  90  40
    23  90  50
    24 420 200
    25 420 200
    26  60  25
    27  60  25
    28  60  20
    29 120  70
    30 200 600
    31 150  70
    32 210 100
    33  60  40
];

net.loadP_kW = loadData(:, 2);
net.loadQ_kVAr = loadData(:, 3);
net.loadP_pu = net.loadP_kW / (net.baseMVA * 1000);
net.loadQ_pu = net.loadQ_kVAr / (net.baseMVA * 1000);
net.totalLoad_kW = sum(net.loadP_kW);
net.totalLoad_kVAr = sum(net.loadQ_kVAr);
end

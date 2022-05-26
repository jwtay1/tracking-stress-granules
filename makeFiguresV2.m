clearvars
clc

%% 20220426_ XY 5
roi = [154 195 445 643];
spotID = 1;
frames = 48:57;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\tracks\trackedData_20220426__crop_XY5.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\20220426_';

exportImages(inputFile, outputDir, roi, spotID, frames)

%% trackedData_20220311_polyic_xy3
roi = [1 126 283 322];
spotID = 1;
frames = 20:38;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\tracks\trackedData_20220311_polyic_xy3.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\20220311_polyic_xy3';

exportImages(inputFile, outputDir, roi, spotID, frames, ...
    'redChannel', 1, 'greenChannel', 2, ...
    'redChannelNormRange', [400 3500], 'greenChannelNormRange', [200 3000], ...
    'nearDist', 100)

%% trackedData_20220311_polyic_xy6
roi = [280 708 529 900];
spotID = 1;
frames = 115:122;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\tracks\trackedData_20220311_polyic_xy6.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\20220311_polyic_xy6';

exportImages(inputFile, outputDir, roi, spotID, frames, ...
    'redChannelNormRange', [500 1200], 'greenChannelNormRange', [250 2500], ...
    'nearDist', 50)

%% trackedData_20220311_polyic_xy7_10to20
roi = [397 349 642 635];
spotID = 1;
frames = 10:20;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\tracks\trackedData_20220311_polyic_xy7_10to20.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\20220311_polyic_xy7_10to20';

exportImages(inputFile, outputDir, roi, spotID, frames, ...
    'redChannelNormRange', [500 1200], 'greenChannelNormRange', [500 1500], ...
    'nearDist', 50)

%% trackedData_20220311_polyic_xy7_28to38
roi = [210 350 385 570];
spotID = 1;
frames = 28:38;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\tracks\trackedData_20220311_polyic_xy7_28to38.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\20220311_polyic_xy7_28to38';

exportImages(inputFile, outputDir, roi, spotID, frames, ...
    'redChannelNormRange', [500 1200], 'greenChannelNormRange', [250 1500], 'nearDist', 50)

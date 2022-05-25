clearvars
clc

%% 20220426_ XY 5
roi = [154 195 445 643];
spotID = 1;
frames = 48:57;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524\trackedData_20220426__crop_XY5.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524\20220426_';

exportImages(inputFile, outputDir, roi, spotID, frames)

%% trackedData_20220311_polyic_xy3
roi = [1 126 283 322];
spotID = 1;
frames = 20:38;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524\trackedData_20220311_polyic_xy3.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524\20220311_polyic_xy3';

exportImages(inputFile, outputDir, roi, spotID, frames, ...
    'redChannel', 1, 'greenChannel', 2, ...
    'redChannelNormRange', [400 3500], 'greenChannelNormRange', [200 3000])

%% trackedData_20220311_polyic_xy6 NOTE: ROI not yet picked
roi = [1 126 283 322];
spotID = 1;
frames = 48:57;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524\trackedData_20220311_polyic_xy6.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524\20220311_polyic_xy6';

exportImages(inputFile, outputDir, roi, spotID, frames)

%% trackedData_20220311_polyic_xy7
roi = [1 126 283 322];
spotID = 1;
frames = 48:57;

inputFile = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524\trackedData_20220311_polyic_xy7.mat';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524\20220311_polyic_xy7';

exportImages(inputFile, outputDir, roi, spotID, frames)
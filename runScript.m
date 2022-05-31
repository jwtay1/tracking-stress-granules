clearvars
clc
dataFolder = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\publication';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525';

files = {'20220311_polyic_xy3.mat', '20220426__crop_XY5.mat', ...
    '20220311_polyic_xy7_10to20.mat', '20220311_polyic_xy7_28to38.mat', ...
    '20220311_polyic_xy6.mat'};

frames = {20:38, 47:57, 10:20, 28:38, 115:122};

thLvls = {1200, 5000, 1200, 1200, 1200};  %Cell threshold level

%%

% files = {'20220311_polyic_xy7.nd2'};
% 
% frames = {10:20};
% 
% thLvls = {1200};
% 
% %Make cell masks
% for iF = 1:numel(files)
%     
%     currFN = fullfile(dataFolder, files{iF});
%     [~, outputFN] = fileparts(currFN);
%     
%     outputFN = [outputFN, '.tif'];
%     
%     exportCellMask(currFN, fullfile(outputDir, outputFN), thLvls{iF}, frames{iF});
% 
% end
% 
% %Masks are edited

%% Process the data

outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\publication\tracks';

maskDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\edited';
maskFiles = {'20220311_polyic_xy3.tif', '20220426__crop_XY5.tif', ...
    '20220311_polyic_xy7_10to20.tif', '20220311_polyic_xy7_28to38.tif', ...
    '20220311_polyic_xy6.tif'};

greenSpotSensitivity = [300 1500 100 100 100];
redSpotSensitivity = [750, 750, 500, 750, 500];

for iF = 1%:numel(files)
    
    currFN = fullfile(dataFolder, files{iF});
    currMaskFN = fullfile(maskDir, maskFiles{iF});
       
    processMovie(currFN, outputDir, currMaskFN,...
        'greenSpotSensitivity', greenSpotSensitivity(iF), ...
        'frames', frames{iF}, ...
        'redSpotSensitivity', redSpotSensitivity(iF));
    
end




















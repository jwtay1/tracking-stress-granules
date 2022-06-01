clearvars
clc

dataFolder = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\publication';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525';

files = {'20220311_polyic_xy3.mat', '20220426__crop_XY5.mat', ...
    '20220311_polyic_xy7_10to20.mat', '20220311_polyic_xy7_28to38.mat', ...
    '20220311_polyic_xy6.mat'};

frames = {20:38, 47:57, 10:20, 28:38, 115:122};

maskDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\edited';
maskFiles = {'20220311_polyic_xy3.tif', '20220426__crop_XY5.tif', ...
    '20220311_polyic_xy7_10to20.tif', '20220311_polyic_xy7_28to38.tif', ...
    '20220311_polyic_xy6.tif'};

greenSpotSensitivity = [300 4000 280 300 200];
redSpotSensitivity = [750, 2500, 750, 750, 500];

iT = 20;

chRed = 1;
chGreen = 2;

%Load data

for iF = 3 %1:numel(files)
    
    mipImages = load(fullfile(dataFolder, files{iF}));
    currMaskFN = fullfile(maskDir, maskFiles{iF});
    
    mip = mipImages.mip{iT - frames{iF}(1) + 1};

    maxGreenInt = double(max(cellfun(@(x) prctile(x(:, :, 2), 99, 'all'), mipImages.mip)));
    
    %Read the mask file
    cellMask = imread(currMaskFN, iT - frames{iF}(1) + 1);
    cellMask = cellMask > 0;

    %Detect spots in each channel
    spotMask_Red = detectSpots(mip(:, :, chRed), redSpotSensitivity(iF));
    spotMask_Green = detectSpots(mip(:, :, chGreen), greenSpotSensitivity(iF));
    
    figure(1)
    showoverlay(mip(:, :, chRed), spotMask_Red, 'Opacity', 40, 'color', [1 1 0])
    
    figure(2)
    showoverlay(mip(:, :, chGreen), spotMask_Green, 'Opacity', 30)
    

    
end
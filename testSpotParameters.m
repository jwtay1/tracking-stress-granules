clearvars
clc

dataFolder = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\data\crop';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525';

files = {'20220311_polyic_xy3.nd2', '20220426__crop_XY5.nd2', ...
    '20220311_polyic_xy7.nd2', '20220311_polyic_xy7.nd2', ...
    '20220311_polyic_xy6.nd2'};

frames = {20:38, 47:57, 10:20, 28:38, 115:122};

maskDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220525\edited';
maskFiles = {'20220311_polyic_xy3.tif', '20220426__crop_XY5.tif', ...
    '20220311_polyic_xy7_10to20.tif', '20220311_polyic_xy7_28to38.tif', ...
    '20220311_polyic_xy6.tif'};

greenSpotSensitivity = [200 1500 100 100 100];
redSpotSensitivity = [750, 750, 500, 750, 500];

iT = 56;

chRed = 2;
chGreen = 3;

for iF = 2 %1:numel(files)
    
    currFN = fullfile(dataFolder, files{iF});
    currMaskFN = fullfile(maskDir, maskFiles{iF});
    
    nd2 = ND2reader(currFN);

       
    %Get the MIP
    mip = calculateMIP(nd2, 1, iT);

    %Read the mask file
    cellMask = imread(currMaskFN, iT - frames{iF}(1) + 1);
    cellMask = cellMask > 0;

    %Detect spots in each channel
    spotMask_Red = detectSpotsByExtendedMax(mip(:, :, chRed), redSpotSensitivity(iF));
    spotMask_Green = detectSpotsByExtendedMax(mip(:, :, chGreen), greenSpotSensitivity(iF));
    
    figure(1)
    showoverlay(mip(:, :, chRed), spotMask_Red, 'Opacity', 10)
    
    figure(2)
    showoverlay(mip(:, :, chGreen), spotMask_Green, 'Opacity', 10)
    

    
end
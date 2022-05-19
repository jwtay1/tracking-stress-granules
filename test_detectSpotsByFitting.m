clearvars
clc

filename = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\data\20220426_.nd2';

outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220519';

%Parameters
minSpotSize = 3;
spotThreshold = 15;

ch2IntRange = [500, 15000];
ch3IntRange = [500, 15000];

cellTracker = LAPLinker;
cellTracker.LinkedBy = 'Centroid';
%cellTracker.LinkCostMetric = 'pxintersect';
cellTracker.LinkScoreRange = [0 50];
cellTracker.MaxTrackAge = 1;

%% Process data

nd2 = ND2reader(filename);

%Setup output filename and directory
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

[~, outputFN] = fileparts(filename);

%Create a new video
vid = VideoWriter(fullfile(outputDir, [outputFN, '.avi']));
vid.FrameRate = 15;
open(vid)

for iT = 1:nd2.sizeT

    %Get the MIP
    mip = calculateMIP(nd2, iT);

    %Mask cells
    cellMask = identifyCells(mip(:, :, 1), 600);
    % showoverlay(mip(:, :, 1), bwperim(cellMask));

    %Detect spots in each channel
    spotMask_Red = detectSpotsByExtendedMax(mip(:, :, 2), 1200);
    spotMask_Green = detectSpotsByExtendedMax(mip(:, :, 3), 1500);

    %Collect spot information
    cellData = regionprops(cellMask, 'Centroid', 'PixelIdxList');

    for ii = 1:numel(cellData)

        currCellMask = false(size(cellMask));
        currCellMask(cellData(ii).PixelIdxList) = true;
        
        %Add spot counts and location
        curr_spotMask_Red = spotMask_Red & currCellMask;
        redSpotData = regionprops(curr_spotMask_Red, mip(:, :, 2), 'MaxIntensity', 'Centroid');

        cellData(ii).NumRedSpots = numel(redSpotData);
        cellData(ii).RedSpotsPos = cat(1, redSpotData.Centroid);
        cellData(ii).RedSpotsInt = cat(1, redSpotData.MaxIntensity);

        curr_spotMask_Green = spotMask_Green & currCellMask;
        greenSpotData = regionprops(curr_spotMask_Green, mip(:, :, 3), 'MaxIntensity', 'Centroid');
        
        cellData(ii).NumGreenSpots = numel(greenSpotData);
        cellData(ii).GreenSpotsPos = cat(1, greenSpotData.Centroid);
        cellData(ii).GreenSpotsInt = cat(1, greenSpotData.MaxIntensity);

    end

    %Track cells
    cellTracker = assignToTrack(cellTracker, iT, cellData);


    %Generate an image
    ch2Norm = double(mip(:, :, 2));
    ch2Norm = (ch2Norm - (min(ch2IntRange)))/(max(ch2IntRange) - min(ch2IntRange));
    ch3Norm = double(mip(:, :, 3));
    ch3Norm = (ch3Norm - (min(ch2IntRange)))/(max(ch2IntRange) - min(ch2IntRange));

    Ired = ch2Norm;
    Igreen = ch3Norm;
    Iblue = ch2Norm;

    Irgb = cat(3, Ired, Igreen, Iblue);

    %Overlay masks
    Iout = showoverlay(Irgb, bwperim(cellMask), 'Opacity', 1000, 'Color', [1 1 1]);
    Iout = showoverlay(Iout, spotMask_Red, 'Opacity', 40, 'Color', [1 1 0]);
    Iout = showoverlay(Iout, spotMask_Green, 'Opacity', 40, 'Color', [0 1 1]);

    Iout = uint16(Iout * 65535);

    %Label cells
    for iAT = 1:numel(cellTracker.activeTrackIDs)
        currAT = getTrack(cellTracker, cellTracker.activeTrackIDs(iAT));
        Iout = insertText(Iout, currAT.Centroid(end, :), int2str(cellTracker.activeTrackIDs(iAT)));
    end

    Iout = im2double(Iout);

    writeVideo(vid, Iout)

end

close(vid)

%% Data analysis

track1 = getTrack(cellTracker, 2);

plot(track1.Frames, track1.NumRedSpots, 'r-', track1.Frames, track1.NumGreenSpots, 'g-');


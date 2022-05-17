clearvars
clc

nd2 = ND2reader('D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\data\20220426_.nd2');

cellTracker = LAPLinker;
cellTracker.LinkedBy = 'PixelIdxList';
cellTracker.LinkCostMetric = 'pxintersect';
cellTracker.LinkScoreRange = [1 12];

% spotTracker = LAPLinker;
% cellTracker.LinkedBy = 'Centroid';
% cellTracker.LinkScoreRange = [0 40];

redSpotSize = 2;
redSpotThreshold = 5;
redSpotMinSpotArea = 10;
redSpotSBR = 2;

greenSpotSize = 2;
greenSpotThreshold = 4;
greenSpotMinSpotArea = 10;
greenSpotSBR = 3;

vid = VideoWriter('D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\2022-05-16 Results.avi');
vid.FrameRate = 10;
open(vid)

for iT = 1:nd2.sizeT

    currFrame = zeros(nd2.height, nd2.width, nd2.sizeC);
    for iZ = 1:nd2.sizeZ
        currFrame = max(currFrame, double(getImage(nd2, 1, iT, 1)));
    end

    cellMask = currFrame(:, :, 2) > 800;
    cellMask = imopen(cellMask, strel('disk', 5));
    cellMask = imfill(cellMask, 'holes');

    cellData = regionprops(cellMask, 'Centroid', 'PixelIdxList');

    spotMaskRed = detectSpots(currFrame(:, :, 1), cellMask,...
        redSpotSize, redSpotThreshold, redSpotMinSpotArea);

    spotMaskGreen = detectSpots(currFrame(:, :, 2), cellMask,...
        greenSpotSize, greenSpotThreshold, greenSpotMinSpotArea);
    
    finalSpotMaskRed = false(size(spotMaskRed));
    finalSpotMaskGreen = false(size(spotMaskGreen));

    %Count number of spots and location in each cell
    for iCell = 1:numel(cellData)

        currCellMask = false(size(cellMask));
        currCellMask(cellData(iCell).PixelIdxList) = true;

        %Mask the red and green spots within the cell
        currSpotMaskRed = spotMaskRed & currCellMask;
        currSpotMaskGreen = spotMaskGreen & currCellMask;

        %Measure spot data
        spotRedData = regionprops(currSpotMaskRed, currFrame(:, :, 1), 'MeanIntensity', 'Centroid', 'PixelIdxList');
        spotGreenData = regionprops(currSpotMaskGreen, currFrame(:, :, 2), 'MeanIntensity', 'Centroid', 'PixelIdxList');

        %Remove regions that are below a set signal-to-background ratio
        %(excluding spots)
        redImg = currFrame(:, :, 1);
        cellIntensityRed = mean(redImg(currCellMask & ~currSpotMaskRed), 'all');

        if numel(spotRedData) > 0
            spotRedIntensities = [spotRedData.MeanIntensity];
            spotRedData((spotRedIntensities/cellIntensityRed) < redSpotSBR) = [];
        end

        greenImg = currFrame(:, :, 1);
        cellIntensityGreen = mean(greenImg(currCellMask & ~currSpotMaskGreen), 'all');

        if numel(spotGreenData) > 0
            spotGreenIntensities = [spotGreenData.MeanIntensity];
            spotGreenData((spotGreenIntensities/cellIntensityGreen) < greenSpotSBR) = [];
        end        

        %Measure distances of green spots to red spots
        if numel(spotGreenData) > 0 && numel(spotRedData) > 0

            greenSpotPos = cat(1, spotGreenData.Centroid);
            for iRedSpot = 1:numel(spotRedData)

                spotRedData(iRedSpot).DistanceToGreenSpot = ...
                    sqrt(sum((greenSpotPos - spotRedData(iRedSpot).Centroid).^2, 2));

                finalSpotMaskRed(spotRedData(iRedSpot).PixelIdxList) = true;
            end

            for iGreenSpot = 1:numel(spotGreenData)

                finalSpotMaskGreen(spotGreenData(iGreenSpot).PixelIdxList) = true;

            end

        else


        end
        
%         imshow(finalSpotMaskRed)

        cellData(iCell).redSpotData = spotRedData;
        cellData(iCell).greenSpotData = spotGreenData;

        cellData(iCell).NumRedSpots = numel(spotRedData);
        cellData(iCell).NumGreenSpots = numel(spotGreenData);

    end

    %Track cells
    cellTracker = assignToTrack(cellTracker, iT, cellData);

    %Make output video
    Ired = currFrame(:, :, 1);
    Ired = (Ired - min(Ired(:)))/(max(Ired(:)) - min(Ired(:)));

    Igreen = currFrame(:, :, 1);
    Igreen = (Igreen - min(Igreen(:)))/(max(Igreen(:)) - min(Igreen(:)));

    Iblue = zeros(size(Igreen));

    Irgb = cat(3, Ired, Igreen, Iblue);
    Irgb = showoverlay(Irgb, bwperim(cellMask), 'color', [1 1 1]);
    Irgb = showoverlay(Irgb, finalSpotMaskRed, 'color', [1 1 0], 'Opacity', 40);
    Irgb = showoverlay(Irgb, finalSpotMaskGreen, 'color', [1 0 1], 'Opacity', 40);

    for ii = 1:numel(cellTracker.activeTrackIDs)
        currAT = getTrack(cellTracker, ii);

        Irgb = insertText(Irgb, currAT.Centroid(end, :), int2str(ii));
    end

    writeVideo(vid, Irgb)

end
close(vid)

%% Plot data

cellTracks = cellTracker.tracks;

for iCell = 3

    currCellData = getTrack(cellTracker, iCell);

end

plot(currCellData.Frames, currCellData.NumRedSpots, ...
    currCellData.Frames, currCellData.NumGreenSpots)




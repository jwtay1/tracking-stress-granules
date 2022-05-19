clearvars
clc

inputFN = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\data\20220426_.nd2';

nd2 = ND2reader(inputFN);

cellThreshold = 1800;

cellTracker = LAPLinker;
cellTracker.LinkedBy = 'PixelIdxList';
cellTracker.LinkCostMetric = 'pxintersect';
cellTracker.LinkScoreRange = [1 12];

for iT = 69

    %Compute max intensity projection
    currFrame = zeros(nd2.height, nd2.width, nd2.sizeC);
    for iZ = 1:nd2.sizeZ
        currFrame = max(currFrame, double(getImage(nd2, 1, iT, 1)));
    end

    %Mask the Cy5 channel (channel 1)
    cellMask = sum(currFrame, 3) > cellThreshold;
    cellMask = imopen(cellMask, strel('disk', 5));

    dd = -bwdist(~cellMask);
    dd(~cellMask) = -Inf;
    dd = imhmin(dd, 6);

    LL = watershed(dd);

    cellMask(LL == 0) = 0;
    cellMask = bwareaopen(cellMask, 400);

    cellData = regionprops(cellMask, 'Centroid', 'PixelIdxList');

    cellTracker = assignToTrack(cellTracker, iT, cellData);

    %Find spots
    spotMask = detectSpots(currFrame(:, :, 3), ...
        cellMask, 3, 2, 3, 10);
   
    showoverlay(currFrame(:, :, 3), spotMask)
    drawnow

end


clearvars
clc

nd2 = ND2reader('20211208_polyIC_.nd2');
%%
vid = VideoWriter('test.avi');
vid.FrameRate = 10;
open(vid)

for iT = 1:nd2.sizeT
    
    currFrame = zeros(nd2.height, nd2.width, 2);
    for iZ = 1:nd2.sizeZ
        currFrame = max(currFrame, double(getImage(nd2, 1, iT, 1)));
    end

    cellMask = currFrame(:, :, 2) > 700;
    cellMask = imopen(cellMask, strel('disk', 5));
    cellMask = imfill(cellMask, 'holes');
    %showoverlay(currFrame(:, :, 2), cellMask)

    cellData = regionprops(cellMask, 'PixelIdxList');
    cellPixels = {cellData.PixelIdxList};

    %Detect spots
    spotMaskRed = detectSpots(currFrame(:, :, 1), cellMask, 2, 4, 10);
    IoutRed = showoverlay(currFrame(:, :, 1), spotMaskRed);

    spotMaskGreen = detectSpots(currFrame(:, :, 2), cellMask, 2, 4, 10);
    IoutGreen = showoverlay(currFrame(:, :, 2), spotMaskGreen);

    %How many green spots within x radius of a red spot?
    redSpotData = regionprops(spotMaskRed, 'Centroid', 'PixelIdxList');
    %greenSpotData = regionprops(spotMaskGreen, 'PixelIdxList');

    for iRedSpot = 1:numel(redSpotData)

        %Find which cell this spot is in
        for iCell = 1:numel(cellData)
            inSet = ismember(redSpotData(iRedSpot).PixelIdxList, cellPixels{iCell});

            if any(inSet)
                break
            end
        end
    
        %Find green spots near a red spot
        currRedSpotMask = false(size(spotMaskRed));
        currRedSpotMask(redSpotData(iRedSpot).PixelIdxList) = true;
        currRedSpotMask = imdilate(currRedSpotMask, strel('disk', 15));
        
        intersectMask = currRedSpotMask .* spotMaskGreen;
        %imshow(intersectMask)

        cc = bwconncomp(intersectMask);
        numGreenSpots(iRedSpot) = cc.NumObjects;
        
        %Find number of green spots at other locations in the cell                
        currRedSpotMask(cellPixels{iCell}) = ~currRedSpotMask(cellPixels{iCell});

        intersectMask = currRedSpotMask .* spotMaskGreen;
        ccOutside = bwconncomp(intersectMask);
        numGreenSpotsOutside(iRedSpot) = cc.NumObjects;

        imshow(intersectMask)
    end

    %Collect spot data into a data structure
    spotData(iT).NumGreenSpots = numGreenSpots;

    for iRedSpot = 1:numel()
        spotData(iT).redSpotPixelIdxList = {redSpotData.PixelIdxList};
        spotData(iT).greenSpotPixelIdxList = {redSpotData.PixelIdxList};
    end
    Iout = imfuse(spotMaskRed, spotMaskGreen);

    writeVideo(vid, Iout)

end
close(vid)

greenSpotSize = 3;
greenSpotThreshold = 4;
greenSpotMinSpotArea = 10;
greenSpotSBR = 3;

iT = 30;
SBR = 3;

currFrame = zeros(nd2.height, nd2.width, 2);
for iZ = 1:nd2.sizeZ
    currFrame = max(currFrame, double(getImage(nd2, 1, iT, 1)));
end

cellMask = currFrame(:, :, 2) > 800;
cellMask = imopen(cellMask, strel('disk', 5));
cellMask = imfill(cellMask, 'holes');

spotMaskGreen = detectSpots(currFrame(:, :, 2), cellMask,...
    greenSpotSize, greenSpotThreshold, greenSpotMinSpotArea);

%Get cell and spot data
cellData = regionprops(cellMask, currFrame(:, :, 2), 'MeanIntensity', 'PixelIdxList');
greenSpotData = regionprops(spotMaskGreen, currFrame(:, :, 2), 'MeanIntensity', 'PixelIdxList');

%Filter spots by cell SBR
finalSpotMask = false(size(spotMaskGreen));

for iCell = 1:numel(cellData)    
    for iGreenSpot = 1:numel(greenSpotData)
        if (greenSpotData(iGreenSpot).MeanIntensity / cellData(iCell).MeanIntensity) > SBR

            finalSpotMask(greenSpotData(iGreenSpot).PixelIdxList) = true;

        end
    end
end

showoverlay(currFrame(:, :, 2), finalSpotMask, 'opacity', 40)





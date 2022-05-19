function spotMask = detectSpots(imageIn, cellMask, minSpotSize, spotSensitivity, spotThreshold, minSpotArea)

imageIn = double(imageIn);

sigma1 = (1 / (1 + sqrt(2))) * minSpotSize;
sigma2 = sqrt(2) * sigma1;

g1 = imgaussfilt(imageIn, sigma1);
g2 = imgaussfilt(imageIn, sigma2);

dogImg = imcomplement(g2 - g1);

[nCnts, xBins] = histcounts(dogImg(:));
xBins = diff(xBins) + xBins(1:end-1);

gf = fit(xBins', nCnts', 'gauss1');

spotBg = gf.b1 + spotSensitivity .* gf.c1;

%Segment the spots
spotMask = dogImg > spotBg;

%Remove spots outside cells
spotMask(~cellMask) = false;
spotMask = bwareaopen(spotMask, minSpotArea);
spotMask = imfill(spotMask, 'holes');
spotMask = imclose(spotMask, [1 1 1; 1 1 1; 1 1 1]);

dd = -bwdist(~spotMask);
% dd = imhmin(dd, 1);
LL = watershed(dd);

spotMask(LL == 0) = false;

%Filter spots by mean cell intensity
cellData = regionprops(cellMask, 'PixelIdxList');

for iCell = 1:numel(cellData)

    %Check if spots are significantly different compared to cell background
    currCellMask = false(size(spotMask));
    currCellMask(cellData(iCell).PixelIdxList) = true;

    currCellNoSpots = currCellMask;
    currCellNoSpots(spotMask) = false;

    meanCellIntensity = mean(imageIn(currCellNoSpots));

    currCellSpotMask = currCellMask & spotMask;
        
    spotData = regionprops(currCellSpotMask, imageIn, 'meanIntensity', 'PixelIdxList');

    allInt = [spotData.MeanIntensity];
    isSpotValid = allInt > spotThreshold * meanCellIntensity;

    for iSpot = find(~isSpotValid)

        spotMask(spotData(iSpot).PixelIdxList) = false;

    end

end

function spotMask = detectSpots(imageIn, cellMask, minSpotSize, spotThreshold, minSpotArea)

imageIn = double(imageIn);

sigma1 = (1 / (1 + sqrt(2))) * minSpotSize;
sigma2 = sqrt(2) * sigma1;

g1 = imgaussfilt(imageIn, sigma1);
g2 = imgaussfilt(imageIn, sigma2);

dogImg = imcomplement(g2 - g1);

[nCnts, xBins] = histcounts(dogImg(:));
xBins = diff(xBins) + xBins(1:end-1);

gf = fit(xBins', nCnts', 'gauss1');

spotBg = gf.b1 + spotThreshold .* gf.c1;

%Segment the spots
spotMask = dogImg > spotBg;

%Remove spots outside cells
spotMask(~cellMask) = false;
spotMask = bwareaopen(spotMask, minSpotArea);
spotMask = imfill(spotMask, 'holes');
spotMask = imclose(spotMask, [1 1 1; 1 1 1; 1 1 1]);



% dd = -bwdist(~spotMask);
% LL = watershed(dd);

%spotMask(LL == 0) = false;

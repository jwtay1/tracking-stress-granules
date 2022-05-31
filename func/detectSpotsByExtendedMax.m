function spotMask = detectSpotsByExtendedMax(spotImage, maxLevel, cellMask, thLevel)
%DETECTSPOTSBYEXTENDEDMAX  Detect spots in images using extended max
%
%  SPOTMASK = DETECTSPOTSBYEXTENDEDMAX(IMAGE, LVL) detects spots in an
%  image using the extended maximum algorithm. The function returns a
%  binary mask which will be true where spots are detected and false
%  everywhere else.
% 
%  The extended maximum algorithm works as follows: The input image is
%  first filtered using a gaussian filter (std deviation of 1.5). An
%  extended maximum transform is then carried out whih identifies connect
%  components of pixels with a constant intensity value and are bordered by
%  pixels with a lower value. LVL is the value used to determine if the
%  region is sufficiently bright to be considered a local maxima. Finally,
%  the resulting transform is filtered to remove regions which are less
%  than two pixels and greater than 20 pixels in area.

spotImage = imgaussfilt(spotImage, 0.5);

spotImageFilt = imtophat(spotImage, strel('disk', 3));

spotMask = imextendedmax(spotImageFilt, maxLevel);
%spotMask = imextendedmax(spotImage, 180);

dd = -bwdist(~spotMask);
%dd(~mask) = -Inf;
LL = watershed(dd);

spotMask(LL == 0) = 0;

% imshow(spotMask)
spotMask = bwareafilt(spotMask, [1 15]);

spotData = regionprops(spotMask, spotImage, ...
    'PixelIdxLIst', 'MeanIntensity', 'MaxIntensity');

allMeanInt = cat(1, spotData.MeanIntensity);
allMaxInt = cat(1, spotData.MaxIntensity);

%Mean cell intensity
% meanCellInt = prctile(spotImage(cellMask & ~spotMask), 90, 'all');
% delIdx = find(allMeanInt < (thLevel * meanCellInt));

delIdx = find(allMaxInt < thLevel);

for jj = 1:numel(delIdx)

    spotMask(spotData(delIdx(jj)).PixelIdxList) = false;

end

end
function cellMask = identifyCells(cellImage, thresholdLvl)

cellImage = imgaussfilt(cellImage, 3);

cellMask = cellImage > thresholdLvl;

% cellMarker = imextendedmin(cellImage, 80);
% cellMarker(~cellMask) = false;
% 
% %Try to merge regions together
% cellMarker = imdilate(cellMarker, strel('disk', 15));
% cellMarker = bwmorph(cellMarker, 'thin', 10);
% 
% cellMarker = bwareafilt(cellMarker, [1000 5000]);

%Marker-based watershed
dd = -bwdist(~cellMask);
dd(~cellMask) = -Inf;

dd = imhmin(dd, 5);

%  dd = imimposemin(dd, cellMarker);

LL = watershed(dd);

cellMask(LL == 0) = 0;

cellMask = bwareaopen(cellMask, 1000);

end
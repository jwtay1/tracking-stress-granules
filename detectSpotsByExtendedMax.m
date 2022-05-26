function spotMask = detectSpotsByExtendedMax(spotImage, maxLevel)

spotImage = imgaussfilt(spotImage, 1.5);
spotMask = imextendedmax(spotImage, maxLevel);
spotMask = bwareafilt(spotMask, [2 20]);

end
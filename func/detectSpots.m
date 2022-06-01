function spotMask = detectSpots(spotImage, sensitivity)
%DETECTSPOTS  Detect spots in images
%
%  SPOTMASK = DETECTSPOTS(IMAGE, LVL) detects spots in an image. The
%  function returns a binary mask which will be true where spots are
%  detected and false everywhere else.
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
spotImageFilt = imtophat(spotImage, strel('disk', 2));
spotMask = spotImageFilt > sensitivity;

spotMask = bwareafilt(spotMask, [2 Inf]);

end
clearvars
clc

nd2 = ND2reader('20211208_polyIC_.nd2');

iT = 52;
minSpotSize = 3;
spotThreshold = 15;

%Get the MIP
currFrame = zeros(nd2.height, nd2.width, 2);
for iZ = 1:nd2.sizeZ
    currFrame = max(currFrame, double(getImage(nd2, 1, iT, 1)));
end

imshow(currFrame(:, :, 2), [])

%% Run initial spot detection
imageIn = double(currFrame(:, :, 2));

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

showoverlay(currFrame(:, :, 2), spotMask, 'Opacity', 40)

spotData = regionprops(spotMask, 'Centroid');

%% Add refined spot detection
tic;
%Declare the 2D Gaussian surface model
gauss2Dmodel = fittype('A * exp(-( ((xx - B).^2)/(2*D^2) + ((yy - C).^2)/(2*E.^2) )) - F',...
    'independent', {'xx', 'yy'});

%Generate the x-data and y-data axes
fitSize = [5 5];
xdata = 1:fitSize(1);
ydata = 1:fitSize(2);
[xdata, ydata] = meshgrid(xdata, ydata);

%Initialize a matrix of NaNs (not-a-numbers) to store the position data
storeFitData = struct;
nP = 0;  %Counter of number of found particles

for iP = 1:numel(spotData)
    
    currSpotCenter = round(spotData(iP).Centroid);

    %Check that spot is not too close to edge of images
    if (any((currSpotCenter - fitSize) < 0)) || ...
            (any( (currSpotCenter + fitSize) > [nd2.width, nd2.height] ))
        
        imshow(currFrame(:, :, 2), [])
        hold on
        plot(currSpotCenter(1), currSpotCenter(2), 'rx')
        hold off

        keyboard
        continue
    end

    %Crop a 5x5 image around each particle
    Icrop = double(...
        imageIn( (currSpotCenter(2) - floor(fitSize(1)/2)):(currSpotCenter(2) + floor(fitSize(1)/2)),...
        (currSpotCenter(1) - floor(fitSize(2)/2)):(currSpotCenter(1) + floor(fitSize(2)/2)) ));
    
%     imshow(Icrop, [])

    %Fit the surface - with a guess to the starting values
    [fitObj, gof] = fit([xdata(:), ydata(:)], Icrop(:), gauss2Dmodel, ...
        'StartPoint', [max(Icrop(:)), 3, 3, 2, 2, 0]);
    
    %Save the fitted positions (remember to correct for the offset since we
    %cropped the image)
    storeFitData(nP + 1).Amplitude = fitObj.A;
    storeFitData(nP + 1).Center = [fitObj.B, fitObj.C] + [currSpotCenter(1) - 2, currSpotCenter(2) - 2];
    storeFitData(nP + 1).WidthX = fitObj.D;
    storeFitData(nP + 1).WidthY = fitObj.E;
    storeFitData(nP + 1).Background = fitObj.F;
    storeFitData(nP + 1).R2 = gof.rsquare;
    
    %Increment the counter
    nP = nP + 1;
end

toc

%% Filter data

%Make a copy of data before filtering
filteredData = storeFitData;

%Remove spots with low Goodness-of-Fit
allGOF = [storeFitData.R2];
histogram(allGOF)

isFiltered = allGOF < 0.4;

storeFitDataRemoved = filteredData(isFiltered);
filteredData(isFiltered) = [];

%Remove spots which are too dim compared to background
bgValue = prctile(currFrame(:, :, 2), 70, 'all');

allAmplitude = [filteredData.Amplitude];

isFiltered = allAmplitude < bgValue;

storeFitDataRemoved((end + 1):(end + nnz(isFiltered))) = filteredData(isFiltered);
filteredData(isFiltered) = [];

%% Make some plots

imshow(currFrame(:, :, 2), []);

hold on

for ii = 1:numel(filteredData)

    plot(filteredData(ii).Center(1), filteredData(ii).Center(2), 'x')

end
hold off



function fittedData = fitSpots(imageIn, spotData, fitSize)


%Declare the 2D Gaussian surface model
gauss2Dmodel = fittype('A * exp(-( ((xx - B).^2)/(2*D^2) + ((yy - C).^2)/(2*E.^2) )) - F',...
    'independent', {'xx', 'yy'});

%Generate the x-data and y-data axes
fitSize = [fitSize, fitSize];
xdata = 1:fitSize(1);
ydata = 1:fitSize(2);
[xdata, ydata] = meshgrid(xdata, ydata);

%Initialize a matrix of NaNs (not-a-numbers) to store the position data
fittedData = struct;
nP = 0;  %Counter of number of found particles

for iP = 1:numel(spotData)
    
    currSpotCenter = round(spotData(iP).Centroid);

%     %Check that spot is not too close to edge of images
%     if (any((currSpotCenter - fitSize) < 0)) || ...
%             (any( (currSpotCenter + fitSize) > [nd2.width, nd2.height] ))
%         
%         imshow(currFrame(:, :, 2), [])
%         hold on
%         plot(currSpotCenter(1), currSpotCenter(2), 'rx')
%         hold off
% 
%         keyboard
%         continue
%     end

    %Crop a 5x5 image around each particle
    Icrop = double(...
        imageIn( (currSpotCenter(2) - floor(fitSize(1)/2)):(currSpotCenter(2) + floor(fitSize(1)/2)),...
        (currSpotCenter(1) - floor(fitSize(2)/2)):(currSpotCenter(1) + floor(fitSize(2)/2)) ));
    
%     imshow(Icrop, [])

    %Fit the surface - with a guess to the starting values
    [fitObj, gof] = fit([xdata(:), ydata(:)], Icrop(:), gauss2Dmodel, ...
        'StartPoint', [max(Icrop(:)), 3, 3, 2, 2, 0]);
%     fitObj
% 
%     figure(1);
%     subplot(1, 2, 1)
%     imshow(Icrop, [])
% 
%     subplot(1, 2, 2)
%     plot(fitObj, [xdata(:), ydata(:)], Icrop(:))
%     keyboard

    
    %Save the fitted positions (remember to correct for the offset since we
    %cropped the image)
    fittedData(nP + 1).Amplitude = fitObj.A;
    fittedData(nP + 1).Center = [fitObj.B, fitObj.C] + [currSpotCenter(1) - 2, currSpotCenter(2) - 2];
    fittedData(nP + 1).WidthX = fitObj.D;
    fittedData(nP + 1).WidthY = fitObj.E;
    fittedData(nP + 1).Background = fitObj.F;
    fittedData(nP + 1).R2 = gof.rsquare;
    
    %Increment the counter
    nP = nP + 1;
end
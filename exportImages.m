function exportImages(inputMATfile, outputDir, ROI, spotID, frames, varargin)

ip = inputParser;
% addParameter(ip, 'redChannel', 2);
% addParameter(ip, 'greenChannel', 3);

addParameter(ip, 'redChannelNormRange', [500 7500]);
addParameter(ip, 'greenChannelNormRange', [3000 23000]);
addParameter(ip, 'nearDist', 100);

parse(ip, varargin{:});

load(inputMATfile, 'spotTracker', 'inputFile', 'frameData');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end


nd2 = ND2reader(inputFile);

if nd2.sizeC == 2
    chRed = 1;
    chGreen = 2;
elseif nd2.sizeC == 3
    chRed = 2;
    chGreen = 3;
end

currSpotData = getTrack(spotTracker, spotID);

for iT = frames

    I = calculateMIP(nd2, 1, iT);

    ch2IntRange = ip.Results.redChannelNormRange;
    ch3IntRange = ip.Results.greenChannelNormRange;

    Icrop_red = I(:, :, chRed);
    Icrop_red = Icrop_red(ROI(2):ROI(4), ROI(1):ROI(3));

    Icrop_green = I(:, :, chGreen);
    Icrop_green = Icrop_green(ROI(2):ROI(4), ROI(1):ROI(3));

    Icrop_red_norm = double(Icrop_red);
    Icrop_red_norm = (Icrop_red_norm - (min(ch2IntRange)))/(max(ch2IntRange) - min(ch2IntRange));
    Icrop_red_norm(Icrop_red_norm > 1) = 1;
    Icrop_red_norm(Icrop_red_norm < 0) = 0;

    Icrop_green_norm = double(Icrop_green);
    Icrop_green_norm = (Icrop_green_norm - (min(ch3IntRange)))/(max(ch3IntRange) - min(ch3IntRange));
    Icrop_green_norm(Icrop_green_norm > 1) = 1;
    Icrop_green_norm(Icrop_green_norm < 0) = 0;

    Ired = Icrop_red_norm;
    Igreen = Icrop_green_norm;
    Iblue = Icrop_red_norm;

    Irgb = cat(3, Ired, Igreen, Iblue);

    %Plot markers to show the position of the spots
    idx = find(currSpotData.Frames == iT);

    figure(1);
    set(gcf, 'Position', [1960 72 1022 762])
    imshow(Irgb, [])
    hold on
    if ~isempty(idx)

        plot(currSpotData.Centroid(idx, 1) - ROI(1), currSpotData.Centroid(idx, 2) - ROI(2), 'yo', ...
            'LineWidth', 1)
        
%         if iT == frames(1)
            
            %Plot a circle
            viscircles(currSpotData.Centroid(idx, :) - ROI(1:2), ip.Results.nearDist, ...
                'LineStyle', '--', 'Color', 'white')            
            
%         end
        

        if frameData(iT).NumGreenSpots >= 1

            greenPos = cat(1, frameData(iT).spotDataGreen.Centroid);

            %Filter spots outside of ROI
            greenPos(greenPos(:, 1) < ROI(1) | ...
                greenPos(:, 1) > ROI(3) | ...
                greenPos(:, 2) < ROI(2) | ...
                greenPos(:, 2) > ROI(4), :) = [];

            plot(greenPos(:, 1) - ROI(1), greenPos(:, 2) - ROI(2), 's', ...
                'MarkerEdgeColor', [0 90 181]/255, 'LineWidth', 2)

        end

    end

    hold off

    saveas(gcf, fullfile(outputDir,...
        sprintf('export_spot%.0f_frame%.0f.svg', spotID, iT)));

    %Distance to green spot
    if ~isempty(idx) && exist('greenPos', 'var')
        distToGreen = sqrt(sum((currSpotData.Centroid(idx, :) - greenPos).^2, 2));

        binEdges = 0:20:200;

        %Make a histogram showing number of spots close to the red spot
        figure(2);
        set(gcf, 'Position', [1957 424 668 515])
        histogram(distToGreen, 'binEdges', binEdges)
        saveas(gcf, fullfile(outputDir,...
            sprintf('histogram_spot%.0f_frame%.0f.svg', spotID, iT)));
    end

    %Also export raw images and masks
    imwrite(Icrop_red_norm, fullfile(outputDir, sprintf('chRed_spot%.0f_frame%.0f.png', spotID, iT)), 'Compression', 'none');
    imwrite(Icrop_green_norm, fullfile(outputDir, sprintf('chGreen_spot%.0f_frame%.0f.png', spotID, iT)), 'Compression', 'none');
    
    clearvars greenPos

end

%Plot
dT = round(mean(diff(nd2.getTimestamps(1, 1))/60));

timeVec = frames * dT;

numGreenSpots = [frameData(frames).NumGreenSpots];
numRedSpots = [frameData(frames).NumRedSpots];

figure(3)
yyaxis left
plot(timeVec, numGreenSpots)

yyaxis right
plot(timeVec, numRedSpots)


saveas(gcf, fullfile(outputDir,...
            sprintf('numSpots_spot%.0f_frame%.0f.svg', spotID, iT)));
        







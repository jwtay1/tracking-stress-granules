clearvars
clc

load('D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220523\trackedData.mat', ...
    'spotTracker', 'filename', 'frameData');

nd2 = ND2reader(filename);

%%

%Figure for spot at edge
roi = [92 547 376 724];
spotID = 15;
frames = [92 97 102 107 112];

% %Figure with spot at center
% roi = [419 90 616 257];
% spotID = 6;
% frames = [51 56 61 66 71];

currSpotData = getTrack(spotTracker, spotID);
%%

for iT = frames


    I = calculateMIP(nd2, iT);

    ch2IntRange = [500, 7500];
    ch3IntRange = [3000, 13000];

    Icrop_red = I(:, :, 2);
    Icrop_red = Icrop_red(roi(2):roi(4), roi(1):roi(3));

    Icrop_green = I(:, :, 3);
    Icrop_green = Icrop_green(roi(2):roi(4), roi(1):roi(3));

    ch2Norm = double(Icrop_red);
    ch2Norm = (ch2Norm - (min(ch2IntRange)))/(max(ch2IntRange) - min(ch2IntRange));
    ch2Norm(ch2Norm > 1) = 1;
    ch2Norm(ch2Norm < 0) = 0;

    ch3Norm = double(Icrop_green);
    ch3Norm = (ch3Norm - (min(ch3IntRange)))/(max(ch3IntRange) - min(ch3IntRange));
    ch3Norm(ch3Norm > 1) = 1;
    ch3Norm(ch3Norm < 0) = 0;

    Ired = ch2Norm;
    Igreen = ch3Norm;
    Iblue = ch2Norm;

    Irgb = cat(3, Ired, Igreen, Iblue);

    %Plot markers to show the position of the spots
    idx = find(currSpotData.Frames == iT);

    figure(1);
    set(gcf, 'Position', [1960 72 1022 762])
    imshow(Irgb, [])
    hold on
    if ~isempty(idx)

        plot(currSpotData.Centroid(idx, 1) - roi(1), currSpotData.Centroid(idx, 2) - roi(2), 'yo', ...
            'LineWidth', 1)

        if frameData(iT).NumGreenSpots >= 1

            greenPos = cat(1, frameData(iT).spotDataGreen.Centroid);

            %Filter spots outside of ROI
            greenPos(greenPos(:, 1) < roi(1) | ...
                greenPos(:, 1) > roi(3) | ...
                greenPos(:, 2) < roi(2) | ...
                greenPos(:, 2) > roi(4), :) = [];

            plot(greenPos(:, 1) - roi(1), greenPos(:, 2) - roi(2), 's', ...
                'MarkerEdgeColor', [0 90 181]/255, 'LineWidth', 2)

        end

    end

    hold off

    saveas(gcf, fullfile('D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220523\',...
        sprintf('export_spot%.0f_frame%.0f.png', spotID, iT)));

  
    %Distance to green spot
    if ~isempty(idx) 
    distToGreen = sqrt(sum((currSpotData.Centroid(idx, :) - greenPos).^2, 2));

    binEdges = 0:20:200;

    %Make a histogram showing number of spots close to the red spot
    figure(2);
    set(gcf, 'Position', [1957 424 668 515])
    histogram(distToGreen, 'binEdges', binEdges)
    saveas(gcf, fullfile('D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220523\',...
        sprintf('histogram_spot%.0f_frame%.0f.png', spotID, iT)));
    end


end

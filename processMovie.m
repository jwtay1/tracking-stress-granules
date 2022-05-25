clearvars
clc

filename = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\data\crop\20220311_polyic_xy3.nd2';

outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\20220524';

% function processMovie(filename, outputDir, varargin)
% 
% ip = inputParser;
% addParameter(ip, 'redChannel', 2);
% addParameter(ip, 'redChannelNormRange', [500 7500]);
% 
% addParameter(ip, 'greenChannel', 3);
% addParameter(ip, 'greenChannelNormRange', [3000 23000]);
% 
% parse(ip, varargin{:});

iXY = 1;

chRed = 1;
chGreen = 2;

%Parameters
minSpotSize = 3;
spotThreshold = 15;

%Intensities to normalize images to in movie
ch2IntRange = [500, 4000];
ch3IntRange = [1000, 27000];

greenSpotSensitivity = 200;
redSpotSensitivity = 1200;

frames = 20:38;

%frames = 25;


% %Cell tracking parameters
% cellTracker = LAPLinker;
% cellTracker.LinkedBy = 'Centroid';
% %cellTracker.LinkCostMetric = 'pxintersect';
% cellTracker.LinkScoreRange = [0 50];
% cellTracker.MaxTrackAge = 1;

%Spot tracking parameters
spotTracker = LAPLinker;
spotTracker.LinkedBy = 'Centroid';
spotTracker.LinkScoreRange = [0 50];
spotTracker.MaxTrackAge = 4;

%% Process data

nd2 = ND2reader(filename);
%nd2 = BioformatsImage(filename);

%Setup output filename and directory
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

[~, outputFN] = fileparts(filename);

%Create a new video
vid = VideoWriter(fullfile(outputDir, [outputFN, '.avi']));
vid.FrameRate = 15;
open(vid)

%Create a structure to hold data
frameData = struct;

for iT = frames%1:nd2.sizeT

    %Get the MIP
    mip = calculateMIP(nd2, iXY, iT);

    %Mask cells
%     cellMask = identifyCells(mip(:, :, 1), 800);
    % showoverlay(mip(:, :, 1), bwperim(cellMask));

    %Detect spots in each channel
    spotMask_Red = detectSpotsByExtendedMax(mip(:, :, chRed), redSpotSensitivity);
    spotMask_Green = detectSpotsByExtendedMax(mip(:, :, chGreen), greenSpotSensitivity);
    %showoverlay(mip(:, :, chGreen), spotMask_Green, 'Opacity', 10)

    %Get data from red spots
    dataSpot_Red = regionprops(spotMask_Red, mip(:, :, chRed), 'Centroid', 'MeanIntensity');
    dataSpot_Green = regionprops(spotMask_Green, mip(:, :, chGreen), 'Centroid', 'MeanIntensity');

    %Collect data from current frame
    frameData(iT).NumRedSpots = numel(dataSpot_Red);
    frameData(iT).NumGreenSpots = numel(dataSpot_Green);
    frameData(iT).spotDataGreen = dataSpot_Green;
    frameData(iT).spotDataRed = dataSpot_Red;

    if ~isempty(dataSpot_Red)

        %Measure spot distance to green
        for iSR = 1:numel(dataSpot_Red)

            if ~isempty(dataSpot_Green)

                allPos = cat(1, dataSpot_Green.Centroid);

                dataSpot_Red(iSR).distToGreen = ...
                    sqrt(sum((allPos - dataSpot_Red(iSR).Centroid).^2, 2));
                
            else

                dataSpot_Red(iSR).distToGreen = [NaN];

            end

        end

        %Track the red spots
        spotTracker = assignToTrack(spotTracker, iT, dataSpot_Red);

    end
    



    %Collect spot information
%     cellData = regionprops(cellMask, 'Centroid', 'PixelIdxList');

%     for ii = 1:numel(cellData)
% 
%         currCellMask = false(size(cellMask));
%         currCellMask(cellData(ii).PixelIdxList) = true;
%         
%         %Add spot counts and location
%         curr_spotMask_Red = spotMask_Red & currCellMask;
%         redSpotData = regionprops(curr_spotMask_Red, mip(:, :, 2), 'MaxIntensity', 'Centroid');
% 
%         cellData(ii).NumRedSpots = numel(redSpotData);
%         cellData(ii).RedSpotsPos = cat(1, redSpotData.Centroid);
%         cellData(ii).RedSpotsInt = cat(1, redSpotData.MaxIntensity);
% 
%         curr_spotMask_Green = spotMask_Green & currCellMask;
%         greenSpotData = regionprops(curr_spotMask_Green, mip(:, :, 3), 'MaxIntensity', 'Centroid');
%         
%         cellData(ii).NumGreenSpots = numel(greenSpotData);
%         cellData(ii).GreenSpotsPos = cat(1, greenSpotData.Centroid);
%         cellData(ii).GreenSpotsInt = cat(1, greenSpotData.MaxIntensity);
% 
%     end

%     %Track cells
%     cellTracker = assignToTrack(cellTracker, iT, cellData);


    %Generate an image
    ch2Norm = double(mip(:, :, chRed));
    ch2Norm = (ch2Norm - (min(ch2IntRange)))/(max(ch2IntRange) - min(ch2IntRange));
    ch3Norm = double(mip(:, :, chGreen));
    ch3Norm = (ch3Norm - (min(ch2IntRange)))/(max(ch2IntRange) - min(ch2IntRange));

    Ired = ch2Norm;
    Igreen = ch3Norm;
    Iblue = ch2Norm;

    Irgb = cat(3, Ired, Igreen, Iblue);

    %Overlay masks
%    Iout = showoverlay(Irgb, bwperim(cellMask), 'Opacity', 1000, 'Color', [1 1 1]);
    Iout = showoverlay(Irgb, spotMask_Red, 'Opacity', 40, 'Color', [1 1 0]);
    Iout = showoverlay(Iout, spotMask_Green, 'Opacity', 40, 'Color', [0 1 1]);

    Iout = uint16(Iout * 65535);

%     %Label cells
%     for iAT = 1:numel(cellTracker.activeTrackIDs)
%         currAT = getTrack(cellTracker, cellTracker.activeTrackIDs(iAT));
%         Iout = insertText(Iout, currAT.Centroid(end, :), int2str(cellTracker.activeTrackIDs(iAT)));
%     end

    %Label spots
    for iAT = 1:numel(spotTracker.activeTrackIDs)
        currAT = getTrack(spotTracker, spotTracker.activeTrackIDs(iAT));
        Iout = insertText(Iout, currAT.Centroid(end, :), int2str(spotTracker.activeTrackIDs(iAT)));
    end

    Iout = im2double(Iout);

    writeVideo(vid, Iout)

end

close(vid)

%% Data analysis
% 
% track1 = getTrack(cellTracker, 2);
% 
% plot(track1.Frames, track1.NumRedSpots, 'r-', track1.Frames, track1.NumGreenSpots, 'g-');

% %Count number of spots within a 200 px radius
% validRadius = 200;
% currSpot = 6;
% 
% currSpotData = getTrack(spotTracker, 6);
% 
% for iT = 1:numel(currSpotData.distToGreen)
% 
%     numGreenWithinRadius(iT) = numel(currSpotData.distToGreen{iT} <= validRadius);
% 
% end
% 
% plot(currSpotData.Frames, numGreenWithinRadius)
% xlabel('Frames')
% ylabel('Number of green spots within 200px radius')
% title('Red spot #6')
% 
% 
% %%
% 
% %Plot number of red and green spots over time
% tt = 1:nd2.sizeT;
% 
% figure(2)
% yyaxis left
% plot(tt, [frameData.NumRedSpots])
% ylabel('Number of red spots')
% 
% yyaxis right
% plot(tt, [frameData.NumGreenSpots])
% ylabel('Number of green spots')
% xlabel('Frames')
% title('Number of spots in frame')

%% Save data


save(fullfile(outputDir, ['trackedData_', outputFN, '.mat']), 'frameData', 'spotTracker', 'filename')


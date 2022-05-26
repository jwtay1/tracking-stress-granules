function processMovie(inputFile, outputDir, cellMaskFile, varargin)

ip = inputParser;
% addParameter(ip, 'redChannel', 2);
% addParameter(ip, 'greenChannel', 3);

addParameter(ip, 'redChannelNormRange', [500 7500]);
addParameter(ip, 'greenChannelNormRange', [3000 23000]);
addParameter(ip, 'minSpotSize', 3);
addParameter(ip, 'spotThreshold', 15);
addParameter(ip, 'greenSpotSensitivity', 200);
addParameter(ip, 'redSpotSensitivity', 1200);
addParameter(ip, 'frames', 20:38);
parse(ip, varargin{:});

%Spot tracking parameters
spotTracker = LAPLinker;
spotTracker.LinkedBy = 'Centroid';
spotTracker.LinkScoreRange = [0 50];
spotTracker.MaxTrackAge = 4;

%% Process data
nd2 = ND2reader(inputFile);

%Set up channels
if nd2.sizeC == 2
    chRed = 1;
    chGreen = 2;
elseif nd2.sizeC == 3
    chRed = 2;
    chGreen = 3;
end

%Setup output filename and directory
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

[~, outputFN] = fileparts(cellMaskFile);

%Create a new video
vid = VideoWriter(fullfile(outputDir, [outputFN, '.avi']));
vid.FrameRate = 15;
open(vid)

%Create a structure to hold data
frameData = struct;

for iT = ip.Results.frames

    %Get the MIP
    mip = calculateMIP(nd2, 1, iT);

    %Read the mask file
    cellMask = imread(cellMaskFile, iT - ip.Results.frames(1) + 1);
    cellMask = cellMask > 0;

    %Detect spots in each channel
    spotMask_Red = detectSpotsByExtendedMax(mip(:, :, chRed), ip.Results.redSpotSensitivity);
    spotMask_Green = detectSpotsByExtendedMax(mip(:, :, chGreen), ip.Results.greenSpotSensitivity);
    %showoverlay(mip(:, :, chGreen), spotMask_Green, 'Opacity', 10)
    
    spotMask_Red(~cellMask) = false;
    spotMask_Green(~cellMask) = false;
    
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

    ch2IntRange = ip.Results.redChannelNormRange;
    ch3IntRange = ip.Results.greenChannelNormRange;

    %Generate an image
    ch2Norm = double(mip(:, :, chRed));
    ch2Norm = (ch2Norm - (min(ch2IntRange)))/(max(ch2IntRange) - min(ch2IntRange));
    ch3Norm = double(mip(:, :, chGreen));
    ch3Norm = (ch3Norm - (min(ch3IntRange)))/(max(ch3IntRange) - min(ch3IntRange));

    Ired = ch2Norm;
    Igreen = ch3Norm;
    Iblue = ch2Norm;

    Irgb = cat(3, Ired, Igreen, Iblue);

    %Overlay masks
    Iout = showoverlay(Irgb, spotMask_Red, 'Opacity', 40, 'Color', [1 1 0]);
    Iout = showoverlay(Iout, spotMask_Green, 'Opacity', 40, 'Color', [0 1 1]);

    Iout = uint16(Iout * 65535);

    %Label spots
    for iAT = 1:numel(spotTracker.activeTrackIDs)
        currAT = getTrack(spotTracker, spotTracker.activeTrackIDs(iAT));
        Iout = insertText(Iout, currAT.Centroid(end, :), int2str(spotTracker.activeTrackIDs(iAT)));
    end

    Iout = im2double(Iout);

    writeVideo(vid, Iout)

end

close(vid)


%% Save data
save(fullfile(outputDir, ['trackedData_', outputFN, '.mat']), 'frameData', 'spotTracker', 'inputFile')



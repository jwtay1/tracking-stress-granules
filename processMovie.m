function processMovie(inputFile, outputDir, cellMaskFile, varargin)
%PROCESSMOVIE  Process specified movie file
%
%  PROCESSMOVIE(FILE, OUPUTDIR, CELLMASK) will process the movie file
%  specified. Processing consists of detecting spots in both the mApple-PKR
%  channel and the GFP-G3BP1 channel, tracking the PKR spots, and computing
%  the distance from the mApple spot to the G3BP1 spots in each frame.
%
%  The output file will be saved in the folder OUTPUTDIR. For each movie,
%  an AVI-file will be created which shows the ID of the tracked PKR spots.
%  A MAT-file will also be saved containing the tracked data. This data can
%  be analyzed using the exportImages script.
%
%  PROCESSMOVIE(..., PARAM, VALUE) allows additional arguments to be passed
%  to the processing function to control processing and spot detection:
%
%  'greenSpotSensitivity' and 'redSpotSensitivity' specifies the intensity
%  difference for a region in an image to be considered a spot.
%
%  'frames' should be a vector specifying which frames in the movie to
%  process.
%
%  See also: exportImages.m

ip = inputParser;
addParameter(ip, 'greenSpotSensitivity', 200);
addParameter(ip, 'redSpotSensitivity', 1200);
addParameter(ip, 'frames', 20:38);
addParameter(ip, 'distThresholdToGreen', 100);
addParameter(ip, 'padding', 0);
parse(ip, varargin{:});

%Spot tracking parameters
spotTracker = LAPLinker;
spotTracker.LinkedBy = 'Centroid';
spotTracker.LinkScoreRange = [0 50];
spotTracker.MaxTrackAge = 4;

%% Process data
%nd2 = ND2reader(inputFile);

mipImages = load(inputFile);

chRed = 1;
chGreen = 2;

% %Set up channels
% if nd2.sizeC == 2
%     chRed = 1;
%     chGreen = 2;
% elseif nd2.sizeC == 3
%     chRed = 2;
%     chGreen = 3;
% end

%Setup output filename and directory
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

[~, outputFN] = fileparts(cellMaskFile);

%Create a new video
vid = VideoWriter(fullfile(outputDir, [outputFN, '.avi']));
vid.FrameRate = 7.5;
open(vid)

%Create a structure to hold data
frameData = struct;

for kk = 1:numel(ip.Results.frames)

    if kk == 1
        totalCellMask = imread(cellMaskFile, kk);
    else
        totalCellMask = totalCellMask | imread(cellMaskFile, kk);
    end

end

totalCellMask = bwareaopen(totalCellMask, 100);

%Find the bounding box of the cell mask
topRow = find(any(totalCellMask, 2), 1, 'first') - ip.Results.padding;
botRow = find(any(totalCellMask, 2), 1, 'last') + ip.Results.padding;

leftCol = find(any(totalCellMask, 1), 1, 'first') - ip.Results.padding;
rightCol = find(any(totalCellMask, 1), 1, 'last') + ip.Results.padding;

maxRedInt = double(max(cellfun(@(x) prctile(x(:, :, chRed), 99.5, 'all'), mipImages.mip)));
minRedInt = double(min(cellfun(@(x) prctile(x(:, :, chRed), 1, 'all'), mipImages.mip)));

maxGreenInt = double(max(cellfun(@(x) prctile(x(:, :, chGreen), 99.9, 'all'), mipImages.mip)));
minGreenInt = double(min(cellfun(@(x) prctile(x(:, :, chGreen), 1, 'all'), mipImages.mip)));

%Make output directory to export images
[~, outputImageDir] = fileparts(inputFile);

if ~exist(fullfile(outputDir, outputImageDir), 'dir')
    mkdir(fullfile(outputDir,outputImageDir))
end


for iT = ip.Results.frames

    %Get the MIP
    %mip = calculateMIP(nd2, 1, iT);
    mip = mipImages.mip{iT - ip.Results.frames(1) + 1};

    %Read the mask file
    cellMask = imread(cellMaskFile, iT - ip.Results.frames(1) + 1);
    cellMask = cellMask > 0;

    %Detect spots in each channel
    spotMask_Red = detectSpots(mip(:, :, chRed), ip.Results.redSpotSensitivity);
    spotMask_Green = detectSpots(mip(:, :, chGreen), ip.Results.greenSpotSensitivity);
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

    ch2IntRange = [minRedInt, maxRedInt];
    ch3IntRange = [minGreenInt, maxGreenInt];

    %Generate an image
    ch2Norm = double(mip(:, :, chRed));
    ch2Norm = (ch2Norm - (min(ch2IntRange)))/(max(ch2IntRange) - min(ch2IntRange));
    ch2Norm(ch2Norm > 1) = 1;
    ch2Norm(ch2Norm < 0) = 0;

    ch3Norm = double(mip(:, :, chGreen));
    ch3Norm = (ch3Norm - (min(ch3IntRange)))/(max(ch3IntRange) - min(ch3IntRange));
    ch3Norm(ch3Norm > 1) = 1;
    ch3Norm(ch3Norm < 0) = 0;

    Ired = ch2Norm;
    Igreen = ch3Norm;
    Iblue = ch2Norm;

    Irgb = cat(3, Ired, Igreen, Iblue);

    %Overlay masks
    %     Iout = showoverlay(Irgb, spotMask_Red, 'Opacity', 40, 'Color', [1 1 0]);
    %     Iout = showoverlay(Iout, spotMask_Green, 'Opacity', 40, 'Color', [0 1 1]);
    Iout = Irgb;

    Iout = uint16(Iout * 65535);

    %Label spots
    for iAT = 1:numel(spotTracker.activeTrackIDs)
        currAT = getTrack(spotTracker, spotTracker.activeTrackIDs(iAT));
        Iout = insertText(Iout, currAT.Centroid(end, :), int2str(spotTracker.activeTrackIDs(iAT)), ...
            'BoxOpacity', 0, 'TextColor', 'blue');
    end

    %Mark spots
    recSize = 10;
    for iGS = 1:numel(frameData(iT).spotDataGreen)
        currPos = cat(1, frameData(iT).spotDataGreen(iGS).Centroid);


        try
        Iout = insertShape(Iout, 'rectangle', ...
            [currPos(:, 1) - recSize/2, currPos(:, 2) - recSize/2, recSize, recSize], ...
            'LineWidth', 2, 'Color', 'yellow');

        catch
            keyboard
        end
    end

    %Mark spots
    circSize = 5;
    for iRS = 1:numel(frameData(iT).spotDataRed)
        currPos = cat(1, frameData(iT).spotDataRed(iRS).Centroid);

        Iout = insertShape(Iout, 'circle', ...
            [currPos(:, 1), currPos(:, 2), circSize], ...
            'LineWidth', 2, 'Color', 'cyan');
    end


    Iout = im2double(Iout);

    %Crop images
    Iout = Iout(topRow:botRow, leftCol:rightCol, :);

    %Rescale image to look better in movie
    IoutRescale = imresize(Iout, 4);
    IoutRescale(IoutRescale > 1) = 1;
    IoutRescale(IoutRescale < 0) = 0;
    writeVideo(vid, IoutRescale)

    ch2Norm = ch2Norm(topRow:botRow, leftCol:rightCol);
    ch3Norm = ch3Norm(topRow:botRow, leftCol:rightCol);

    ch2Norm = cat(3, ch2Norm, zeros(size(ch2Norm)), ch2Norm);

    imwrite(ch2Norm, fullfile(outputDir, outputImageDir, ...
        [outputFN, '_PKR_frame', int2str(iT), '.tif']), ...
        'Compression', 'none')

    ch3Norm = cat(3, zeros(size(ch3Norm)), ch3Norm, zeros(size(ch3Norm)));

    imwrite(ch3Norm, fullfile(outputDir, outputImageDir, ...
        [outputFN, '_G3BP1_frame', int2str(iT), '.tif']), ...
        'Compression', 'none')

    Irgb = Irgb(topRow:botRow, leftCol:rightCol, :);
    imwrite(Irgb, fullfile(outputDir, outputImageDir, ...
        [outputFN, '_merged_frame', int2str(iT), '.tif']), ...
        'Compression', 'none')

    %Create a marked image
    fig = figure;
    imshow(Irgb)
    hold on
    %Mark spots
    recSize = 10;
    for iGS = 1:numel(frameData(iT).spotDataGreen)
        currPos = cat(1, frameData(iT).spotDataGreen(iGS).Centroid);

        plot(currPos(:, 1) - leftCol, currPos(:, 2) - topRow, 'color', [0.9290 0.6940 0.1250], ...
            'LineWidth', 1, 'marker', 's', 'LineStyle', 'none', 'MarkerSize', 15)

    end

    %Mark spots
    circSize = 5;
    if ~isempty(frameData(iT).spotDataRed)

        currPos = cat(1, frameData(iT).spotDataRed(1).Centroid);

        plot(currPos(:, 1) - leftCol, currPos(:, 2) - topRow, 'color', [0.3010 0.7450 0.9330], ...
            'LineWidth', 1, 'marker', 'o', 'LineStyle', 'none', 'MarkerSize', 15)

        %Mark distance threshold
        viscircles([currPos(:, 1) - leftCol, currPos(:, 2) - topRow],...
            ip.Results.distThresholdToGreen, ...
            'EnhanceVisibility', false, ...
            'color', [1, 1, 1], ...
            'LineWidth', 2, 'LineStyle', '--');
    end

    hold off
    saveas(fig, fullfile(outputDir, outputImageDir, ...
        [outputFN, '_merged_frame', int2str(iT), '.svg']))

    close(fig)



    %Make a histogram showing number of spots close to the red spot
    if ~isempty(frameData(iT).spotDataRed) && ~isempty(frameData(iT).spotDataGreen)

        redSpotPos = frameData(iT).spotDataRed(1).Centroid;
        greenSpotPos = cat(1, frameData(iT).spotDataGreen.Centroid);

        distToGreen = sqrt(sum((redSpotPos - greenSpotPos).^2, 2));

        binEdges = 0:10:130;

        fig = figure;
        set(fig, 'Position', [1957 424 668 515])
        histogram(distToGreen, 'binEdges', binEdges)
        xlabel('Distance to dRIF (px)')
        ylabel('Number of G3BP1 detected')
        ylim([0 20])
        xlim([0 130])
        saveas(gcf, fullfile(outputDir, outputImageDir, ...
            [outputFN, '_histogram', int2str(iT), '.svg']))

        close(fig)

    end

end

close(vid)


%% Save data
save(fullfile(outputDir, ['trackedData_', outputFN, '.mat']), 'frameData', 'spotTracker', 'inputFile')



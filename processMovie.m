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
% addParameter(ip, 'redChannelNormRange', [500 7500]);
% addParameter(ip, 'greenChannelNormRange', [3000 23000]);
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

%Find the bounding box of the cell mask
topRow = find(any(totalCellMask, 2), 1, 'first');
botRow = find(any(totalCellMask, 2), 1, 'last');

leftCol = find(any(totalCellMask, 1), 1, 'first');
rightCol = find(any(totalCellMask, 1), 1, 'last');

%Determine intensity range
% maxRedInt = 0.8 * double(max(cellfun(@(x) max(x(:, :, 1), [], 'all'), mipImages.mip)));
% minRedInt = 0.8 * double(min(cellfun(@(x) min(x(:, :, 1), [], 'all'), mipImages.mip)));
% 
% maxGreenInt = 0.8 * double(max(cellfun(@(x) max(x(:, :, 2), [], 'all'), mipImages.mip)));
% minGreenInt = 0.8 * double(min(cellfun(@(x) min(x(:, :, 2), [], 'all'), mipImages.mip)));

maxRedInt = double(max(cellfun(@(x) prctile(x(:, :, 1), 99, 'all'), mipImages.mip)));
minRedInt = double(min(cellfun(@(x) prctile(x(:, :, 1), 1, 'all'), mipImages.mip)));

maxGreenInt = double(max(cellfun(@(x) prctile(x(:, :, 2), 99, 'all'), mipImages.mip)));
minGreenInt = double(min(cellfun(@(x) prctile(x(:, :, 2), 1, 'all'), mipImages.mip)));

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
    spotMask_Red = detectSpotsByExtendedMax(mip(:, :, chRed), ip.Results.redSpotSensitivity, cellMask, 2);
    spotMask_Green = detectSpotsByExtendedMax(mip(:, :, chGreen), ip.Results.greenSpotSensitivity, cellMask, 1.7);
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

        Iout = insertShape(Iout, 'rectangle', ...
            [currPos(:, 1) - recSize/2, currPos(:, 2) - recSize/2, recSize, recSize], ...
            'LineWidth', 2, 'Color', 'yellow');
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

    imwrite(ch2Norm, fullfile(outputDir, outputImageDir, ...
        [outputFN, '_PKR_frame', int2str(iT), '.tif']), ...
        'Compression', 'none')

    imwrite(ch3Norm, fullfile(outputDir, outputImageDir, ...
        [outputFN, '_G3BP1_frame', int2str(iT), '.tif']), ...
        'Compression', 'none')

    Irgb = Irgb(topRow:botRow, leftCol:rightCol, :);
    imwrite(Irgb, fullfile(outputDir, outputImageDir, ...
        [outputFN, '_merged_frame', int2str(iT), '.tif']), ...
        'Compression', 'none')


end

close(vid)


%% Save data
save(fullfile(outputDir, ['trackedData_', outputFN, '.mat']), 'frameData', 'spotTracker', 'inputFile')



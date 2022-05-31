%Workaround for ND2 compatibility issues
clearvars
clc

file = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\data\crop\20220311_polyic_xy5.nd2';
outputDir = 'D:\Projects\ALMC Tickets\T336-Corbet-SpotDetection\results\publication';
frames = 47:57;

reader = ND2reader(file);

if reader.sizeC == 2
    chRed = 1;
    chGreen = 2;
else
    chRed = 2;
    chGreen = 3;
end

mip = cell(1, numel(frames));

for iT = frames

    mip{iT - frames(1) + 1} = calculateMIP(reader, 1, iT);

end

[~, outputFN] = fileparts(file);

save(fullfile(outputDir, [outputFN, '.mat']), 'mip', 'file');
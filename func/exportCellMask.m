function exportCellMask(inputFile, outputFile, cellThreshold, frames)
%EXPORTCELLMASK  Generates and exports a file containing cell masks
%
%  EXPORTCELLCMASK(INPUTFILE, OUTPUTFILE) will process all frames in the
%  movie to identify cells. The binary mask will then be saved as a TIF
%  file. 
%
%  EXPORTCELLCMASK(..., FRAMES) will process only the frames specified.

outputPath = fileparts(outputFile);

if ~exist(outputPath, 'dir')
    mkdir(outputPath);
end

nd2 = ND2reader(inputFile);

if ~exist('frames', 'var')
    frames = 1:nd2.sizeT;
end

for iT = frames

    %Compute the maximum intensity projection of the image
    mip = calculateMIP(nd2, 1, iT);

    %Sum the channels
    sumImage = sum(mip, 3);

    %Make a mask of the cells
    cellMask = identifyCells(sumImage, cellThreshold);

    %Write the mask to file
    if iT == frames(1)
        imwrite(cellMask, outputFile, 'Compression', 'none')
    else
        imwrite(cellMask, outputFile, 'Compression', 'none', 'writeMode', 'append')
    end
    
end



end
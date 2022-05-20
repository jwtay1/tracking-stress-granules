function mip = calculateMIP(reader, iT)
%CALCULATEMIP  Calculate the maximum intensity projection of a z-stack
%
%  MIP = CALCULATEMIP(reader, iT) calculates the maximum intensity
%  projection of a z-stack image. reader should be the variable containing
%  the image reader (i.e., ND2reader or BioformatsImage). The output mip
%  contains the maximum intensity projection, with each channel
%  concatenated in the third dimesion (i.e., channel 2 will be in mip(:, :,
%  2)).

if isa(reader, 'ND2reader')
    mip = zeros(reader.height, reader.width, reader.sizeC, 'uint16');
    for iZ = 1:reader.sizeZ
        mip = max(mip, getImage(reader, 1, iT, 1));
    end

elseif isa(reader, 'BioformatsImage')

    mip = zeros(reader.height, reader.width, reader.sizeC, 'uint16');

    for iZ = 1:reader.sizeZ

        currImage = zeros(reader.height, reader.width, reader.sizeC, 'uint16');

        for iC = 1:reader.sizeC
            currImage(:, :, iC) = getPlane(reader, iZ, iC, iT);
        end

        mip = max(mip, currImage);
    end
end

end
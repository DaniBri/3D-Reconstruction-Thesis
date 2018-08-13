function result = rgb2binarize(image, contrast_logical, img_rotation, ...
                                laser_corr_angle)
%   LINEPIC2ANGLE does some preprocessing on the image.
%   The picture passed as parameter is rotated by user as well as
%   laser_corr_angle. Then the image is converted to a binarized matrix.
%
%   Author: Daniel Briguet, 18-06-2018

    % Rotate image n times clockwise
    for rotations = 1:img_rotation       
        image = imrotate(image,-90,'bilinear');         % Rotating image by 90° clockwise
    end
    
    % Laser rotation angle correction if laser wasn't horizontal
    image = imrotate(image,laser_corr_angle,'bilinear');
    
    gray_im = rgb2gray(image);                          % Convert from RGB to grayscale
    result = imbinarize(gray_im, contrast_logical);     % Brightness ponderation
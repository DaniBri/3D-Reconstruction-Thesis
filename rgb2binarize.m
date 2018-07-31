function result = rgb2binarize(image, contrast_logical)
%   LINEPIC2ANGLE 
%
%   Author: Daniel Briguet, 18-06-2018

    gray_im = rgb2gray(image);                                              % Convert from RGB to grayscale
    result = imbinarize(gray_im, contrast_logical);                         % Brightness ponderation
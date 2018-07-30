function result = rgb2binarize(image, reverse_color, contrast_logical)
%   LINEPIC2ANGLE 
%
%   Author: Daniel Briguet, 18-06-2018

    gray_im = rgb2gray(image);                                              % Convert from RGB to grayscale
    if(reverse_color == 1)
        gray_im = uint8(255) - gray_im;                                     % Reverse black and white in a grayscale 
    end
    result = imbinarize(gray_im, contrast_logical);                         % Brightness ponderation
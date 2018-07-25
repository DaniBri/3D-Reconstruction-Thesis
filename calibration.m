function result = calibration(real_size,pic_location)
%   CALIBRATION returns average relation between size of squares on a
%   checkerboeard image stored at given location and the number real_size.
%   Variable real_size is the dimension in mm from the squares.
%   The value returnes is the realtion in [mm/px].
%   Only the width between crossesection of checkerboard is considerd.
%   
%   Example:
%
%     CALIBRATION(10,'...\myFolder\calibration_image.jpg')
%
%
%   Author: Daniel Briguet, 07-06-2018
 
%% Detect pattern in the image.
% The following function returns all cross section on checkerboeard (corner
% of squares), as well as the size of points found. Ex: 3x4
[imagePoints,boardSize] = detectCheckerboardPoints(pic_location);

%% Getting Average diff between values in Array
% Only the square width is considerd.
coloumn = imagePoints(:,2); 

% Calculate difference between successive values in vector
% Array gets shortet by 1 beceaus it is not possible to compare last value
% with nothing
diff_array = diff(coloumn);

% Convert array to matrix
diff_array = diff_array.';                                      % Convert column to row
diff_array = [diff_array, NaN];                                 % Size array back to orriginal length
diff_matrix = reshape(diff_array,boardSize(1)-1,boardSize(2)-1);% Convert array back to matrix

% Removing last row of matrix holding all the jump values
diff_matrix(boardSize(1)-1:boardSize(2)-2:end,:) = [];

% Average dimension found on image, in pixel
width_mean = mean(mean(diff_matrix));             

result = real_size / width_mean ; % [mm/px]
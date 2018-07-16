function result = calibration(real_size,pic_location)
% CALIBRATION returns average relation between size of cubes on
% checkerboeardIMG stored at given location and the number real_size
% this number should corespond to the size of cubes in the real world
% retunrs a Value that is [mm/px]
%   CALIBRATION(real_size,pic_location) 

%   Example:
%
%     CALIBRATION(10)
%
%
%   Author: Daniel Briguet, 07-06-2018
 
%% Detect calibration pattern in the images.
[imagePoints] = detectCheckerboardPoints(pic_location);
 
%% Display the detected points.
%I = imread(imageFileName);
%imshow(I); hold on; plot(imagePoints(:,1), imagePoints(:,2), 'ro');

%% Getting Average diff between values in Array
% Splitting both colums
col_1 =imagePoints(:,1);
col_2 =imagePoints(:,2);
% Calculate difference between successive vector values
diff_1 = diff(col_1);
diff_2 = diff(col_2);

% Taking every nth element from each column in a matrix
jumps_1 = diff_1(11:11:end,:);

% Removin every nth element
jumps_2 = diff_2;
jumps_2(11:11:end,:) = [];
mean_1 = mean(jumps_1);     % average vertikal dist
mean_2 = mean(jumps_2);     % average horizontal dist
average_dist = (mean_1+mean_2)/2;
result = real_size / average_dist ; % [mm/px]
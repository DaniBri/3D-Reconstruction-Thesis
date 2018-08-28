function angle = linepic2angle(nmr_img_check, picFolder, picFiles, ...
                 laser_correction_object_no, contrast_logical, ...
                 line_object_size, img_rotation, recursive_laser_correction_angle)
%   LINEPIC2ANGLE returns the average line angle on a series of pictures.
%   Using start and end of line to determin angle.
%
%   nmr_img_check: how many images will be checked
%   cor_object_size: minimal size of such an object
%   laser_correction_object_no: how much "line" is loock for at start and
%   end of line.
%   recursive_laser_correction_angle gives some angle correction. This
%   variable should be initialized at 0.
%
%   Author: Daniel Briguet, 18-06-2018

correction_img_array = NaN(1,nmr_img_check);                      	% Initialize array
for image_nbr = 1:nmr_img_check
    firstpic_name = fullfile(picFolder, picFiles(image_nbr).name);  % Getting current file in directory
    current_img = imread(firstpic_name);                           	% Load image
    
    % Process image from rgb to binarize 
	diff_im = rgb2binarize(current_img, contrast_logical, img_rotation, recursive_laser_correction_angle);
    
    diff_im = bwareaopen(diff_im,line_object_size);               	% Min. size of object
    logical_map = logical(diff_im);                                 % Convert to logical
    objects = regionprops(logical_map, 'Centroid');

    % Check the amount of object that is asked to be used via parameter
	% If it's to much calculate a value that can be used
    if(laser_correction_object_no >= length(objects)/2)
        laser_correction_object_no = round(length(objects)/3);
    end
    
    % Creating array of doubles from all centroid
    allCentroids = [objects.Centroid];                             	% Split cell up and create array
    yCentroids = allCentroids(2:2:end);                            	% Store every second value starting at 2
    xCentroids = allCentroids(1:2:end);                            	% Store every second value starting at 1
    centroids = [xCentroids;yCentroids];                          	% Create matrix
    centroids = rot90(centroids,1);                                	% Rotate matrix 90°
    centroids_sorted = sortrows(centroids,1);                      	% Sort matrix according to column 1 holding x values of centroid
    
    correction_array = zeros(1,laser_correction_object_no);        	% Initializing array where different angles will be stored
    for i = 1:laser_correction_object_no
        laser_diff_height = centroids_sorted(i,2) - centroids_sorted(length(objects)-i+1,2);    % Get height difference of two opposite detected points
        laser_diff_length = centroids_sorted(i,1) - centroids_sorted(length(objects)-i+1,1);    % Get length difference of two opposite detected points
        laser_correction_angle = atan(laser_diff_height/laser_diff_length);                     % Calculate angle between those points
        laser_correction_angle = laser_correction_angle * 180 / pi;                             % Convert to degree
        correction_array(i) = laser_correction_angle;                                           % Store data
    end
    correction_img_array(image_nbr) = mean(correction_array);                               	% Use the mean of all the different angles calculated
end

% If angle is lower then 0.01 breack out of loop
if(abs(mean(correction_img_array)) >= 0.01)
    angle = mean(correction_img_array)+...
            linepic2angle(nmr_img_check, picFolder, picFiles, ...
            laser_correction_object_no, contrast_logical, ...
            line_object_size, img_rotation, ...
            mean(correction_img_array) + recursive_laser_correction_angle);
else
    angle = mean(correction_img_array);
end

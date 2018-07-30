function angle = linepic2angle(nmr_img_check, picFolder, picFiles, ...
                 laser_correction_object_no, contrast_logical, ...
                 cor_object_size, img_rotation)
%   LINEPIC2ANGLE 
%
%   Author: Daniel Briguet, 18-06-2018

correction_img_array = zeros(1,nmr_img_check);                      % Initialize array
for image_nbr = 1:nmr_img_check
    firstpic_name = fullfile(picFolder, picFiles(image_nbr).name);  % Getting current file in directory
    first_img = imread(firstpic_name);                              % Load image
    
    % Rotate image n times clockwise
    for rotations = 1:img_rotation       
        first_img = imrotate(first_img,-90,'bilinear');             % Rotating image by 90° clockwise
    end
        
    gray_im = rgb2gray(first_img);                                  % Convert from RGB to grayscale
    diff_im = imbinarize(gray_im,contrast_logical);                 % Gray ponderation
    diff_im = bwareaopen(diff_im,cor_object_size);                  % Min. size of object
    logical_map = logical(diff_im);                                 % Convert to logical
    objects = regionprops(logical_map, 'Centroid');

    % Check that amount of object user wants to use to make comparesion is
    % avaible
    if(laser_correction_object_no >= length(objects)/2)
        laser_correction_object_no = round(length(objects)/2);
    end
    
    % Creating array of doubles from all centroid
    allCentroids = [objects.Centroid];                                      % Splitt cell up and creat array
    yCentroids = allCentroids(2:2:end);                                     % Store every second value starting at 2
    xCentroids = allCentroids(1:2:end);                                     % Store every second value starting at 1
    centroids = [xCentroids;yCentroids];                                    % Creat matrix
    centroids = rot90(centroids,1);                                         % Rotate matrix 90°
    centroids_sorted = sortrows(centroids,1);                               % Sort matrix according to column 1 holding x values of centroid
    
    % Nota Bene: stats are sortet by bounding box on X axe
    correction_array = zeros(1,laser_correction_object_no);                 % Initializing array where different angles will be stored
    for i = 1:laser_correction_object_no
        laser_diff_height = centroids_sorted(i,2) - centroids_sorted(length(objects)-i+1,2);    % Get height difference of two opposit dedected points
        laser_diff_length = centroids_sorted(i,1) - centroids_sorted(length(objects)-i+1,1);    % Get length difference of two opposit dedected points
        laser_correction_angle = atan(laser_diff_height/laser_diff_length);                     % Calculate angle between those points
        laser_correction_angle = laser_correction_angle * 180 / pi;                             % Convert to degree
        correction_array(i) = laser_correction_angle;                                           % Store data
    end
    correction_img_array(image_nbr) = mean(correction_array);                               	% Use the mean of all the different angles calculated
end
angle = mean(correction_img_array);
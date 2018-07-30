function z_matrix = factory(picFormat, folder_name, ...
        img_rotation, smooth_run, smooth_factor, ... 
        contrast_logical, ground_height_factor, ...
        filling_method, limiter_ponderation, limiter_area, ...
        limiter_status, laser_correction_object_no, ...
        nmr_img_check, activate_errors, error_percentage, ...
        min_object_size, corr_object_size)

%   FACTORY returns a 2D matrix.
%   This matrix contains the height from the points from which the lane on
%   each image consists of.
%
%   - picFormat: what format pictures are stored in. 'png' 'jpg'...
%   - folder_name: folder name containing image sequence. Image named chronologicaly
%   - img_rotation: how many times image are rotated
%   - activate_smooth: is surfaced smoothed out
%   - smooth_factor: how strong is it smoothed
%   - contrast_logical: used by imbinarize function
%   - inverse_height: needs to be avtivated if line hitting the item is higher on image
%   - ground_height_factor: in how many slices histogram is cut
%   - filling_method: what method is used to restor missing data in matrix
%     Fill method must be 'constant', 'previous', 'next', 'nearest', 'linear', 'spline', or 'pchip'
%   - limiter_ponderation: used by limiter function
%   - limiter_area: used by limiter function
%   - limiter_status: used by limiter function
%
%   Example:
%     factory('jpg', 0.5, 1, 'linear', 0.001, 'mySequenze', 0, 30, 0, 0.5, 4, 1)
%
%   Author: Daniel Briguet, 18-06-2018

%% Loading image from directory
picFolder = strcat(pwd, folder_name); % Folder that contains all the images

% Check if folder does exist 
if ~isdir(picFolder)
    error('Error, The following directory does not exist: \n%s', picFolder);
end

% Load the images in folder
filePattern = fullfile(picFolder, strcat('*.', picFormat));
picFiles = dir(filePattern);
no_of_img = length(picFiles);

% Check if folder is empty
if(no_of_img == 0)
    error('Error, no images found in folder');
end

%% Removing unusable images
% This part removes all images at start of sequenz that are balck or do not
% have enough laser line in them to be relevant.
for current_img_no = 1:no_of_img                                            % Go through all the images in directory
    fullFileName = fullfile(picFolder, picFiles(current_img_no).name);      % Getting current image in directory
    current_img = imread(fullFileName);                                     % Load current image
    gray_im = rgb2gray(current_img);                                        % Convert from RGB to grayscale
    diff_im = imbinarize(gray_im,contrast_logical);                         % Brightness ponderation
    diff_im = bwareaopen(diff_im,corr_object_size);                          % Min. size of object
    logical_map = logical(diff_im);                                         % Convert to logical
    objects = regionprops(logical_map, 'Centroid');                         % Store information
    
    % Check if there are more then n objects found on image
    if(length(objects) < 20)                                              
        delete(fullFileName);
    else
        % Start of model found, no more images deleted
    	break;
    end
end

%% Check laser angle
% First few images are used to define laser rotation (angle) correction
laser_corr_angle = linepic2angle(nmr_img_check, picFolder, picFiles, ...
                 laser_correction_object_no, contrast_logical, ...
                 corr_object_size, img_rotation);                                   % Get laser angle from images

%% Processing images
for current_img_no = 1:no_of_img                                            % Go through all the images in directory
	fullFileName = fullfile(picFolder, picFiles(current_img_no).name);      % Getting current image in directory
    current_img = imread(fullFileName);                                     % Load current image
    
    % Rotate image n times clockwise
    for rotations = 1:img_rotation
        current_img = imrotate(current_img,-90,'bilinear'); 
    end
    
    % Laser rotation angle correction if laser wasn't horizontal
    current_img = imrotate(current_img,laser_corr_angle,'bilinear');
    
	img_y_length = size(current_img,1);                                     % Get height of image
    no_of_strips = size(current_img,2);                                     % Get width of image
	
	% Initialize z_matrix, only done once, this is done in for loop to know the dimensions of images
    if(current_img_no == 1)             
        z_matrix = NaN(no_of_strips,no_of_img); 
    end
	
    gray_im = rgb2gray(current_img);                                        % Convert from RGB to grayscale
    diff_im = imbinarize(gray_im,contrast_logical);                         % Brightness ponderation
    
    % Find laser center position in every strip
    for current_strip = 1:no_of_strips                                      % Go through all slices of an image
        map_strip = diff_im(1:img_y_length,current_strip:current_strip);    % Load strip of current image
        z_matrix(current_strip,current_img_no) = finder(map_strip, min_object_size);         % Find position in strip
    end
end

%% Adding random points inmatrix 
% random points at random position in matrix to test filter
% what percentage of total values are randomized at random position
% it is possible that same cell is randomized multiple times
if(activate_errors ~= 0)
    max_limit = round(max(max(z_matrix)));
    for row = 1:(size(z_matrix,1)*size(z_matrix,2))*error_percentage/100
        % change between + and - to change inclenison
        z_matrix(randi(size(z_matrix,1)),randi(size(z_matrix,2))) = randi(max_limit);
    end
end

%% Remove isolatet points
if(limiter_status~=0)
    % Remove spice values that don't make sense
    z_matrix = limiter(z_matrix, limiter_ponderation, limiter_area);
    % Applie median filter for good measure
    z_matrix = medfilt2(z_matrix);
end

%% Recover missing values in matrix 
% Reconstruct if there are some values missing in matrix
% Do reconstruction in perpendicular to scan direction
z_matrix = rot90(z_matrix,1);                       % Rotate matrix 90°
z_matrix = fillmissing(z_matrix,filling_method);    % Replaces all NaNs
z_matrix = rot90(z_matrix,-1);                      % Rotate back
z_matrix = fillmissing(z_matrix,filling_method);

%% Inverse matrix if ground item is upside down in matrix
% If ground has higher value then item hight matrix needs to be inverted.
% else when pulling to ground everything gona be flatend
% Finde ground
[array,edges] = histcounts(z_matrix(:),ground_height_factor);   % Get values and limit of histogramm
[~,I] = max(array);                                             % Find index of most used range
ground = edges(I);                                              % Get upper limit of that valuerange

% Finde average hight of matrix
height_matrix = mean(mean(z_matrix));

% Inverse height if matrix average height is below ground
if(ground > height_matrix)
   z_matrix = max(max(z_matrix))- z_matrix;
end

%% Smoothing
% Smooth transition from one value to another
if(smooth_run ~= 0)
    % Store matrix dimension because smoothing transforms it to array
    temp1 = size(z_matrix,1);
    temp2 = size(z_matrix,2);
    
    % Smooth methodes: moving, lowess, loess, sgolay, rlowess, rloess
    z_matrix = smooth(z_matrix,smooth_factor,'moving'); % Smoothing of matrix
    z_matrix = reshape(z_matrix,temp1,temp2);           % Convert array back to matrix
end

% If smoothing created negative values replace them by 0
z_matrix(z_matrix < 0) = 0;

%% Artificaly creating ground angle
if(activate_errors ~= 0)
    for column = 1:size(z_matrix,2)
        for row = 1:size(z_matrix,1)
            % change between + and - to change inclenison
            z_matrix(row,column) = z_matrix(row,column) - 1.5*column;
        end
    end
end

%% Removing diagonal on ground X
% Removing digonal on X axe of ground.
z_matrix = ground_balancer(z_matrix);

%% Put object to ground
[array,edges] = histcounts(z_matrix(:),ground_height_factor);   % Get values and limit of histogramm
[~,I] = max(array);                                             % Find index of most used range
ground_limit = edges(I+1);                                      % Get upper limit of that valuerange
z_matrix = z_matrix - ground_limit;                             % Remove it from all values in matrix to make it the new ground
z_matrix(z_matrix < 0) = 0;                                     % Remove all negative values

%% Cutting exessiv border from z_matrix
% Cut of border so there are only that many rows & colums with NAN
[array,edges] = histcounts(z_matrix(:),ground_height_factor);
[~,I] = max(array);
ground_limit = edges(I+1);
z_matrix = cutter(z_matrix, ground_limit);                      % Pass down the new ground limit to the cutter

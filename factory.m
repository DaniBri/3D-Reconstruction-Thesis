function z_matrix = factory(picFormat, folder_name, ...
        img_rotation, smooth_run, smooth_factor, ... 
        contrast_logical, inverse_height, ground_height_factor, ...
        filling_method, limiter_ponderation, limiter_area, ...
        limiter_status, laser_correction_object_no, ...
        activate_errors, error_percentage)

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
    diff_im = bwareaopen(diff_im,5);                                        % Min. size of object
    logical_map = logical(diff_im);                                         % Convert to logical
    stats = regionprops(logical_map, 'BoundingBox', 'Centroid');            % Store information
    
    % Check if there are more then n objects found on image
    if(length(stats) < 20)                                              
        delete(fullFileName);
    else
        % Start of model found, no more images deleted
    	break;
    end
end

%% Check laser angle
% First 3 images are used to define laser rotation (angle) correction
nmr_img_check = 3;
correction_img_array = zeros(1,nmr_img_check);                      % Initialize array
for image_nbr = 1:nmr_img_check
    firstpic_name = fullfile(picFolder, picFiles(image_nbr).name);  % Getting current file in directory
    first_img = imread(firstpic_name);                              % Load image
    
    % Rotate image n times clockwise
    for rotations = 1:img_rotation       
        first_img = imrotate(first_img,-90,'bilinear');             % Rotating image by 90�
    end
    
    gray_im = rgb2gray(first_img);                                  % Convert from RGB to grayscale
    diff_im = imbinarize(gray_im,contrast_logical);                 % Gray ponderation
    diff_im = bwareaopen(diff_im,5);                                % Min. size of object
    logical_map = logical(diff_im);                                 % Convert to logical
    stats = regionprops(logical_map, 'BoundingBox', 'Centroid');

    % Nota Bene: stats are sortet by bounding box on X axe
    correction_array = zeros(1,laser_correction_object_no);                 % Initializing array where different angles will be stored
    for i = 1:laser_correction_object_no
        laser_diff_height = stats(i).Centroid(2) - stats(length(stats)-i+1).Centroid(2);    % Get height difference of two opposit dedected points
        laser_diff_length = stats(i).Centroid(1) - stats(length(stats)-i+1).Centroid(1);    % Get length difference of two opposit dedected points
        laser_correction_angle = atan(laser_diff_height/laser_diff_length);                 % Calculate angle between those points
        laser_correction_angle = laser_correction_angle * 180 / pi;                         % Convert to degree
        correction_array(i) = laser_correction_angle;                                       % Store data
    end
    correction_img_array(image_nbr) = mean(correction_array);                               % Use the mean of all the different angles calculated
end
laser_correction_angle = mean(correction_img_array);


%% Processing images
for current_img_no = 1:no_of_img                                            % Go through all the images in directory
	fullFileName = fullfile(picFolder, picFiles(current_img_no).name);      % Getting current image in directory
    current_img = imread(fullFileName);                                     % Load current image
    
    % Rotate image n times clockwise
    for rotations = 1:img_rotation
        current_img = imrotate(current_img,-90,'bilinear'); 
    end
    
    % Laser rotation angle correction if laser wasn't horizontal
    current_img = imrotate(current_img,laser_correction_angle,'bilinear');  
    
	img_y_length = size(current_img,1);                                     % Get height of image
    no_of_strips = size(current_img,2);										% Get width of image
	
	% Initialize z_matrix, only done once, this is done in for loop to know the dimensions of images
    if(current_img_no == 1)             
        z_matrix = NaN(no_of_strips,no_of_img); 
    end
	
    gray_im = rgb2gray(current_img);                                        % Convert from RGB to grayscale
    diff_im = imbinarize(gray_im,contrast_logical);                         % Brightness ponderation
    
    % Find laser center position in every strip
    for current_strip = 1:no_of_strips                                      % Go through all slices of an image
        map_strip = diff_im(1:img_y_length,current_strip:current_strip);    % Load strip of current image
        z_matrix(current_strip,current_img_no) = finder(map_strip);         % Find position in strip
    end
end

% Inverse height if laser hitting the item is higher on image
if(inverse_height ~= 0)
   z_matrix = max(max(z_matrix))- z_matrix;
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
z_matrix = rot90(z_matrix,1);                       % Rotate matrix 90�
z_matrix = fillmissing(z_matrix,filling_method);    % Replaces all NaNs
z_matrix = rot90(z_matrix,-1);                      % Rotate back
z_matrix = fillmissing(z_matrix,filling_method);

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

%% artificaly creating ground angle TODO REMOVE THIS CHAPTER
if(activate_errors ~= 0)
    for column = 1:size(z_matrix,2)
        for row = 1:size(z_matrix,1)
            % change between + and - to change inclenison
            z_matrix(row,column) = z_matrix(row,column) - 1.5*column;
        end
    end
end


%% Removing diagonal on ground
% Removing digonal on X axe of item. There should not be any diagonal on Y
% axe cause this would macke the laser line diagonal and laser angle
% correction already solves that problem.
% Making average ground height difference at start and end of scan.
% Correct the height in a linear way, fixing diagonal of scan on length
% Matrix margin to check = bodrer width that is checked
margin = 4;
correction_array = zeros(1,size(z_matrix,1));       % Initializing array where slop is stored
diff_array = zeros(1,margin);                       % Initializing array where height difference is stored
if(margin*2+1 < size(z_matrix,2))                   % Minimal length of item matrix necessary
    for row = 1:size(z_matrix,1)                    % Go through all the rows of matrix
        % Get slop between border at start and end of row
        for i = 0:margin
            diff_max = z_matrix(row,1+i) - z_matrix(row,size(z_matrix,2) - i);  % Calculate height difference
            diff_length = (size(z_matrix,2) - 2 * i);                           % Calculate length difference
            diff_array(i+1) = diff_max / diff_length;                           % Store slop
        end
        correction_array(row) = mean(diff_array);                               % Store mean slop of column
    end
    slop = mean(correction_array);                                              % Average ground slop 

    % Update every single value in row acording to slop
    for column = 1:size(z_matrix,2)                                             % position in column
        correction = slop*column;                                               % Correction needed on that row of matrix
        for row = 1:size(z_matrix,1)                                            % Do entire row
            % Apply correction, doesn't matter if positiv or negativ
            % it will mabe heighten ground up but it's gona be flat
            % later ground is put to 0 anyway
            z_matrix(row,column) = z_matrix(row,column) + correction;
        end
    end
end
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

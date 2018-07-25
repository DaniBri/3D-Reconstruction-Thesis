function z_matrix = factory(picFormat,  folder_name, ...
        img_rotation, activate_smooth, smooth_factor, ... 
        contrast_logical, inverse_height, ground_height_factor, ...
        filling_method, limiter_ponderation, limiter_area, ...
        limiter_status, laser_correction_object_no)
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
        first_img = imrotate(first_img,-90,'bilinear');             % Rotating image by 90°
    end
    
    gray_im = rgb2gray(first_img);                                  % Convert from RGB to grayscale
    diff_im = imbinarize(gray_im,contrast_logical);                 % Gray ponderation
    diff_im = bwareaopen(diff_im,5);                                % Min. size of object
    logical_map = logical(diff_im);                                 % Convert to logical
    stats = regionprops(logical_map, 'BoundingBox', 'Centroid');

    % Nota Bene: stats are sortet by bounding box on X axe
    correction_array = zeros(1,laser_correction_object_no);                 % initializing array where different angles will be stored
    for i = 1:laser_correction_object_no
        laser_diff_height = stats(i).Centroid(2) - stats(length(stats)-i+1).Centroid(2); % get height difference of two opposit dedected points
        laser_diff_length = stats(i).Centroid(1) - stats(length(stats)-i+1).Centroid(1);% get length difference of two opposit dedected points
        laser_correction_angle = atan(laser_diff_height/laser_diff_length);    % calc angle
        laser_correction_angle = laser_correction_angle * 180 / pi;                     % convert to degree
        correction_array(i) = laser_correction_angle;                                   % store it
    end
    correction_img_array(image_nbr) = mean(correction_array);                            % use the mean of all the different angles calculated
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

%% Remove isolatet points
if(limiter_status~=0)
    z_matrix = limiter(z_matrix, limiter_ponderation, limiter_area);
end

%% Recover missing values in matrix 
% Reconstruct if there are some values missing in matrix
% Do reconstruction in perpendicular to scan direction
z_matrix = rot90(z_matrix,1);                       % Rotate matrix 90°
z_matrix = fillmissing(z_matrix,filling_method);    % Replaces all NaNs
z_matrix = rot90(z_matrix,-1);                      % Rotate back
z_matrix = fillmissing(z_matrix,filling_method);

%% Smoothing
% Smooth transition from one value to another
if(activate_smooth ~= 0)
    % Store matrix dimension because smoothing transforms it to array
    temp1 = size(z_matrix,1);
    temp2 = size(z_matrix,2);
    
    % Smooth methodes: moving, lowess, loess, sgolay, rlowess, rloess
    z_matrix = smooth(z_matrix,smooth_factor,'moving'); % Smoothing of matrix
    z_matrix = reshape(z_matrix,temp1,temp2);           % Convert array back to matrix
end

% If smoothing created negative values replace them by 0
z_matrix(z_matrix < 0) = 0;

%% Removin diagonal on ground
% Making average ground height difference at start and end of scan. 
% Correct the height in a linear way, fixing diagonal of scan on length
% Matrix margin to check = bodrer width that is checked
margin = 4;
correction_array = zeros(1,size(z_matrix,2));       % Initializing array where slop is stored
diff_array = zeros(1,margin);                       % Initializing array where height difference is stored
for column = 1:size(z_matrix,2)                     % Go through all the columns of matrix
    % Get height difference between border at start and end of matrix
    for i = 0:margin
        diff_max = z_matrix(1+1,column) - z_matrix(size(z_matrix,1)-i,column);	% Calculate height difference
        diff_length = (1+i) - size(z_matrix,2)-i;                            	% Calculate length difference
        diff_array(i+1) = diff_max / diff_length;                               % Store slop
    end
    correction_array(column) = mean(diff_array);                                % Store mean slop of rows
end
slop = mean(correction_array);                                                  % Mean slop of ground

% Update every single value in row acording to slop
for row = 1:size(z_matrix,1)                                                    % Column position
    correction = slop*row;                                                      % Correction needed on that row of matrix
    for column = 1:size(z_matrix,2)                                             % Row position
        z_matrix(row,column) = z_matrix(row,column) - correction;
    end
end

%% Put object to ground
[N,edges] = histcounts(z_matrix(:),ground_height_factor);
[~,I] = max(N);
ground_limit = edges(I+1);
z_matrix = z_matrix - ground_limit;
z_matrix(z_matrix < 0) = 0;

%% Cutting exessiv border from z_matrix
% Cut of border so there are only that many rows & colums with NAN
[N,edges] = histcounts(z_matrix(:),ground_height_factor);
[~,I] = max(N);
ground_limit = edges(I+1);
z_matrix = cutter(z_matrix, ground_limit);

function z_matrix = factory(picFormat,  folder_name, ...
        img_rotation, activate_smooth, smooth_factor, ... 
        contrast_logical, inverse_height, ground_height_factor, ...
        filling_method, limiter_ponderation, limiter_area, limiter_status)
%   FACTORY returns a 2D matrix 
%   This matrix contains the height from the points from which the lane on
%   each image consists of.
%	The folder name containing image sequence is passed down as parameter
% 	same goes for a lot of other factors.
%	Images in folder need to be stored in chronological order.
%   Parameter filling_method is used for the reconstruction of missing values.
%
%   Example:
%     factory('jpg', 0.5, 1, 'linear', 0.001, 'mySequenze', 0, 30, 0, 0.5, 4, 1)
%
%   Author: Daniel Briguet, 18-06-2018

%% Setting Configurations
picFolder = strcat(pwd, folder_name);      % Folder that holds all the IMGs from CMOS
laser_correction_object_no = 20;                                                                % Number of object jused to find out angle correction

%% Loading IMG from Directory
% Check if folder does exist 
if ~isdir(picFolder)
    error('Error, The following directory does not exist: \n%s', picFolder);
end

% Load the files in folder
filePattern = fullfile(picFolder, strcat('*.', picFormat));
picFiles = dir(filePattern);
no_of_img = length(picFiles);                                               % Get number of IMGs taken by CMOS

if(no_of_img == 0)
    error('Error, no images found in folder');
end

%% Removing unusable Images
for current_img_no = 1:no_of_img                                            % Go through all the IMGs in directory
    fullFileName = fullfile(picFolder, picFiles(current_img_no).name);      % Getting current file in directory
    current_img = imread(fullFileName);                                     % Load current IMG
    gray_im = rgb2gray(current_img);    
    diff_im = imbinarize(gray_im,contrast_logical);                                   % Gray ponderation
    diff_im = bwareaopen(diff_im,5);                                        % Min. size of object
    logical_map = logical(diff_im);                                         % Convert to logical
    stats = regionprops(logical_map, 'BoundingBox', 'Centroid');
        if(length(stats) < laser_correction_object_no)                      % Check if there are more then n objects found on image
            delete(fullFileName)
        else
            break;                                                          % Start of model found no more img should be deleted
        end
end

%% Check laser angle
% use first 3 image to define angle correction
correction_img_array = zeros(1,3);
for image_nbr = 1:3
    firstpic_name = fullfile(picFolder, picFiles(image_nbr).name);                  % Getting current file in directory
    first_img = imread(firstpic_name);                                      % Load  IMG
    for rotations = 1:img_rotation                                          % Rotate img n times (clockwise)
        first_img = imrotate(first_img,-90,'bilinear'); 
    end
    gray_im = rgb2gray(first_img);                                          % Convert from rgb image to graysacale
    diff_im = imbinarize(gray_im,contrast_logical);                                   % Gray ponderation
    diff_im = bwareaopen(diff_im,5);                                        % Min. size of object
    logical_map = logical(diff_im);                                         % Convert to logical
    stats = regionprops(logical_map, 'BoundingBox', 'Centroid');

    % Nota Bene: stats are sortet by bounding box on X axe
    correction_array = zeros(1,laser_correction_object_no);                 % initializing array where different angles will be stored
    for i = 1:laser_correction_object_no
        laser_diff_hight = stats(i).Centroid(2) - stats(length(stats)-i+1).Centroid(2); % get hight difference of two opposit dedected points
        laser_diff_length = stats(i).Centroid(1) - stats(length(stats)-i+1).Centroid(1);% get length difference of two opposit dedected points
        laser_correction_angle = atan(laser_diff_hight/laser_diff_length);    % calc angle
        laser_correction_angle = laser_correction_angle * 180 / pi;                     % convert to degree
        correction_array(i) = laser_correction_angle;                                   % store it
    end
    correction_img_array(image_nbr) = mean(correction_array);                            % use the mean of all the different angles calculated
end
laser_correction_angle = mean(correction_img_array);


%% Processing Images    
for current_img_no = 1:no_of_img                                            % Go through all the IMGs in directory
    %loading in current img and correcting rotation
	fullFileName = fullfile(picFolder, picFiles(current_img_no).name);      % Getting current file in directory
    current_img = imread(fullFileName);                                     % Load current IMG
    for rotations = 1:img_rotation                                          % Rotate image if user asked for
        current_img = imrotate(current_img,-90,'bilinear'); 
    end
    current_img = imrotate(current_img,laser_correction_angle,'bilinear');  % use laser angle correction if laser wasn't horizontal
    
	img_y_length = size(current_img,1);                                     % Get hight of IMG
    no_of_strips = size(current_img,2);										% Get width of IMG
	
	% Initialize z_matrix, only done once, this is done in for loop to know the dimensions of images
    if(current_img_no == 1)             
        z_matrix = NaN(no_of_strips,no_of_img); 
    end
	
    gray_im = rgb2gray(current_img);                                        % Convert from rgb to grayscale
    diff_im = imbinarize(gray_im,contrast_logical);                                   % Brightnes ponderation
    for current_strip = 1:no_of_strips                                  % Go through all slices of an IMG
        map_strip = diff_im(1:img_y_length,current_strip:current_strip);% Load strip of current IMG
        z_matrix(current_strip,current_img_no) = finder(map_strip);
    end
end
if(inverse_height ~= 0)
   z_matrix = max(max(z_matrix))- z_matrix;
end

%% Remove isolatet points
if(limiter_status~=0)
    z_matrix = limiter(z_matrix, limiter_ponderation, limiter_area);
end

%% Reconstruct Errors for every IMG 
% Reconstruct if there are some Values missing in table

z_matrix = rot90(z_matrix,1);
z_matrix = fillmissing(z_matrix,filling_method); % replaces NaN values
z_matrix = rot90(z_matrix,3);
z_matrix = fillmissing(z_matrix,filling_method); %Fill method must be 'constant', 'previous', 'next', 'nearest', 'linear', 'spline', or 'pchip'.

%% Smoothing
if(activate_smooth ~= 0)
    temp1 = size(z_matrix,1);
    temp2 = size(z_matrix,2);
    z_matrix = smooth(z_matrix(:,:),smooth_factor,'moving');                 % Smoothing out values takes up to 3 min
    % moving, lowess, loess, sgolay, rlowess, rloess
    z_matrix = reshape(z_matrix,temp1,temp2);             % Smoothing transformed matrix to array... reconstruct it
end
z_matrix(z_matrix < 0) = 0;

%% Removin diagonal on ground
% Mak diff of ground hight at start and end of scan for every value then 
% correct the hight in a linear way / fixing diagonal of scan on length
% axcis of model

% going past every row
correction_array = zeros(1,4);                 % initializing array where different angles will be stored
for row = 1:size(z_matrix,1)
    
    
    for i = 0:4
        diff_max = z_matrix(row,1+i) - z_matrix(row,size(z_matrix,2)-i); %z_matrix(row,column)
        correction_array(i+1) = diff_max;                                   % store it
    end
    
    % use the mean of all the different angles calculated
    diff_max = mean(correction_array);
    diff_step = diff_max/size(z_matrix,2);
    
    % update every single value of row
    for column = 1:size(z_matrix,2)-1
        z_matrix(row,size(z_matrix,2)-column) = z_matrix(row,size(z_matrix,2)-column) - diff_step*column;
    end
    
    % bring object to ground again if diff was negativ value
    if(mean(z_matrix(:,1)) < mean(z_matrix(:,(size(z_matrix,2)))))
        z_matrix = z_matrix - diff_max;
    end
end

%% Put object to ground
h=histogram(z_matrix(:),ground_height_factor);
[~,I] = max(h.Values);
ground_limit = h.BinEdges(I+1);
z_matrix = z_matrix - ground_limit;
z_matrix(z_matrix < 0) = 0;

%% Cutting exessiv border from z_matrix
% Cut of border so there are only that many rows & colums with NAN
h=histogram(z_matrix(:),ground_height_factor);
[~,I] = max(h.Values);
ground_limit = h.BinEdges(I+1);
z_matrix = cutter(z_matrix, ground_limit);

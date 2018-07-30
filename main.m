imtool close all;
close all;
clc;
clear;
% Main.m is the base script to run for the reconstruction.
% In here it is possible to configure all the settings, allowing to modify
% the quality of the reconstruction and to adapt to different pictures.
% In the end the script returns an STL File according to all the Picture located
% in a given folder.
%
% Author: Daniel Briguet, 18-06-2018

%% Settings

% Sequenze
folder_name = '\sequenz2';              % Name of folder where images are stored
picFormat = 'jpg';						% Format of images in folder

% Calibration
use_checkerboeard = 0;                  % Turn on or off, if off camera param are used
calib_folder_name = '\calibration_pic'; % Name of folder where images are stored in
calib_picFormat = 'jpg';				% Format of calib image in folder
size_of_checkerboard_square = 0.029;    % Size of 1 square from checker board in mm
pixel_size = 2.2;                       % [um] If unknown = 0;
imager_size = 5.7;                      % [mm] ONLY used when pixel size unknown
active_pixels = 2592;					% Number of pixels from sensor ONLY used when pixel size unknown

% IMG Processing
contrast_logical = 0.9;                 % Contrast factor to define logical map
img_rotation = 2;						% Number of rotation of images by 90° clockwise
min_object_size = 3;                    % Minimal size of sequenz for finder to look for. Helps avoiding noise on image

%TODO rename this, clear up
inverse_Y_axis = 1;						% Mirror model left right also needed when height inversed
filling_method = 'nearest';             % Fill method must be 'constant', 'previous', 'next', 'nearest', 'linear', 'spline', or 'pchip'.
ground_height_factor = 25;              % How many slices histogram is made of.
                                        % Ground will be removed from where most points are

% Smooth
smooth_run = 1;                         % Turn on or off
smooth_factor = 0.0001;                 % Use with moderation. Falsifies dimensions and slows down reconstruction

% Limiter
limiter_status = 1;                     % Turn on or off
limiter_ponderation = 0.1;              % Faktor on diff ponderation between values
limiter_area = 5;                       % How many adjasant values are checked in (up/down/left/right)

% Motor
motor_alim = 2;                         % [V] Motor powere supply
motor_axis_dia = 6;                     % [mm] Diameter where cable is wrapped around
motor_poly = [0.0201 0.5978 0.2827];    % Funktion calculated vrom measurment on motor
                                        % p(x) = [ax^2+bx+c]

% Laser
angle_laser = 15;                       % Angle between laser and socket
laser_correction_object_no = 15;        % Number of object used to find out angle rotation
nmr_img_check = 10;                     % On how many images at start of scan angle is checked
corr_object_size = 10;                  % Minimal size of object on image for corretion

% Camera 
camera_fps = 7;                         % Camera images taken per second

% Output
stl_file_name = 'model.stl';			% Name of STL file created from script
scale = 1;                              % Resize factor of model
stl_compression = 0.2;                  % How much data from original data should be keept.
                                        % Reduces file size but also reduces
                                        % qualitiy of model

% Error Creation
activate_errors = 0;                    % Artificaly creat errors of different sort in matrix
error_percentage = 7;                   % percentage of values randomized in matrix

%% Calibration Set-up
if(use_checkerboeard ~= 0)
    calibFolder = strcat(pwd, calib_folder_name);       % Getting calibration file directory
    if ~isdir(calibFolder)
        error('Error, The following directory does not exist: \n%s', calibFolder);
    end
    calibration_filename = fullfile(calibFolder, strcat('*.', calib_picFormat));    % Getting calibration image in directory
    picFile = dir(calibration_filename);                                            % Storing information about all files in that folder
    fullFileName = fullfile(calibFolder, picFile(1).name);                          % Save path to first image and it's name
    relation_px_mm = calibration(size_of_checkerboard_square,fullFileName);         % Give image and size, retuns relation [mm/px]
else
    if(pixel_size ~= 0)
        relation_px_mm = pixel_size/1000;               % [um] -> [mm]
    else
        relation_px_mm = imager_size/active_pixels;     % Calculate pixel_size directly in mm
    end
end

%% Get Z_matrix
% Transmit settings and run image processing
tic
z_matrix = factory(picFormat, folder_name, ...
        img_rotation, smooth_run, smooth_factor, ... 
        contrast_logical, ground_height_factor, ...
        filling_method, limiter_ponderation, limiter_area, ...
        limiter_status, laser_correction_object_no, ...
        nmr_img_check, activate_errors, error_percentage, ...
        min_object_size, corr_object_size);
no_of_img = size(z_matrix,2);               % Dimension 1 from z_matrix gives amount of image taken
img_width = size(z_matrix,1);               % NB: img width not item width
disp('-Image Processing done');
toc

%% Z_MATRIX correction
% height = length/tan(angle)
angle_laser = angle_laser*pi/180;                       % Converting degree to rad
z_matrix = relation_px_mm*z_matrix/tan(angle_laser);    % Calculating height and converting from pixel to mm

%% X_MATRIX correction
% Speed calculation
rps = polyval(motor_poly,motor_alim)/ 60;               % Calculate motor rotation per second
circumference_axe = motor_axis_dia*pi;                  % Circumferance of motor axe
conveyor_speed = circumference_axe*rps ;                % [mm/s]
item_length = (no_of_img/camera_fps)* conveyor_speed;   % Calculate length of item

%% Y_MATRIX correction
item_width = img_width*relation_px_mm;                  % Convert from width in pixel to mm      

%% Creation Y/X Matrices
% Creation of X matrix going from 0 to item length row after row
x_matrix = linspace(0,item_length,no_of_img);
x_matrix = imresize(x_matrix, [img_width no_of_img], 'nearest');  % Set matrix dimension same ad z_matrix

% Creation of Y matrix going from 0 to item width column after column
y_matrix = linspace(0,item_width,img_width);
y_matrix = y_matrix.';                              % Transpose matrix
y_matrix = imresize(y_matrix, [img_width no_of_img], 'nearest');  

% Mirror left and right of matrix
if(inverse_Y_axis ~= 0)
    y_matrix = item_width-y_matrix;
end

%% Create patch struct
solid = surf2solid(x_matrix,y_matrix,z_matrix,'ELEVATION',0);
tic 
% TODO remove comment
% solid = reducepatch(solid,stl_compression);
disp('-Patch Reduction');
toc
%% Resized struct
solid.vertices = solid.vertices*scale;

%% Create STL file
% TODO remove comment
%stlwrite(stl_file_name,solid);

%% Display Patch
figure;
% display stl patch
patch(solid,'FaceColor',       [0.8 0.8 1.0], ...
         'EdgeColor',       'none',        ...
         'FaceLighting',    'gouraud',     ...
         'AmbientStrength', 0.15);

% Add a camera light, and tone down the specular highlighting
camlight('headlight');
material('dull');
xlabel(' X ')   % width of item
ylabel(' Y ')   % length of item
zlabel(' Z ')   % height of item
% Fix the axes scaling, and set view angle
view([-135 35]);
axis('image');

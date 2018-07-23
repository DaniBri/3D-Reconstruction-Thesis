imtool close all;
close all;
clc;
clear;
% The Main is the base of the reconstruction script.
%   In here it is possible to change all the settings, allowing to work with
%   the quality of the reconstruction and to adapt to different pictures.
%   At the end it gives out a STL File according to all the Picture located
%   in a given folder.
%
%   Author: Daniel Briguet, 18-06-2018

%% Settings

% Sequenze
folder_name = '\sequenz2';                         	% name of folder where images are stored in
picFormat = 'jpg';									% format of images in folder

% Calibration
use_checkerboeard = 0;                             	% if not camera parameters are used Turn on or off
calib_folder_name = '\calibration_pic';                         	% name of folder where images are stored in
calib_picFormat = 'jpg';									% format of images in folder
size_of_checkerboard_square = 14;                  	% Size of 1 square from checker board for calibration
pixel_size = 2.2;                                  	% [um] if unknown = 0;
imager_size = 5.7;                                 	% [mm] ONLY used when pixel size unknown
active_pixels = 2592;                              	% Number of pixels from sensor ONLY used when pixel size unknown

% IMG Processing
color_ponderation = 0.9;							% Contrast factor to define logical map
img_rotation = 0;                                  	% Number of rotation of images by 90° clockwise
inverse_hight = 1;                                 	% if model is upside down
inverse_Y_axis = 1;                                	% switches left and right / turning model 180%
filling_method = 'nearest';                         % Fill method must be 'constant', 'previous', 'next', 'nearest', 'linear', 'spline', or 'pchip'.
ground_hight_factor = 25;                          	% in how many slices hight is cut and ground will be removed from where most points are

% Smooth
smooth_run = 1;                               	% Turn on or off
smooth_factor = 0.0001;                            	% Use with moderation. Falsifies dimensions and slows down reconstruction

% Limiter
limiter_status = 1;                                	% Turn on or off
limiter_ponderation = 0.1;                         	% how many time the other value can be the current values size
limiter_area = 5;                                  	% Size of cross area that spike must at least have

% Motor
motor_alim = 2;                                    	% [V] voltage given to motor
motor_axis_dia = 6;                                	% [mm] diameter where cable is wrapped around
motor_poly = [0.0201 0.5978 0.2827];               	% p(x) = [ax^2+bx+c]

% Laser
angle_laser = 15;                                  	% Angle laser has to the lens axe

% Camera 
camera_fps = 7;                                  	% Frames per second of camera

% Output
stl_file_name = 'model.stl';						% Name of STL file created from script
scale = 1;                                         	% Resize factor of model

%% Calibration Set-up
tic;                                               	% Starting stopwatch
if(use_checkerboeard ~= 0)
    calibFolder = strcat(pwd, calib_folder_name);
    if ~isdir(calibFolder)
        error('Error, The following directory does not exist: \n%s', calibFolder);
    end
    calibration_filename = fullfile(calibFolder, strcat('*.', calib_picFormat));                                % getting current file directory
    picFiles = dir(calibration_filename);
    fullFileName = fullfile(calibFolder, picFiles(1).name);      % Getting current file in directory
    relation_px_mm = calibration(size_of_checkerboard_square,fullFileName);                 % [mm/px]
else
    if(pixel_size ~= 0)
        relation_px_mm = pixel_size/1000;
    else
        relation_px_mm = imager_size/active_pixels;
    end
end
disp('-Calibration done');
toc                                                 % End stopwatch and give time
disp('-----------------');
tic

%% Get Z_matrix
% Transmit settings and run scanning reconstruction
z_matrix = factory(picFormat, color_ponderation, ...
    smooth_run, filling_method, ...
    smooth_factor, folder_name, inverse_hight, ...
    ground_hight_factor, img_rotation, limiter_ponderation, ...
    limiter_area, limiter_status);
no_of_img = size(z_matrix,2);
img_width = size(z_matrix,1);                  % not actual img width but how many pixel large the scan on img was
disp('-Image Processing done');
toc                                                
disp('-----------------');
tic

%% Z_MATRIX correction
% Hight = length/tan(angle)
angle_laser = angle_laser*pi/180;                                             % Converting degree to rad
corrector_h = tan(angle_laser);                                               % in px
z_matrix = relation_px_mm*z_matrix/corrector_h;

%% X_MATRIX correction
% Speed calculation
rpm = polyval(motor_poly,motor_alim);                                       % base funktion found by measurment
rps = rpm / 60;                                                             % rotation per second
circumference_axe = motor_axis_dia*pi;                                      % circumferance of motor axe
conveyor_speed = circumference_axe*rps ;                                    % [mm/s]

% Belt Speed and IMG No.
% Example: object is 14 pic large. Camera is 7 FPS. Belt moves 1m/s. means
% object is exactly 2m long
real_length = (no_of_img/camera_fps)* conveyor_speed;

%% Y_MATRIX correction
% nothing to do cause object should be at least as large as image that was
% taken
real_width = img_width*relation_px_mm;

%% Creation Y-X_Matrixes & px to mm
% model length doesn't need to be converted from px to mm cause it has
% already been converted from img number to mm
x_matrix = linspace(0,real_length,no_of_img);
x_matrix = imresize(x_matrix, [img_width no_of_img], 'nearest');  %adapt size
y_matrix = linspace(0,real_width,img_width);
y_matrix = y_matrix.';                              % transpose matrix
y_matrix = imresize(y_matrix, [img_width no_of_img], 'nearest');  %adapt size

if(inverse_Y_axis ~= 0)
    y_matrix = real_width-y_matrix;
end
disp('-Creation & Correction of matrixes done');
toc
disp('-----------------');
tic

%% Making patch struct
solid = surf2solid(x_matrix,y_matrix,z_matrix,'ELEVATION',0);
disp('-Conversion to solid done');
toc
disp('-----------------');
tic

%% Resized struct
Model_scaled = solid;
Model_scaled.vertices = Model_scaled.vertices*scale;

%% Make STL file
[Model_scaled.vertices, ~, indexn] =  unique(Model_scaled.vertices, 'rows');
Model_scaled.faces = indexn(Model_scaled.faces);
stlwrite(stl_file_name,Model_scaled);
% display stl
figure;
patch(Model_scaled,'FaceColor',       [0.8 0.8 1.0], ...
         'EdgeColor',       'none',        ...
         'FaceLighting',    'gouraud',     ...
         'AmbientStrength', 0.15);

% Add a camera light, and tone down the specular highlighting
camlight('headlight');
material('dull');

% Fix the axes scaling, and set a nice view angle
view([-135 35]);

axis('image');
disp('-STL done');
toc
disp('-----------------');
%% TODO
% polyval polyfit
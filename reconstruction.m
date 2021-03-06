function result = reconstruction(FolderNameSequenze, ImageFormat, NameSTLFile, ...
                        EnableCheckerboard, FolderNameCalibration, ...
                        SquareSize, PixelSize, ImagerSize, ...
                        ActivePixels, ImageContrast, ImageRotation, ...
                        FinderMinSize, MirrorYAxe, FillingMethod, ...
                        SmoothFactor, LimiterPonderation, LimiterArea, ...
                        MotorAlimentation, MotorAxisDiameter, ...
                        MotorSpeedPolynom, LaserAngle, CameraFPS, ...
                        FileCompression, FileScale, ObjectsChecked, ...
                        ImagesChecked, ObjectSize, ErrorEnabled, ...
                        ErrorPercentage, GroundAngleError)
% RECONSTRUCTION is the base function to run to creat a 3D model.
% In the end the script returns an STL File according to all the Picture 
% located the given folder and parameters included when calling the 
% function.
% This function also displays a figure in matlab to directly visualize the
% model.
%
% Author: Daniel Briguet, 18-06-2018

clc
tic
disp('-Reconstruction Started');

%% Settings
% Sequence
folder_name = FolderNameSequenze;              	% Name of folder where images are stored
picFormat = ImageFormat;						% Format of images in folder

% Calibration
use_checkerboeard = EnableCheckerboard;      	% Turn on or off, if off camera parameters are used
calib_folder_name = FolderNameCalibration; 		% Name of folder where images are stored in
size_of_checkerboard_square = SquareSize;    	% Size of 1 square from checker board in mm
pixel_size = PixelSize;                       	% [um] If unknown = 0;
imager_size = ImagerSize;                      	% [mm] ONLY used when pixel size unknown
active_pixels = ActivePixels;					% Number of pixels from sensor ONLY used when pixel size unknown

% IMG Processing
contrast_logical = ImageContrast;              	% Contrast factor to define logical map
img_rotation = ImageRotation;					% Number of rotation of images by 90� clockwise
finder_object_size = FinderMinSize;           	% Minimal size of sequence for finder to look for. Helps avoiding noise on image
mirror_Y_axe = MirrorYAxe;						% Mirror model left right
filling_method = FillingMethod;             	% Fill method must be 'constant', 'previous', 'next', 'nearest', 'linear', 'spline', or 'pchip'.

% Smooth
smooth_factor = SmoothFactor/10000;           	% Use with moderation. Falsifies dimensions and slows down reconstruction

% Limiter
limiter_ponderation = LimiterPonderation;      	% Factor on proportional difference between adjacent values
limiter_area = LimiterArea;                    	% How many values are checked in each direction (up/down/left/right)

% Motor
motor_alim = MotorAlimentation;               	% [V] Motor power supply
motor_axis_dia = MotorAxisDiameter;           	% [mm] Diameter where cable is wrapped around
motor_poly = MotorSpeedPolynom;    				% Function calculated from measurement on motor
												% p(x) = [ax^2+bx+c]

% Laser
angle_laser = LaserAngle;                       % Angle between laser and socket
laser_correction_object_no = ObjectsChecked;   	% Number of object used to find out angle rotation
nmr_img_check = ImagesChecked;  				% On how many images at start of scan angle is checked
line_object_size = ObjectSize;                  % Minimal size of object on image for correction

% Camera 
camera_fps = CameraFPS;                         % Camera images taken per second

% Output
stl_file_name = NameSTLFile;					% Name of STL file created from script
scale = FileScale;                              % Resize factor of model
stl_compression = FileCompression;           	% How much data from original data should be kept.
												% Reduces file size but also reduces
												% quality of model

% Error Creation
activate_errors = ErrorEnabled;          		% Artificially create errors of different sort in matrix
error_percentage = ErrorPercentage;          	% Percentage of values randomized in matrix
ground_angle_error = GroundAngleError;			% Rise on ground from matrix

%% Calibration Set-up
if(use_checkerboeard ~= 0)
    calibFolder = strcat(pwd, calib_folder_name);       % Getting calibration file directory
    if ~isdir(calibFolder)
        error('Error, The following directory does not exist: \n%s', calibFolder);
    end
    calibration_filename = fullfile(calibFolder, strcat('*.', picFormat));    		% Getting calibration image in directory
    picFile = dir(calibration_filename);                                            % Storing information about all files in that folder
    fullFileName = fullfile(calibFolder, picFile(1).name);                          % Save path to first image and it's name
    relation_px_mm = calibration(size_of_checkerboard_square,fullFileName);         % Give image and size, returns relation [mm/px]
else
    if(pixel_size ~= 0)
        relation_px_mm = pixel_size/1000;               % [um] -> [mm]
    else
        relation_px_mm = imager_size/active_pixels;     % Calculate pixel_size directly in mm
    end
end

%% Get Z_matrix
% Transmit settings and run image processing
total_time = toc;
tic
disp('-Image Processing...');
z_matrix = factory(picFormat, folder_name, ...
        img_rotation, smooth_factor, ... 
        contrast_logical, filling_method, ...
        limiter_ponderation, limiter_area, ...
        laser_correction_object_no, ...
        nmr_img_check, activate_errors, error_percentage, ...
        finder_object_size, line_object_size, ground_angle_error);
no_of_img = size(z_matrix,2);               % Dimension 1 from z_matrix gives amount of image taken
img_width = size(z_matrix,1);               % Image width not item width
disp('-Processing Done');
toc
total_time = total_time+toc;

%% Z_MATRIX correction
% height = length/tan(angle)
tic 
angle_laser = angle_laser*pi/180;                       % Converting degree to rad
z_matrix = relation_px_mm*z_matrix/tan(angle_laser);    % Calculating height and converting from pixel to mm

%% X_MATRIX correction
% Speed calculation
rps = polyval(motor_poly,motor_alim)/ 60;               % Calculate motor rotation per second
circumference_axe = motor_axis_dia*pi;                  % Circumference of motor axe
conveyor_speed = circumference_axe*rps ;                % [mm/s]
item_length = (no_of_img/camera_fps)* conveyor_speed;   % Calculate length of item

%% Y_MATRIX correction
item_width = img_width*relation_px_mm;                  % Convert from width in pixel to mm      
disp('-Dim corrections done');
toc
total_time = total_time+toc;
%% Creation Y/X Matrices
% Creation of X matrix going from 0 to item length row after row
tic
x_matrix = linspace(0,item_length,no_of_img);
x_matrix = imresize(x_matrix, [img_width no_of_img], 'nearest');  % Set matrix dimension same as z_matrix

% Creation of Y matrix going from 0 to item width column after column
y_matrix = linspace(0,item_width,img_width);
y_matrix = y_matrix.';                              	% Transpose matrix
y_matrix = imresize(y_matrix, [img_width no_of_img], 'nearest');  

% Mirror left and right of matrix
if(mirror_Y_axe ~= 0)
    y_matrix = item_width-y_matrix;
end
disp('-X&Y matrices done');
toc
total_time = total_time+toc;
%% Create patch struct
tic
disp('-Patch reduction started');
solid = surf2solid(x_matrix,y_matrix,z_matrix,'ELEVATION',0);
if(stl_compression < 1)
    solid = reducepatch(solid,stl_compression);
end
disp('-Done');
toc

%% Resized structure
solid.vertices = solid.vertices*scale;
result = solid;

%% Create STL file
stlwrite(strcat(stl_file_name, '.stl'),solid);

%% Display Patch
figure;
% Display STL patch
patch(solid,'FaceColor',       [0.8 0.8 1.0], ...
         'EdgeColor',       'none',        ...
         'FaceLighting',    'gouraud',     ...
         'AmbientStrength', 0.15);

% Add a camera light, and tone down the specular highlighting
camlight('headlight');
material('dull');
xlabel(' X [mm]')   % width of item
ylabel(' Y [mm]')   % length of item
zlabel(' Z [mm]')   % height of item

% Fix the axes scaling, and set view angle
view([-135 35]);
axis('image');
total_time = total_time+toc;
disp('-End of script');
disp(strcat('Total time used',{' '}, num2str(round(total_time,2)), 's'));


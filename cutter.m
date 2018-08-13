function result_matrix = cutter(z_matrix, ground_cutter_limit, smooth_factor)
% CUTTER resizes matrix by cutting of border having no cell with value
% equal or greater than limit.
%
%   Example:
%
%     a = 3×3
%     2     2     3     3
%     4     5     6     3
%     4     8    10     3
%     3     3     3     4
%
%     matrix = cutter(a, 5)
%
%     result = 2×2
%     5     6
%     8    10
%
%   Author: Daniel Briguet, 04-07-2018

%% Getting corner position of item in matrix
% First step in function is to get corner position in matrix where a values
% are greater than limit.
% To do that 4 values are being looked for:
%   - First row having a value above limit
%   - Last row having a value above limit
%   - First column having a value above limit
%   - Last column having a value above limit

% Initializing variable holding position of first row and column
x_start = 0;
y_start = 0;

% Copy matrix that will be cut later on and send back
backup_matrix = z_matrix;

%% Smoothing
% Extra smoothing to remove perturbation on ground.
% allows to find limit to cut behind some "too high" points on ground
temp1 = size(z_matrix,1);
temp2 = size(z_matrix,2);

% Smooth methods: moving, lowess, loess, sgolay, rlowess, rloess
z_matrix = smooth(z_matrix,smooth_factor,'moving'); % Smoothing of matrix
z_matrix = reshape(z_matrix,temp1,temp2);           % Convert array back to matrix

%% Get cut region
% If smoothing created negative values replace them by 0
z_matrix(z_matrix < 0) = 0;
% Go past every column getting position in Y
for dim_1 = 1:size(z_matrix,1)
    % Do every row of column
    for dim_2 = 1:size(z_matrix,2)
        % Check if value is higher then limit
        if((z_matrix(dim_1,dim_2) >= ground_cutter_limit))
            % Check if start was already found
            if(y_start == 0)
                % Store column number where first value higher then limit
                % was found
                y_start = dim_1;
            end
            % Store every column number where value was found. Last one
            % found is end of item.
            y_dest = dim_1;
        end
    end
end

% Do same as before but for positions in X
for dim_2 = 1:size(z_matrix,2)
    for dim_1 = 1:size(z_matrix,1)
        if((z_matrix(dim_1,dim_2) >= ground_cutter_limit))
            if( x_start == 0)
                x_start = dim_2;
            end
            x_dest = dim_2;
        end
    end
end    

% Check if there was item on image lower then given limit
if(~exist('y_dest','var'))
    error('Error: Nothing was detected on any image');
end

%% Resizing matrix to new dimensions at given location
% z_matrix(column_start_coord:column_dest_coord,row_start_coord:row_dest_coord);
result_matrix = backup_matrix(y_start:y_dest,x_start:x_dest); 
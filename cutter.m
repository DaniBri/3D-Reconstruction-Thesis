function z_matrix = cutter(original_matrix, ground_limit)
% CUTTER removes part of matrix that are lower than certain point
%   Example:
%     matrix = cutter(a, 5)
%
%     a = 3×3
%     2     2     3
%     4     5     6
%     4     8    10
%     
%     result = 2×2
%     5     6
%     8    10
%
%   Author: Daniel Briguet, 04-07-2018



% getting corner position of object in matrix
% what has been seen by camera
x_start = 0;
y_start = 0;

% Goes up and down row after row first x position in a colum found that
% is not found stored as x position of start corner
% Last value found in colum stored as x position of destination corner
for dim_1 = 1:size(original_matrix,1)
    for dim_2 = 1:size(original_matrix,2)
        if((original_matrix(dim_1,dim_2) >= ground_limit)&& y_start == 0)
            y_start = dim_1;
        end
        if((original_matrix(dim_1,dim_2) >= ground_limit))
            y_dest = dim_1;
        end
    end
end

% Same but colum after colum
for dim_2 = 1:size(original_matrix,2)
    for dim_1 = 1:size(original_matrix,1)
        if((original_matrix(dim_1,dim_2) >= ground_limit) && x_start == 0)
            x_start = dim_2;
        end
        if((original_matrix(dim_1,dim_2) >= ground_limit))
            x_dest = dim_2;
        end
    end
end    

if(~exist('y_dest','var'))
    error('Error: Nothing was dedected on any image');
end

% the actuall cutting
z_matrix = original_matrix(y_start:y_dest,x_start:x_dest);                         % z_matrix(vertical_start_coord:vertical_dest_coord,horizontal_start_coord:horizontal_dest_coord);

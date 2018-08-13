function z_matrix = ground_balancer(original_matrix, border_margin)
%   GROUND_BALACER corrects ground in matrix 
%   Making average ground height difference at start and end of matrix.
%   Equivalent to checking height of ground at start and end of scan.
%   Correct the height in a linear way, fixing diagonal of scan on length
%   Matrix border_margin is how many values are used to determin ground
%   angle.
%   Ground is balanced until angle is smaller then 0.01
%
%   Author: Daniel Briguet, 18-06-2018

correction_array = zeros(1,size(original_matrix,1));  	% Initializing array where slop is stored
diff_array = zeros(1,border_margin);                       	% Initializing array where height difference is stored
if(border_margin*2+1 < size(original_matrix,2))               	% Minimal length of item matrix necessary
    for row = 1:size(original_matrix,1)                	% Go through all the rows of matrix
        % Get slop between border at start and end of row
        for i = 0:border_margin
            diff_max = original_matrix(row,1+i) - original_matrix(row,size(original_matrix,2) - i);  % Calculate height difference
            diff_length = (size(original_matrix,2) - 2 * i);                   	% Calculate length difference
            diff_array(i+1) = diff_max / diff_length;                           % Store slop
        end
        correction_array(row) = mean(diff_array);                               % Store mean slop of column
    end
    slop = mean(correction_array);                                              % Average ground slop 

    % Update every single value in row according to slop
    for column = 1:size(original_matrix,2)                                     	% Position in column
        correction = slop * column;                                               % Correction needed on that row of matrix
        for row = 1:size(original_matrix,1)                                     % Do entire row
            % Apply correction, doesn't matter if positive or negative
            % it will maybe heighten ground up but it's going be flat
            % later ground is put to 0 anyway
            original_matrix(row,column) = original_matrix(row,column) + correction;
        end
    end
end

% If angle is lower then 0.01 breack out of loop
if(abs(slop) >= 0.01)
    z_matrix = ground_balancer(original_matrix, border_margin);
else
    z_matrix = original_matrix;
end

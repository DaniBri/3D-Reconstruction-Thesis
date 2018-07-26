function z_matrix = ground_balancer(original_matrix)
%   GROUND_BALACER corrects ground in matrix 
%   Making average ground height difference at start and end of matrix.
%   Correct the height in a linear way, fixing diagonal of scan on length
%   Matrix margin to check = bodrer width that is checked
%
%   Author: Daniel Briguet, 18-06-2018

margin = 4;
correction_array = zeros(1,size(original_matrix,1));       % Initializing array where slop is stored
diff_array = zeros(1,margin);                       % Initializing array where height difference is stored
if(margin*2+1 < size(original_matrix,2))                   % Minimal length of item matrix necessary
    for row = 1:size(original_matrix,1)                    % Go through all the rows of matrix
        % Get slop between border at start and end of row
        for i = 0:margin
            diff_max = original_matrix(row,1+i) - original_matrix(row,size(original_matrix,2) - i);  % Calculate height difference
            diff_length = (size(original_matrix,2) - 2 * i);                           % Calculate length difference
            diff_array(i+1) = diff_max / diff_length;                           % Store slop
        end
        correction_array(row) = mean(diff_array);                               % Store mean slop of column
    end
    slop = mean(correction_array);                                              % Average ground slop 

    % Update every single value in row acording to slop
    for column = 1:size(original_matrix,2)                                             % position in column
        correction = slop*column;                                               % Correction needed on that row of matrix
        for row = 1:size(original_matrix,1)                                            % Do entire row
            % Apply correction, doesn't matter if positiv or negativ
            % it will mabe heighten ground up but it's gona be flat
            % later ground is put to 0 anyway
            original_matrix(row,column) = original_matrix(row,column) + correction;
        end
    end
end

z_matrix = original_matrix;
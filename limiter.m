function z_matrix = limiter(original_matrix, ponderation, area)
%   LIMITER removes point in a matrix that are too high compared to an area
%   of adjacent points. To determine if a point is too high it must be 
%   within the ponderation of adjacent area. Points in matrix where change 
%   in value is not justified are replaced by NaN.
%   Area checked is a cross form, NO diagonal control.
%   This fucntion is recursive until no new points were found in
%   matrix to be removed. 
%   Static counter implemented to prevent looping forever (security).
%   Because it is possible that there are minimal changes found for a 
%   very long time in every loop. Ex: removing 2 values at a time when
%   matrix has dimension 1900x100.
%   Loop limit fixed in function at 32
%
%   Example where only singular values:
%     a = 3�3
%     4     4     4     4
%     4     5     4     4
%     4     4     8     4
%     4     4     4     4
%
%     matrix = limiter(a,0.5,1)
%
%     a = 3�3
%     4     4     4     4
%     4     5     4     4
%     4     4    NaN    4
%     4     4     4     4
%     
%   Value 5 is justified because it is within 0.5 range of adjacent values
%   But 8 is not valid cause is would need a factor 1 to be in range.
%
%   Example 2:
%     a = 3�3
%     4     4     4     4
%     4     8     8     4
%     4     8     8     4
%     4     4     4     4
%
%     matrix = limiter(matrix,0.5,1)
%
%     a = 3�3
%     4     4     4     4
%     4     8     8     4
%     4     8     8     4
%     4     4     4     4
%
%   Value 8 is out of range from factor, but is justified because enough
%   other points in area of 1 are within range of value.
%
%   Author: Daniel Briguet, 01-07-2018

%% Loop security setting
loop_limit = 32;

%% Initial Value
% Get dimension of matrix
column = size(original_matrix,2);
row = size(original_matrix,1);

% Create logical matrix with same dimensions, this matrix will be used as
% mask. Using a mask to note what values need to be removed will allow
% avoiding removing directly values to which later other values are being
% compare to.
logical_matrix = false(row,column);
backup_original = original_matrix;                          % Backup-matrix used to compare result with to see if new points where removed
                                                            % If there wasn't can break out of loop 
new_matrix = original_matrix;                               % Copy of matrix to modify with mask later

% Static counter to prevent looping for too long.
persistent recursiveCount;
% Upon the first call we need to initialize the variables.
if isempty(recursiveCount)
    recursiveCount = loop_limit;
end

%% Recover missing values in matrix 
% To compare it correctly there shouldn't be NaN values in matrix
original_matrix = rot90(original_matrix,1);                 % Rotate matrix 90�
original_matrix = fillmissing(original_matrix,'nearest');   % Replaces all NaNs
original_matrix = rot90(original_matrix,-1);                % Rotate back
original_matrix = fillmissing(original_matrix,'nearest');

%% Comparison
for position_y = 1:size(original_matrix,1)                  % Row
    for position_x = 1:size(original_matrix,2)              % Column
        value = original_matrix( position_y, position_x);   % Current position that is beeing checked

        % Counter for how many points in area current value is out of range
        remove = 0;
        % How many next values to compare to
        for i = 1:area                      
            % Check above current position
            if((position_y - i) > 0)        % Matrix boundary control
                checker_val = original_matrix( position_y-i, position_x);   % Get value that current cell is compared to

                % Check if difference between both values is within
                % range of the values in area.
                if(abs(value-checker_val) >= abs(ponderation*checker_val))
                    % If out of range +1 to remove counter
                    remove = remove+1;
                end
            else
                % If out of boundary count it as out of range from value
                remove = remove+1;
            end

            % Check below value
            if((position_y + i) <= row)
                checker_val = original_matrix( position_y+i, position_x);
                if(abs(value-checker_val) >= abs(ponderation*checker_val))
                    remove = remove+1;
                end
            else
                remove = remove+1;
            end

            % Check left of value
            if((position_x - i) > 0)
                checker_val = original_matrix( position_y, position_x-i);
                if(abs(value-checker_val) >= abs(ponderation*checker_val))
                    remove = remove+1;
                end
            else
                remove = remove+1;
            end

            % Check right of value
            if((position_x + i) <= column)
                checker_val = original_matrix( position_y, position_x+i);
                if(abs(value-checker_val) >= abs(ponderation*checker_val))
                    remove = remove+1;
                end
            else
                remove = remove+1;
            end
        end
        
        % If value was out of range for more then half the values in area 
        % turn position to a 1 on mask.
        if(remove > area*2)
            logical_matrix(position_y,position_x) = 1;
        end
    end
end

%% Process Mask
new_matrix(logical_matrix) = NaN;    % Remove from backup of original matrix the points marked on mask to get new matrix
to_send = new_matrix;                % Make copy of result to use later

%% Compare old matrix and new one
% Set NaN cells in matrix to 0 cause else they an not be compared
backup_original(isnan(backup_original)) = 0;    % Replace all NaNs to 0
new_matrix(isnan(new_matrix)) = 0;              % Replace all NaNs to 0

result = backup_original == new_matrix;         % Comparison between new matrix and old one
                                                % If matrices in same cell have same value fill 
                                                % matrix in result with 1 else 0 
idx = result==0;                                % Inverse matrix if there was a difference make 1
out = sum(idx(:));                              % Count differences

%% Recall function / Break out
% If there where no differences break out of recursive loop
% Same goes if turned to long in recursive loop 
if(out == 0 || recursiveCount <= 0)
    % Return final matrix 
    z_matrix = to_send;
    disp('-Limiter done');
    str = ['-Loops = ',num2str(loop_limit-recursiveCount)];
    disp(str);
else
    % If there was still a differences it means there can potentially still
    % be more to remove.
    recursiveCount = recursiveCount - 1;
    z_matrix = limiter(to_send, ponderation, area);
end


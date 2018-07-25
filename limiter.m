function z_matrix = limiter(original_matrix, ponderation, area)
% LIMITER remove isolatet points
% check if there is a huge change in value AND check if change is justified by
% looking at area/size and occurance of that change. like if it's olny 1 
% point that changed or 100 adjasant points are changing as well.
%
%   Example:
%     matrix = limiter(matrix)
%
%   Author: Daniel Briguet, 01-07-2018

%% Initial Value

row_length = size(original_matrix,2);
column_length = size(original_matrix,1);
logical_matrix = false(column_length,row_length);
removed_counter = 0;
comparer_matrix = original_matrix;                              % used to compare if there where changes and breack out of recursivity
backup_origin = original_matrix;
original_matrix = fillmissing(original_matrix,'linear');                                  % Take close number and copie it

%% Comparison
for position_y = 1:size(original_matrix,1)              % Row
    for position_x = 1:size(original_matrix,2)          % Column
        value = original_matrix( position_y, position_x);            % Cell that is beeing checked


        % Value in Critical Section now check if value is alone in that
        % position.
        remove = 0;
        if(~isnan(value))
            for i = 1:area                              % How many next values to compare to

                % Check abow value
                if((position_y - i) > 0) % doesn't go out of boundry
                    checker_val = original_matrix( position_y-i, position_x);   % value that current cell is compared to
                    if(abs(value-checker_val) >= abs(ponderation*value) || isnan(checker_val))  % is int out of range?
                        remove = remove+1;
                    end
                else
                    remove = remove+1;
                end

                % Check below value
                if((position_y + i) <= column_length)
                    checker_val = original_matrix( position_y+i, position_x);   % value that current cell is compared to
                    if(abs(value-checker_val) >= abs(ponderation*value) || isnan(checker_val))
                        remove = remove+1;
                    end
                else
                    remove = remove+1;
                end

                % Check left of value
                if((position_x - i) > 0)
                    checker_val = original_matrix( position_y, position_x-i);   % value that current cell is compared to
                    if(abs(value-checker_val) >= abs(ponderation*value) || isnan(checker_val))
                        remove = remove+1;
                    end
                else
                    remove = remove+1;
                end

                % Check right of value
                if((position_x + i) <= row_length)
                    checker_val = original_matrix( position_y, position_x+i);   % value that current cell is compared to
                    if(abs(value-checker_val) >= abs(ponderation*value) || isnan(checker_val))
                        remove = remove+1;
                    end
                else
                    remove = remove+1;
                end
            end
        end
        if(remove >= area*2)
            logical_matrix(position_y,position_x) = 1;
            removed_counter = removed_counter+1; 
        end
    end
end
backup_origin(logical_matrix) = NaN;    % Remove from matrix the points found and stored in logical_matrix
to_send = backup_origin;                % Store that result to send on later

% set Nan values to 0 cause else they an not be compared
comparer_matrix(isnan(comparer_matrix)) = 0;    % transforms all NaN to 0
backup_origin(isnan(backup_origin)) = 0;    % same 
result = comparer_matrix == backup_origin;  % make comparision between new matrix and old one
idx=result==0;     % check for differences in matrix
out=sum(idx(:));    % count differences
if(out == 0)        % if 0 differences break out of recursivity
    z_matrix = medfilt2(to_send);
else                % if there are still some differences it means there are still some spikes to remove
    z_matrix = limiter(to_send, ponderation, area);
end


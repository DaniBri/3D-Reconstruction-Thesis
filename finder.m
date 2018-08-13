function centroid = finder(array_to_check, min_size)
%   FINDER detects the centre of longest object in a logical array and
%   returns its position in the array. The object is the longest sequenz of
%   1 in array
%   NaN is returned if no center was found.
%
%   Author: Daniel Briguet, 18-06-2018

% Initializing variable
size_largest = min_size;
centroid = NaN;
current_size = 0;

for position = 1:size(array_to_check,1)
    
    % Looking for ones in array
    if(array_to_check(position) == 1)
        % Increment size of sequence if a one was found
        current_size = current_size+1;
    else
        % Set sequence to 0 if no 1 was found
        current_size = 0;
    end
    
    % Check if current size of sequence is larger than largest one until now
    if(current_size > size_largest)
        % Set new largest size if bigger
        size_largest = current_size;
        
        % Update return index (centroids) to new largest sequence
        centroid = position - current_size/2;
    end
end

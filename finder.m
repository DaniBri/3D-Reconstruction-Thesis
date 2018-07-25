function centroid = finder(array_to_check)
%   FINDER detects the centre of longest object in a row.
%   Row needs to be logical, meaning only consisting of ones and zeros
%   The Function goes trough array looking for longest sequence of ones.
%   Once the longes sequence is found the finder returns the index of the
%   sequence. The index is the position of the center of the sequence in
%   the array.
%   NaN is returned if no sequenz was found.
%
%   Author: Daniel Briguet, 18-06-2018

% Initializing variable
size_largest = 0;
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
    
    % Check if current size of sequence is larger largest one untile now
    if(current_size > size_largest)
        % Set new largest size if bigger
        size_largest = current_size;
        
        % Update return index (centrois) to new largest sequence
        centroid = position - current_size/2;
    end
end

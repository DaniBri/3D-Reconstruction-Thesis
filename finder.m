function position = finder(column)
% FINDER detects the center of longest object in a logical map column
% goes trough column looking for longest sequenz of ones.
% last position of largest count is substracted by half of count to get centroid
% RETURNS NAN IF NOTHING WAS FOUND
%
%   Author: Daniel Briguet, 18-06-2018

size_largest = 0;
centroid = NaN;
current_size = 0;
for position = 1:size(column,1)
    if(column(position) == 1)
        current_size = current_size+1;
    else
        current_size = 0;
    end
    
   
    if(current_size > size_largest)
        size_largest = current_size;
        centroid = position - current_size/2;
    end
    
    % if two have same size remove both. beceaus it is not possible to
    % determine which one is the correct line. so NaN is stored in centroid
    % and it will count as missing data. this will alows to make a better
    % decision by comparing it with the other images befor and after the
    % troubelshooting picture
    if(current_size == size_largest)
    end
end

position = centroid;
function centroid = finder(column)
% FINDER detects the centre of longest object in a logical map column
% goes trough column looking for longest sequence of ones.
% last position of largest count is subtracted by half of count to get centroid
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
end

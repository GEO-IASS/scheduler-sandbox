classdef SsFlatImage < SsEntity
    % Computes an image over arbitrary x-y planar region and sampling.
    
    methods (Abstract)
        imageSample = sample(obj, x, y);
    end
    
    methods
        function imageGrid = sampleGrid(obj, x, y)
            % all combinations of x and y in a grid arrangement.
            [xGrid, yGrid] = meshgrid(x, y);
            imageSample = obj.sample(xGrid, yGrid);
            imageGrid = reshape(imageSample, numel(y), numel(x));
        end
    end
end

classdef SsImage < SsEntity
    % Computes an image over arbitrary x-y sampling, cache the results.
    
    properties (Access = private)
        sampleCache;
    end
    
    methods
        function imageSample = sample(obj, x, y, varargin)
            parser = SsInputParser();
            parser.addRequired('x', @isnumeric);
            parser.addRequired('y', @isnumeric);
            parser.addParameter('tag', '', @ischar);
            parser.parseMagically('caller', x, y, varargin{:});
            
            % try to look up samples from cache
            imageSample = obj.checkCache(tag);
            if isempty(imageSample)
                imageSample = obj.computeSample(x, y);
                obj.cacheSample(imageSample, tag);
            end
        end
        
        function imageGrid = sampleGrid(obj, x, y, varargin)
            parser = SsInputParser();
            parser.addRequired('x', @isnumeric);
            parser.addRequired('y', @isnumeric);
            parser.addParameter('tag', '', @ischar);
            parser.parseMagically('caller', x, y, varargin{:});
            
            % all combinations of x and y in a grid arrangement
            [xGrid, yGrid] = meshgrid(x, y);
            imageSample = obj.sample(xGrid, yGrid, 'tag', tag);
            imageGrid = reshape(imageSample, numel(y), numel(x), []);
        end
        
        function imageSample = checkCache(obj, tag)
            parser = SsInputParser();
            parser.addRequired('tag', @ischar);
            parser.parseMagically('caller', tag);
            
            if isempty(obj.sampleCache)
                obj.sampleCache = containers.Map( ...
                    'KeyType', 'char', ...
                    'ValueType', 'any');
            end
            
            if obj.sampleCache.isKey(tag)
                imageSample = obj.sampleCache(tag);
            else
                imageSample = [];
            end
        end
        
        function clearCache(obj)
            if ~isempty(obj.sampleCache)
                obj.sampleCache.remove(obj.sampleCache.keys);
            end
        end        
    end
    
    methods (Abstract, Access = protected)
        % internally do computations
        imageSample = computeSample(obj, x, y);
    end
    
    methods (Access = private)
        function cacheSample(obj, imageSample, tag)
            if isempty(tag)
                return;
            end
            obj.sampleCache(tag) = imageSample;
        end
    end
end

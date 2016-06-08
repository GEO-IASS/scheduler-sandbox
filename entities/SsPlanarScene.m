classdef SsPlanarScene < SsImage & SsSlotTarget
    % Sample a flat image and illuminate it.
    
    properties
        width;
        height;
        horizontalOffset;
        verticalOffset;
        pixelWidth;
        pixelHeight;
        illuminant;
        
        % slotted
        reflectance;
    end
    
    methods
        function obj = SsPlanarScene(varargin)
            parser = SsInputParser();
            parser.addParameter('name', '', @ischar);
            parser.addParameter('width', 1, @isnumeric);
            parser.addParameter('height', 1, @isnumeric);
            parser.addParameter('horizontalOffset', 0, @isnumeric);
            parser.addParameter('verticalOffset', 0, @isnumeric);
            parser.addParameter('pixelWidth', 640, @isnumeric);
            parser.addParameter('pixelHeight', 480, @isnumeric);
            parser.addParameter('illuminant', SsSpectrum(400:10:700), @(s) isa(s, 'SsSpectrum'));
            parser.parseMagically(obj, varargin{:});
        end
        
        function slots = declareSlots(obj)
            % need a multispectral image with wavelengths
            slots = SsSlot() ...
                .assignAs('reflectance') ...
                .requireClass('SsImage') ...
                .requireProperty('wavelengths') ...
                .preferProperty('name', 'value', 'reflectance');
        end
        
        function imageSample = sampleWholeScene(obj)
            % look up or compute the whole scene image
            x = obj.horizontalOffset + linspace(0, obj.width, obj.pixelWidth);
            y = obj.verticalOffset + linspace(0, obj.height, obj.pixelHeight);
            imageSample = obj.sampleGrid(x, y, 'tag', 'whole-scene');
        end
        
        function imageSample = sampleRegion(obj, left, right, top, bottom)
            % convert to pixels
            [x, y] = obj.clipToBounds([left right], [top bottom]);
            [xRange, yRange] = obj.sceneToPixels(x, y);
            
            % pick out part of the whole scenes
            wholeScene = obj.sampleWholeScene();
            xInds = xRange(1):xRange(2);
            yInds = yRange(1):yRange(2);
            imageSample = wholeScene(yInds, xInds, :);
        end
        
        function [left, right, top, bottom] = bounds(obj)
            left = obj.horizontalOffset;
            right = obj.horizontalOffset + obj.width;
            top = obj.verticalOffset;
            bottom = obj.verticalOffset + obj.height;
        end
        
        function [x, y] = clipToBounds(obj, x, y)
            [left, right, top, bottom] = obj.bounds();
            x = max(x, left);
            x = min(x, right);
            y = max(y, top);
            y = min(y, bottom);
        end
        
        function [xPixels, yPixels] = sceneToPixels(obj, xScene, yScene)
            % convert x and y in scene units to internal pixel values
            w = obj.width + eps(obj.width);
            h = obj.height + eps(obj.height);
            xPixels = 1 + floor((xScene - obj.horizontalOffset) * obj.pixelWidth / w);
            yPixels = 1 + floor((yScene - obj.verticalOffset) * obj.pixelHeight / h);
        end
    end
    
    methods (Access = protected)
        function imageSample = computeSample(obj, x, y)
            % get reflectance image from sloted object
            reflectanceSample = obj.reflectance.computeSample(x,y);
            
            % resample illuminant to match reflectance
            illum = obj.illuminant.resample( ...
                obj.reflectance.wavelengths, ...
                'method', 'spd');
            
            % multiplu illuminant across the reflectance image
            imageSample = reflectanceSample ...
                .* repmat(illum.magnitudes(:)', numel(x), 1);
        end
    end
end

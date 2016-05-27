classdef SsPlanarScene < SsImage
    % Sample a flat image and illuminate it.
    
    properties
        width;
        height;
        pixelWidth;
        pixelHeight;
        illuminant;
    end
    
    methods
        function obj = SsPlanarScene(varargin)
            parser = SsInputParser();
            parser.addParameter('width', 1, @isnumeric);
            parser.addParameter('height', 1, @isnumeric);
            parser.addParameter('pixelWidth', 640, @isnumeric);
            parser.addParameter('pixelHeight', 480, @isnumeric);
            parser.addParameter('illuminant', SsSpectrum(400:10:700), @(s) isa(s, 'SsSpectrum'));
            parser.parseMagically(obj, varargin{:});
            
            obj.nested.declareSlot(SsSlot('reflectance') ...
                .requireClass('SsImage') ...
                .requireProperty('wavelengths'));
        end
        
        function imageSample = sampleWholeScene(obj)
            % look up or compute the whole scene image
            x = linspace(0, obj.width, obj.pixelWidth);
            y = linspace(0, obj.height, obj.pixelHeight);
            imageSample = obj.sampleGrid(x, y, 'tag', 'whole-scene');
        end
        
        function imageSample = sampleRegion(obj, left, right, top, bottom)
            wholeScene = obj.sampleWholeScene();
            
            % clip requested region to scene bounds
            left = max(left, 0);
            right = min(right, obj.width - eps(obj.width));
            top = max(top, 0);
            bottom = min(bottom, obj.height - eps(obj.height));
            
            % convert requested region to pixels
            leftPixel = 1 + floor(obj.pixelWidth * left / obj.width);
            rightPixel = 1 + floor(obj.pixelWidth * right / obj.width);
            topPixel = 1 + floor(obj.pixelHeight * top / obj.height);
            bottomPixel = 1 + floor(obj.pixelHeight * bottom / obj.height);
            
            % sample the whole sceneImage
            imageSample = wholeScene(topPixel:bottomPixel, leftPixel:rightPixel, :);
        end
    end
    
    methods (Access = protected)
        function imageSample = computeSample(obj, x, y)
            % get reflectance image from slot
            reflectance = obj.nested.findSlot('reflectance');
            if isempty(reflectance)
                imageSample = [];
                return;
            end
            reflectanceSample = reflectance.computeSample(x,y);
            
            % resample illuminant to match reflectance
            illum = obj.illuminant.resample( ...
                reflectance.wavelengths, ...
                'method', 'spd');
            
            % multiplu illuminant across the reflectance image
            imageSample = reflectanceSample ...
                .* repmat(illum.magnitudes(:)', numel(x), 1);
        end
    end
end

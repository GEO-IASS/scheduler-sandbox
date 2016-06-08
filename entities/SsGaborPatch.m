classdef SsGaborPatch < SsImage
    % Sample a Gabor patch in the infinite x-y plane.
    
    properties
        frequency;
        orientation;
        phase;
        stddev;
        aspect;
        gain;
    end
    
    methods
        function obj = SsGaborPatch(varargin)
            parser = SsInputParser();
            parser.addParameter('name', '', @ischar);
            parser.addParameter('frequency', 1, @isnumeric);
            parser.addParameter('orientation', 0, @isnumeric);
            parser.addParameter('phase', 0, @isnumeric);
            parser.addParameter('stddev', 1, @isnumeric);
            parser.addParameter('aspect', 1, @isnumeric);
            parser.addParameter('gain', 1, @isnumeric);
            parser.parseMagically(obj, varargin{:});
        end
    end
    
    methods (Access = protected)
        function imageSample = computeSample(obj, x, y)
            % Real part of Gabor a filter
            % https://en.wikipedia.org/wiki/Gabor_filter
            
            xPrime = x .* cos(obj.orientation) + y .* sin(obj.orientation);
            yPrime = -x .* sin(obj.orientation) + y .* cos(obj.orientation);
            exponent = -1 * (xPrime .^ 2 + obj.aspect .^ 2 * yPrime .^ 2) ...
                / (2 * obj.stddev .^ 2);
            angle = 2 .* pi() .* obj.frequency .* xPrime + obj.phase;
            imageSample = obj.gain .* exp(exponent) .* cos(angle);
        end
    end
end

classdef SsSpectrum < handle
    % Hold wavelengths, magnitudes, and units for a sampled spectrum.
    
    properties
        wavelengths;
        magnitudes;
        wavelengthUnits;
        magnitudeUnits;
    end
    
    methods
        function obj = SsSpectrum(wavelengths, varargin)
            parser = SsInputParser();
            parser.addRequired('wavelengths', @isnumeric);
            parser.addParameter('magnitudes', [], @isnumeric);
            parser.addParameter('wavelengthUnits', 'nm', @ischar);
            parser.addParameter('magnitudeUnits', 'unitless', @ischar);
            parser.parseMagically(obj, wavelengths, varargin{:});
            
            if isempty(obj.magnitudes)
                obj.magnitudes = ones(size(obj.wavelengths));
            end
        end
        
        function newObj = resample(obj, newWavelengths, varargin)
            parser = SsInputParser();
            parser.addRequired('newWavelengths', @isnumeric);
            parser.addParameter('method', 'raw', @ischar);
            parser.addParameter('extend', 0, @isnumeric);
            parser.parseMagically('caller', newWavelengths, varargin{:});
            
            if strcmp(method, 'spd')
                newMagnitudes = SplineSpd(obj.wavelengths(:), obj.magnitudes(:), newWavelengths(:), extend);
            else
                newMagnitudes = SplineRaw(obj.wavelengths(:), obj.magnitudes(:), newWavelengths(:), extend);
            end
            
            newObj = SsSpectrum( ...
                newWavelengths, ...
                'magnitudes', newMagnitudes, ...
                'wavelengthUnits', obj.wavelengthUnits, ...
                'magnitudeUnits', obj.magnitudeUnits);
        end
    end
end

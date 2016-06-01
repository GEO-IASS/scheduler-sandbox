classdef SsTwoSpectrumImage < SsImage & SsSlotTarget
    % Use a flat image to interpolate bewteen two spectra.
    
    properties
        low;
        high;
        lowSpectrum;
        highSpectrum;
        wavelengths;
        
        % slotted
        weights;
    end
    
    methods
        function obj = SsTwoSpectrumImage(varargin)
            parser = SsInputParser();
            parser.addParameter('low', -1, @isnumeric);
            parser.addParameter('high', 1, @isnumeric);
            parser.addParameter('lowSpectrum', SsSpectrum(400:10:700, 'magnitudes', zeros(1, 31)), @(s) isa(s, 'SsSpectrum'));
            parser.addParameter('highSpectrum', SsSpectrum(400:10:700, 'magnitudes', ones(1, 31)), @(s) isa(s, 'SsSpectrum'));
            parser.parseMagically(obj, varargin{:});
            
            % get low and high spectra in the same sampling
            obj.wavelengths = obj.lowSpectrum.wavelengths;
            obj.highSpectrum = obj.highSpectrum.resample(obj.wavelengths);
        end
        
        function slots = declareSlots(obj)
            % need a nested flat image of weights
            slots = SsSlot() ...
                .assignAs('weights') ...
                .requireClass('SsImage') ...
                .preferProperty('name', 'value', 'weights');
        end
    end
    
    methods (Access = protected)
        function imageSample = computeSample(obj, x, y)
            % convert slotted image to interpolation weights
            weightSample = obj.weights.computeSample(x, y);
            spectrumWeights = (weightSample - obj.low) ./ (obj.high - obj.low);
            
            % weighted sum of spectra -> spectral image sample
            nPlanes = numel(obj.wavelengths);
            nWeights = numel(x);
            lowPart = repmat(spectrumWeights(:), 1, nPlanes) ...
                .* repmat(obj.lowSpectrum.magnitudes(:)', nWeights, 1);
            highPart = repmat(1 - spectrumWeights(:), 1, nPlanes) ...
                .* repmat(obj.highSpectrum.magnitudes(:)', nWeights, 1);
            imageSample = lowPart + highPart;
        end
    end
end

classdef SsStream < handle
    % A place where Computations can read and write data (incomplete).
    %   This implementation is incomplete.  It's just a stub that can catch
    %   data dumped out of a computation.
    
    properties
        name;
        sampleHistory;
    end
    
    methods
        function obj = SsStream(varargin)
            parser = SsInputParser();
            parser.addParameter('name', '', @ischar);
            parser.parseMagically(obj, varargin{:});
        end
        
        function putSample(obj, value, time)
            sample = SsStream.makeSample(value, time);
            if isempty(obj.sampleHistory)
                obj.sampleHistory = sample;
            else
                obj.sampleHistory(end+1) = sample;
            end
        end
        
        function sample = currentSample(obj)
            if isempty(obj.sampleHistory)
                sample = [];
            else
                sample = obj.sampleHistory(end);
            end
        end
        
        function value = currentValue(obj)
            sample = obj.currentSample();
            if isempty(sample)
                value = [];
            else
                value = sample.value;
            end
        end
    end
    
    methods (Static, Access = protected)
        function sample = makeSample(value, time)
            sample = struct('value', {value}, 'time', {time});
        end
    end
end

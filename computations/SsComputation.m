classdef SsComputation < handle
    % A time-varying numerical model with internal state.
    
    properties
        name;
    end
    
    methods (Abstract)
        [nextTime, independenceTime] = update(obj, currentTime, previousTime);
    end
    
    methods
        function initialize(obj)
            % default is no-op, subclasses may override
        end
    end
end

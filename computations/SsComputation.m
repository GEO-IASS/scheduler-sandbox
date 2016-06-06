classdef SsComputation < handle
    % A time-varying numerical model with internal state.
    
    properties
        name;
        updateInterval = 0.1;
    end
    
    methods
        function initialize(obj)
            % default is no-op, subclasses may override
        end
        
        function [nextTime, independenceTime] = update(obj, currentTime, previousTime)
            % chose default update time, subclasses may override
            nextTime = currentTime + obj.updateInterval;
            independenceTime = currentTime + obj.updateInterval;
        end
    end
end

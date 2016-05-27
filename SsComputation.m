classdef SsComputation < handle
    % A time-varying numerical model with internal state.
    
    properties (SetAccess = private)
        entities;
        inputs;
        outputs;
    end
    
    methods
        function obj = SsComputation()
            obj.entities = SsSlotCollection();
            obj.inputs = SsSlotCollection();
            obj.outputs = SsSlotCollection();
        end
    end
    
    methods (Abstract)
        [nextTime, independenceTime] = update(obj, currentTime, previousTime);
    end
end

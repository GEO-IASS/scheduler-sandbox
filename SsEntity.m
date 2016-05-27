classdef SsEntity < handle
    % A "noun" in the simulation with time-constant parameters.
    
    properties
        name;
    end
    
    properties (SetAccess = private)
        nested;
    end
    
    methods
        function obj = SsEntity()            
            obj.nested = SsSlotCollection();
        end
    end
end

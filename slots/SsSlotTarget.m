classdef SsSlotTarget < handle
    % Declare required objects and which properties to receive them.
    
    methods (Abstract)
        % what properties does this object need and where to assign them?
        slots = declareSlots(obj);
    end
    
    methods
        % extra initialization after slot assignments?
        function afterSlotAssignments(obj, slots)
            % default is no-op, subclasses may override
        end
    end
end

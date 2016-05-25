classdef SsEntity < handle
    % A "noun" in the simulation with time-constant parameters.
    
    properties
        slots;
    end
    
    methods
        
        function slot = findSlot(obj, name)
            isNamedSlot = strcmp(name, {obj.slots.name});
            if any(isNamedSlot)
                slot = obj.slots(find(isNamedSlot, 1, 'first'));
            else
                warning('Entity:noSuchSlot', ...
                    'Entity "%s" has no slot named "%s".', obj.name, name);
                slot = [];
            end
        end
    end
    
    methods (Access = private)
        function declareSlot(obj, slot)
            if isempty(obj.slots)
                obj.slots = slot;
            else
                obj.slots(end+1) = slot;
            end
        end
    end
end
